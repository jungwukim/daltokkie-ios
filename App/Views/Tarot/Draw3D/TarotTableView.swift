// 타로 3D 뽑기 무대 — 버드뷰 펠트 테이블에 부채꼴로 겹친 카드 뒷면.
// 탭 → "사사삭" 펼침(사운드+햅틱) → 한 장 선택 → 카드가 뽑혀 중앙으로 날아오고 → 고급 공개 화면.
// 원카드(1장) 플로우 POC. (reduce motion 시 기존 그리드로 폴백)

import SwiftUI

struct TarotTableView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let session: TarotSession

    private enum Stage { case dealing, stacked, fanned, drawn }
    @State private var stage: Stage = .dealing
    @State private var dealtCount = 0
    @State private var hovered: Int?
    @State private var selected: Int?
    @State private var showReveal = false
    @Namespace private var cardNS

    // 부채꼴 구성
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

                // 안내 문구 — 부채꼴 바로 아래
                Text(prompt)
                    .font(DT.sans(13, .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.7)
                    .opacity(stage == .drawn ? 0 : 1)

                // 뽑힌 카드 → 중앙으로 날아옴 (matchedGeometry)
                if stage == .drawn, let drawn = session.cards.first {
                    DrawnCardLayer(drawn: drawn, namespace: cardNS,
                                   matchedID: selected ?? 0)
                        .frame(width: cardW, height: cardH)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.38)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onTapGesture { if stage == .stacked { openFan() } }
            .overlay {
                if showReveal, let drawn = session.cards.first {
                    CardRevealView(session: session, drawn: drawn) { dismissReveal() }
                        .transition(.opacity)
                }
            }
            .onAppear { dealIn() }
        }
    }

    // 부채꼴 카드 뒷면들
    private func fan(in geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<visualCount, id: \.self) { i in
                CardBack(showSheen: stage != .dealing)
                    .frame(width: cardW, height: cardH)
                    .matchedGeometryEffect(id: i, in: cardNS, isSource: !(stage == .drawn && selected == i))
                    .rotationEffect(.degrees(angle(i)), anchor: UnitPoint(x: 0.5, y: 2.0))
                    .scaleEffect(hovered == i ? 1.07 : 1)
                    .offset(y: hovered == i ? -26 : 0)
                    .opacity(opacity(i))
                    .zIndex(hovered == i ? 200 : Double(i))
                    .onTapGesture { onTapCard(i) }
            }
        }
        .rotation3DEffect(.degrees(tilt), axis: (x: 1, y: 0, z: 0),
                          anchor: .bottom, perspective: 0.32)
        .background(fanGroundShadow)
        .position(x: geo.size.width / 2, y: geo.size.height * 0.48)
        .gesture(browseDrag(in: geo))
    }

    // MARK: - 레이아웃 계산

    private func angle(_ i: Int) -> Double {
        let mid = Double(visualCount - 1) / 2
        let step: Double = (stage == .fanned || stage == .drawn) ? 5.4 : 2.2
        return (Double(i) - mid) * step
    }

    private var tilt: Double { stage == .drawn ? 0 : 34 }

    private func opacity(_ i: Int) -> Double {
        if stage == .dealing { return i < dealtCount ? 1 : 0 }
        if stage == .drawn { return selected == i ? 1 : 0 }   // 선택 외 사라짐
        return 1
    }

    private var prompt: String {
        switch stage {
        case .dealing: return ""
        case .stacked: return "카드를 터치해 펼쳐보세요"
        case .fanned:  return "마음이 끌리는 카드를 한 장 선택하세요"
        case .drawn:   return ""
        }
    }

    // MARK: - 인터랙션

    private func dealIn() {
        guard stage == .dealing else { return }
        for i in 0..<visualCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dealtCount = i + 1 }
                CardSound.shared.tick()
                CardSound.shared.slide(volume: 0.4)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(visualCount) * 0.06 + 0.1) {
            stage = .stacked
        }
    }

    private func openFan() {
        CardSound.shared.riffle()
        CardSound.shared.riffleHaptic()
        withAnimation(.spring(response: 0.6, dampingFraction: 0.78)) { stage = .fanned }
    }

    private func onTapCard(_ i: Int) {
        switch stage {
        case .stacked: openFan()
        case .fanned: select(i)
        default: break
        }
    }

    private func select(_ i: Int) {
        CardSound.shared.thud()
        CardSound.shared.slide(volume: 0.8)
        selected = i
        hovered = nil
        withAnimation(.spring(response: 0.62, dampingFraction: 0.8)) { stage = .drawn }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.4)) { showReveal = true }
        }
    }

    private func dismissReveal() {
        withAnimation(.easeInOut(duration: 0.3)) { showReveal = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selected = nil
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { stage = .fanned }
        }
    }

    /// 손가락을 좌우로 끌면 가장 가까운 카드 강조(훑기)
    private func browseDrag(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { v in
                guard stage == .fanned else { return }
                let rel = (v.location.x - geo.size.width / 2) / (geo.size.width * 0.42)
                let idx = Int((rel * Double(visualCount) / 2 + Double(visualCount - 1) / 2).rounded())
                let clamped = max(0, min(visualCount - 1, idx))
                if clamped != hovered {
                    hovered = clamped
                    CardSound.shared.tick()
                }
            }
            .onEnded { _ in
                if stage == .fanned, let h = hovered { select(h) }
            }
    }

    // MARK: - 배경 (펠트 테이블)

    /// 부채꼴 아래 타원 그림자 — 테이블에 놓인 느낌
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

    // MARK: - 폴백 (reduce motion)

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

// MARK: - 뽑혀 중앙으로 오는 카드 (matchedGeometry 소스)

private struct DrawnCardLayer: View {
    let drawn: TarotDrawn
    let namespace: Namespace.ID
    let matchedID: Int

    var body: some View {
        CardBack(showSheen: false)
            .matchedGeometryEffect(id: matchedID, in: namespace, isSource: true)
    }
}
