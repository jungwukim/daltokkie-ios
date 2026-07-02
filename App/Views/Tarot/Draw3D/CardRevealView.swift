// 타로 3D 뽑기 — 선택된 카드의 고급 풀스크린 공개 화면.
// 공개 연출 3종(의식형/시네마틱/토스)을 공개할 때마다 랜덤으로 하나 재생.
// 카드 뒷면→앞면 플립 + 자이로 광택 + 부유/그림자 + 키워드 + 기존 AI 타로 리딩.

import SwiftUI
import CoreMotion

enum RevealStyle: String, CaseIterable {
    case ceremonial, cinematic, toss
    var label: String {
        switch self {
        case .ceremonial: return "의식형"
        case .cinematic:  return "시네마틱"
        case .toss:       return "토스"
        }
    }
}

struct CardRevealView: View {
    @EnvironmentObject var appState: AppState
    let session: TarotSession
    let drawn: TarotDrawn
    let onClose: () -> Void

    // 공개할 때마다 3연출 중 랜덤 (뷰가 매 공개마다 새로 생성 → 매번 재추첨)
    @State private var style: RevealStyle = RevealStyle.allCases.randomElement() ?? .ceremonial

    @StateObject private var motion = MotionTilt()
    @State private var flip = false
    @State private var appear = false
    @State private var float = false
    // 연출별 상태
    @State private var rays = false        // A 광선/오라
    @State private var burst = false       // A 별가루 버스트
    @State private var sweep = false       // B 섬광 스윕
    @State private var glowPulse = false   // B 테두리 글로우
    @State private var tossIn = false      // C 3D 토스

    private let cardW: CGFloat = 196
    private let cardH: CGFloat = 312
    private let gold = Color(hex: 0xEBC77A)

