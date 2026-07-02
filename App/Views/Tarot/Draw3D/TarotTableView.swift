// 타로 3D 뽑기 무대 — 버드뷰 펠트 테이블.
// 카드가 왼쪽에 쌓여 있음 → 손으로 옆으로 드래그하면 부채꼴로 쫙 펼쳐짐(손가락 따라 점진적)
// → 펼쳐진 카드를 훑으면 손 아래 카드가 반응(살짝 들림) → 꾹 누르거나 위로 스와이프하면
// 그 카드가 위로 이동+커지며 플립 → 고급 공개 화면.
// 원카드(1장) 플로우 POC. (reduce motion 시 기존 그리드로 폴백)

import SwiftUI

struct TarotTableView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: TarotSession

    private enum Stage { case dealing, stacked, spread, drawn }
    @State private var stage: Stage = .dealing
    @State private var dealtCount = 0
    @State private var spread: Double = 0          // 0=왼쪽 더미, 1=완전히 펼침
    @State private var dragStartSpread: Double = 0
    @State private var dragging = false
    @State private var spreadDrag: SpreadDrag?     // 펼친 뒤 드래그 모드(시작 방향으로 고정)
    @State private var browseX: CGFloat?           // 훑는 손가락 x — 근처 카드가 파도처럼 올라옴
    @State private var pullIndex: Int?             // 위로 밀어 뽑는 중인 카드
    @State private var pullUp: CGFloat = 0         // 밀어올린 거리(px)
    @State private var pullAmount: CGFloat = 0     // 0..1 진행도(양옆 벌어짐·확대)

    private enum SpreadDrag { case browse, lift }
    @State private var hovered: Int?
    @State private var selected: Int?
    @State private var showReveal = false
    @Namespace private var cardNS

    private let visualCount = 11
    private let cardW: CGFloat = 104
    private let cardH: CGFloat = 166

    var body: some View {
        Group {
            if reduceMotion {
                fallbackGrid
            } else {
                stageView
            }
        }
        .background(tableBackground)
        .navigationTitle(session.spread.label)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - 무대

    private var stageView: some View {
        GeometryReader { geo in
            ZStack {
                fan(in: geo)

                Text(prompt)
                    .font(DT.sans(13, .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.72)
                    .opacity(stage == .drawn ? 0 : 1)

                // 뽑힌 카드 → 위로 이동 + 커지며 (matchedGeometry)
                if stage == .drawn, let drawn = session.cards.first {
                    DrawnCardLayer(drawn: drawn, namespace: cardNS, matchedID: selected ?? 0)
                        .frame(width: cardW, height: cardH)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.36)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(tableDrag(in: geo))
            .onTapGesture { if stage == .stacked { completeSpread() } }
            .overlay {
                if showReveal, let drawn = session.cards.first {
                    CardRevealView(session: session, drawn: drawn) { dismissReveal() }
                        .transition(.opacity)
                }
            }
            .onAppear { dealIn() }
        }
    }

    // 카드 뒷면들 (더미 ↔ 부채꼴, spread로 보간)
    private func fan(in geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<visualCount, id: \.self) { i in
                CardBack(showSheen: stage != .dealing)
                    .frame(width: cardW, height: cardH)
                    .matchedGeometryEffect(id: i, in: cardNS, isSource: !(stage == .drawn && selected == i))
                    .rotationEffect(.degrees(angle(i)), anchor: UnitPoint(x: 0.5, y: 2.0))
                    // 선택 카드는 y로만 위로, 이웃은 x로만 벌어짐 — 겹침 순서(z)는 항상 고정
                    .offset(x: xOffset(i, geo) + partX(i, geo), y: -liftY(i, geo) - focusedUp(i))
                    .opacity(opacity(i))
                    .zIndex(Double(i))
                    .animation(.easeOut(duration: 0.14), value: browseX)
                    .onTapGesture { onTapCard(i) }
                    .onLongPressGesture(minimumDuration: 0.3) { if stage == .spread { select(i) } }
            }
        }
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0),
                          anchor: .bottom, perspective: 0.32)
        .background(fanGroundShadow)
        .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
    }

    // MARK: - 레이아웃 (spread 보간)

    private func angle(_ i: Int) -> Double {
        let mid = Double(visualCount - 1) / 2
        let fan = (Double(i) - mid) * 5.4        // 펼침 각도
        let stack = (Double(i) - mid) * 0.8      // 더미: 거의 수직, 미세 팬
        return stack + (fan - stack) * spread
    }

    /// 더미(왼쪽) ↔ 중앙 보간
    private func xOffset(_ i: Int, _ geo: GeometryProxy) -> CGFloat {
        let mid = CGFloat(visualCount - 1) / 2
        let leftX = -geo.size.width * 0.30
        let stagger = (CGFloat(i) - mid) * 3     // 더미 두께
        return (leftX + stagger) * CGFloat(1 - spread)
    }

    /// 카드의 대략적인 화면 x 중심 (파도 계산용)
    private func cardScreenX(_ i: Int, _ geo: GeometryProxy) -> CGFloat {
        let a = angle(i) * .pi / 180
        let radius: CGFloat = 1.5 * cardH          // 회전 피벗(2.0h)에서 카드 중심까지
        return geo.size.width / 2 + xOffset(i, geo) + radius * CGFloat(sin(a))
    }

    /// 손가락 x와의 거리에 따른 상승량(가우시안) — 근처 카드가 y로만 살짝 올라오고 지나가면 내려감
    private func liftY(_ i: Int, _ geo: GeometryProxy) -> CGFloat {
        guard stage == .spread, let bx = browseX else { return 0 }
        let d = bx - cardScreenX(i, geo)
        let sigma: CGFloat = 34
        return 16 * exp(-(d * d) / (2 * sigma * sigma))
    }

    /// 뽑는 카드의 양옆이 벌어짐 — 이웃 카드를 바깥으로 밀어 선택 카드가 더 보이게
    private func partX(_ i: Int, _ geo: GeometryProxy) -> CGFloat {
        guard stage == .spread, let k = pullIndex, pullAmount > 0, i != k else { return 0 }
        let side: CGFloat = i < k ? -1 : 1
        let dist = CGFloat(abs(i - k))
        return side * 34 * pullAmount / dist        // 가까운 이웃일수록 크게 벌어짐
    }

    /// 뽑는 카드가 위로 빠져나오는 거리
    private func focusedUp(_ i: Int) -> CGFloat {
        (stage == .spread && i == pullIndex) ? pullUp : 0
    }

    private var tilt: Double { stage == .drawn ? 0 : 34 }

    private func opacity(_ i: Int) -> Double {
        if stage == .dealing { return i < dealtCount ? 1 : 0 }
        if stage == .drawn { return selected == i ? 1 : 0 }
        return 1
    }

    private var prompt: String {
        switch stage {
        case .dealing: return ""
        case .stacked: return "카드 더미를 옆으로 드래그해 펼쳐보세요"
        case .spread:  return "카드를 훑어 고른 뒤, 꾹 누르거나 위로 밀어 뽑으세요"
        case .drawn:   return ""
        }
    }

    // MARK: - 제스처

    /// 더미에서는 드래그로 펼치고, 펼친 뒤엔 훑기(hover) + 위로 스와이프로 선택
    private func tableDrag(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { v in
                if !dragging { dragging = true; dragStartSpread = spread }
                switch stage {
                case .stacked:
                    let delta = Double(v.translation.width) / Double(geo.size.width * 0.75)
                    let next = min(1, max(0, dragStartSpread + delta))
                    if Int(next * 10) != Int(spread * 10) { CardSound.shared.tick() }
                    spread = next
                case .spread:
                    // 드래그 시작 방향으로 모드 고정 — 가로=훑기(선택X), 세로 위=뽑기
                    if spreadDrag == nil {
                        let dx = abs(v.translation.width), dy = abs(v.translation.height)
                        guard dx > 12 || dy > 12 else { break }          // 방향 확정 대기
                        if dy > dx && v.translation.height < 0 {
                            spreadDrag = .lift
                            pullIndex = cardAt(x: v.startLocation.x, in: geo)   // 누른(맨 위) 카드
                        } else {
                            spreadDrag = .browse
                        }
                    }
                    switch spreadDrag {
                    case .browse:
                        browseX = v.location.x
                        let idx = cardAt(x: v.location.x, in: geo)
                        if idx != hovered { hovered = idx; CardSound.shared.tick(); CardSound.shared.slide(volume: 0.3) }
                    case .lift:
                        browseX = nil
                        let up = max(0, -v.translation.height)
                        pullUp = up
                        pullAmount = min(1, up / 130)          // 밀수록 양옆 벌어지고 카드가 나옴
                        if up >= 130, let k = pullIndex { select(k) }   // 누른 카드를 뽑음
                    case .none: break
                    }
                default: break
                }
            }
            .onEnded { _ in
                dragging = false
                spreadDrag = nil
                browseX = nil          // 손 떼면 카드들 제자리로
                if stage == .spread && pullIndex != nil {   // 덜 밀고 놓으면 원위치
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        pullIndex = nil; pullUp = 0; pullAmount = 0
                    }
                }
                if stage == .stacked {
                    if spread > 0.45 { completeSpread() }
                    else { withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { spread = 0 } }
                }
            }
    }

    /// 손가락 x에서 실제로 보이는(최상단) 카드 — 겹침에서 위 카드가 우선
    private func cardAt(x: CGFloat, in geo: GeometryProxy) -> Int {
        for i in stride(from: visualCount - 1, through: 0, by: -1) {
            if abs(x - cardScreenX(i, geo)) <= cardW / 2 { return i }
        }
        // 프레임 밖이면 가장 가까운 중심
        var best = 0; var bestD = CGFloat.greatestFiniteMagnitude
        for i in 0..<visualCount {
            let d = abs(x - cardScreenX(i, geo))
            if d < bestD { bestD = d; best = i }
        }
        return best
    }

    // MARK: - 전이

    private func dealIn() {
        guard stage == .dealing else { return }
        for i in 0..<visualCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dealtCount = i + 1 }
                CardSound.shared.tick()
                CardSound.shared.slide(volume: 0.35)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(visualCount) * 0.05 + 0.1) {
            stage = .stacked
        }
    }

    private func completeSpread() {
        CardSound.shared.riffle()
        CardSound.shared.riffleHaptic()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            spread = 1
            stage = .spread
        }
    }

    private func onTapCard(_ i: Int) {
        switch stage {
        case .stacked: completeSpread()
        case .spread: withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { hovered = i }  // 강조만
        default: break
        }
    }

    private func select(_ i: Int) {
        guard stage == .spread else { return }
        CardSound.shared.thud()
        CardSound.shared.slide(volume: 0.85)
        selected = i
        hovered = nil
        browseX = nil
        withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) {
            stage = .drawn
            pullIndex = nil; pullUp = 0; pullAmount = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.4)) { showReveal = true }
        }
    }

    private func dismissReveal() {
        withAnimation(.easeInOut(duration: 0.3)) { showReveal = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selected = nil
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { stage = .spread }
        }
    }

    // MARK: - 배경

    private var fanGroundShadow: some View {
        Ellipse()
            .fill(RadialGradient(colors: [.black.opacity(0.4), .clear],
                                 center: .center, startRadius: 4, endRadius: 170))
            .frame(width: 320, height: 96)
            .offset(y: 70)
            .blur(radius: 14)
            .opacity(stage == .drawn ? 0 : 0.9)
    }

    private var tableBackground: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0x2B3A5C), Color(hex: 0x141A2A)],
                           center: .center, startRadius: 40, endRadius: 520)
            RadialGradient(colors: [Color.white.opacity(0.06), .clear],
                           center: .top, startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
    }

    private var fallbackGrid: some View {
        TarotReadingView(session: session)
    }
}

// MARK: - 카드 뒷면

private struct CardBack: View {
    var showSheen: Bool
    @State private var sheen = false

    var body: some View {
        Image("tarot-back")
            .resizable()
            .scaledToFill()
            .frame(width: 104, height: 166)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 0.8)
            )
            .overlay(sheenOverlay.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)))
            .shadow(color: .black.opacity(0.45), radius: 7, x: 0, y: 5)
    }

    private var sheenOverlay: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.22), .clear],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .rotationEffect(.degrees(18))
            .offset(x: sheen ? 70 : -70)
            .opacity(showSheen ? 1 : 0)
            .onAppear {
                guard showSheen else { return }
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: false)) { sheen = true }
            }
    }
}

// MARK: - 뽑혀 중앙으로 오는 카드 (matchedGeometry 소스 + 커지는 연출)

private struct DrawnCardLayer: View {
    let drawn: TarotDrawn
    let namespace: Namespace.ID
    let matchedID: Int
    @State private var grow = false

    var body: some View {
        CardBack(showSheen: false)
            .matchedGeometryEffect(id: matchedID, in: namespace, isSource: true)
            .scaleEffect(grow ? 1.18 : 0.96)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) { grow = true }
            }
    }
}