    var body: some View {
        ZStack {
            background
            if style == .ceremonial { raysView; burstView }

            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 24)
                    cardShowcase
                    cardCaption
                    aiReading
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, DT.pagePadding)
            }
        }
        .overlay(alignment: .topTrailing) { closeButton }
        .onAppear { startSequence() }
        .onDisappear { motion.stop() }
    }

    // MARK: - 시퀀스

    private func startSequence() {
        motion.start()
        withAnimation(.easeOut(duration: 0.4)) { appear = true }
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { float = true }

        switch style {
        case .ceremonial:
            withAnimation(.easeOut(duration: 1.1)) { rays = true }
            after(0.55) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { flip = true }
                withAnimation(.easeOut(duration: 0.75)) { burst = true }
                CardSound.shared.slide(volume: 0.75); CardSound.shared.success()
            }
        case .cinematic:
            after(0.25) {
                withAnimation(.spring(response: 0.95, dampingFraction: 0.55)) { flip = true }
                CardSound.shared.slide(volume: 0.7)
            }
            after(0.6) { withAnimation(.easeIn(duration: 0.35)) { sweep = true } }
            after(1.1) {
                withAnimation(.easeInOut(duration: 0.45).repeatCount(2, autoreverses: true)) { glowPulse = true }
                CardSound.shared.success()
            }
        case .toss:
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { tossIn = true }
            after(0.12) {
                withAnimation(.spring(response: 0.62, dampingFraction: 0.62)) { flip = true }
                CardSound.shared.slide(volume: 0.85)
            }
            after(0.5) { CardSound.shared.thud(); CardSound.shared.success() }
        }
    }

    private func after(_ t: TimeInterval, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: work)
    }

    // MARK: - 카드 쇼케이스

    private var cardShowcase: some View {
        ZStack {
            cardImage(name: "tarot-back", reversed: false)
                .opacity(flip ? 0 : 1)
            cardImage(name: drawn.card.asset, reversed: drawn.isReversed)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(flip ? 1 : 0)
        }
        .frame(width: cardW, height: cardH)
        .overlay(sweepStreak)                                   // B
        .rotation3DEffect(.degrees(flip ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(style == .toss && !tossIn ? -38 : 0), axis: (x: 0.2, y: 0, z: 1))  // C
        .rotation3DEffect(.degrees(motion.roll * 9), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(-motion.pitch * 9), axis: (x: 1, y: 0, z: 0))
        .scaleEffect(tossScale)
        .offset(y: float ? -8 : 8)
        .shadow(color: .black.opacity(0.55), radius: glowPulse ? 34 : 24, x: 0, y: 18)
        .shadow(color: style == .cinematic && glowPulse ? gold.opacity(0.7) : .clear, radius: 20)
    }

    private var tossScale: CGFloat {
        if style == .toss { return tossIn ? 1 : 1.42 }
        return appear ? 1 : 0.85
    }

    private func cardImage(name: String, reversed: Bool) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(reversed ? 180 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style == .cinematic && glowPulse ? gold : .white.opacity(0.25),
                            lineWidth: style == .cinematic && glowPulse ? 2.5 : 1)
            )
            .overlay(glossOverlay.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)))
    }

    /// 자이로 광택 (모든 연출 공통)
    private var glossOverlay: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.32), .clear],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
        .rotationEffect(.degrees(24))
        .offset(x: CGFloat(motion.roll) * 80, y: CGFloat(motion.pitch) * 60)
        .blendMode(.softLight)
        .opacity(flip ? 1 : 0)
    }

    /// B — 엣지 통과 순간 흰 섬광이 카드를 사선으로 스윕
    private var sweepStreak: some View {
        Group {
            if style == .cinematic {
                LinearGradient(colors: [.clear, .white.opacity(0.85), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(width: cardW * 0.5)
                    .rotationEffect(.degrees(24))
                    .offset(x: sweep ? cardW : -cardW)
                    .opacity(sweep ? 0 : 0.9)
                    .blendMode(.screen)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    // MARK: - A: 광선 + 별가루

    private var raysView: some View {
        AngularGradient(
            gradient: Gradient(colors: [.clear, gold.opacity(0.55), .clear, gold.opacity(0.3),
                                        .clear, gold.opacity(0.5), .clear, gold.opacity(0.28), .clear]),
            center: .center)
        .frame(width: 620, height: 620)
        .scaleEffect(rays ? 1.5 : 0.2)
        .rotationEffect(.degrees(rays ? 22 : -8))
        .opacity(rays ? (flip ? 0.55 : 0.28) : 0)
        .blur(radius: 9)
        .offset(y: -40)
        .allowsHitTesting(false)
    }

    private var burstView: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { k in
                Circle()
                    .fill(gold)
                    .frame(width: k % 2 == 0 ? 5 : 3)
                    .offset(burstOffset(k))
                    .opacity(burst ? 0 : 0.9)
                    .scaleEffect(burst ? 1 : 0.3)
            }
        }
        .offset(y: -40)
        .allowsHitTesting(false)
    }

    private func burstOffset(_ k: Int) -> CGSize {
        let a = Double(k) / 16 * 2 * .pi
        let r: CGFloat = burst ? 190 : 8
        return CGSize(width: CGFloat(cos(a)) * r, height: CGFloat(sin(a)) * r)
    }

    // MARK: - 설명 / AI (기존)

    private var cardCaption: some View {
        VStack(spacing: 10) {
            Text(drawn.position).font(DT.sans(12, .semibold)).foregroundStyle(DT.accent)
            HStack(spacing: 6) {
                Text(drawn.card.nameKo).font(DT.serif(24, .bold)).foregroundStyle(.white)
                if drawn.isReversed {
                    Text("역방향").font(DT.sans(11, .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(hex: 0xD45555), in: Capsule())
                }
            }
            Text(drawn.card.name).font(DT.sans(12)).foregroundStyle(.white.opacity(0.6))
            let keywords = drawn.isReversed ? drawn.card.keywordsReversed : drawn.card.keywords
            HStack(spacing: 8) {
                ForEach(keywords, id: \.self) { kw in
                    Text(kw).font(DT.sans(12, .medium)).foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.white.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 0.8))
                }
            }
            .padding(.top, 4)
        }
        .opacity(flip ? 1 : 0)
        .animation(.easeIn(duration: 0.4).delay(0.3), value: flip)
    }

    private var aiReading: some View {
        Group {
            if flip {
                AIInterpretationView(title: "타로 리딩") {
                    AIProxy.interpretTarot(
                        cards: [[
                            "name": drawn.card.name, "nameKo": drawn.card.nameKo,
                            "isReversed": drawn.isReversed, "position": drawn.position,
                            "keywords": drawn.isReversed ? drawn.card.keywordsReversed : drawn.card.keywords,
                        ]],
                        spread: session.spread.rawValue, topic: session.topic, question: session.question,
                        gender: appState.profile?.gender, birthYear: appState.profile?.year,
                        region: appState.profile?.region)
                }
                .transition(.opacity)
            }
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.14), in: Circle())
        }
        .padding(.trailing, 16).padding(.top, 8)
        .accessibilityLabel("닫기")
    }

    private var background: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0x2A2F50), Color(hex: 0x0E1018)],
                           center: .top, startRadius: 20, endRadius: 640)
            // B: 급암전 + 비네트(스포트라이트)
            if style == .cinematic {
                RadialGradient(colors: [.clear, .black.opacity(0.85)],
                               center: .center, startRadius: 120, endRadius: 460)
                    .opacity(appear ? 1 : 0)
            }
            ForEach(0..<18, id: \.self) { i in
                Circle().fill(.white.opacity(0.5))
                    .frame(width: i % 3 == 0 ? 2.5 : 1.5)
                    .position(x: starX(i), y: starY(i))
                    .opacity(appear ? 0.8 : 0)
            }
        }
        .ignoresSafeArea()
    }

    private func starX(_ i: Int) -> CGFloat { CGFloat((i * 73 + 31) % 360) + 16 }
    private func starY(_ i: Int) -> CGFloat { CGFloat((i * 137 + 61) % 700) + 40 }
}

// MARK: - 자이로 기울임

@MainActor
final class MotionTilt: ObservableObject {
    @Published var roll: Double = 0
    @Published var pitch: Double = 0
    private let mgr = CMMotionManager()

    func start() {
        guard mgr.isDeviceMotionAvailable else { return }
        mgr.deviceMotionUpdateInterval = 1 / 30
        mgr.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            self.roll = max(-1, min(1, m.attitude.roll * 1.2))
            self.pitch = max(-1, min(1, m.attitude.pitch * 1.2))
        }
    }

    func stop() { mgr.stopDeviceMotionUpdates() }
}
