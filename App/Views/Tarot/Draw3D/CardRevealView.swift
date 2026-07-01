// 타로 3D 뽑기 — 선택된 카드의 고급 풀스크린 공개 화면.
// 카드가 뒷면→앞면으로 플립, 자이로 기울임에 광택(gloss)이 흐르고, 부드러운 부유/그림자 + ✨.
// 하단에 키워드 + 기존 AI 타로 리딩 연결.

import SwiftUI
import CoreMotion

struct CardRevealView: View {
    @EnvironmentObject var appState: AppState
    let session: TarotSession
    let drawn: TarotDrawn
    let onClose: () -> Void

    @StateObject private var motion = MotionTilt()
    @State private var flip = false        // false=뒷면, true=앞면
    @State private var appear = false
    @State private var float = false

    private let cardW: CGFloat = 196
    private let cardH: CGFloat = 312

    var body: some View {
        ZStack {
            background

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
        .onAppear {
            motion.start()
            withAnimation(.easeOut(duration: 0.4)) { appear = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.7)) { flip = true }
                CardSound.shared.slide(volume: 0.7)
                CardSound.shared.success()
            }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { float = true }
        }
        .onDisappear { motion.stop() }
    }

    // MARK: - 카드 쇼케이스 (플립 + 자이로 광택)

    private var cardShowcase: some View {
        ZStack {
            // 뒷면
            cardImage(name: "tarot-back", reversed: false)
                .opacity(flip ? 0 : 1)
            // 앞면 (거울상 보정)
            cardImage(name: drawn.card.asset, reversed: drawn.isReversed)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(flip ? 1 : 0)
        }
        .frame(width: cardW, height: cardH)
        .rotation3DEffect(.degrees(flip ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        // 자이로 기울임
        .rotation3DEffect(.degrees(motion.roll * 9), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(-motion.pitch * 9), axis: (x: 1, y: 0, z: 0))
        .offset(y: float ? -8 : 8)
        .scaleEffect(appear ? 1 : 0.85)
        .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 18)
    }

    private func cardImage(name: String, reversed: Bool) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .rotationEffect(.degrees(reversed ? 180 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            .overlay(glossOverlay.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)))
    }

    /// 자이로에 따라 흐르는 광택
    private var glossOverlay: some View {
        LinearGradient(
            colors: [.clear, .white.opacity(0.32), .clear],
            startPoint: .topLeading, endPoint: .bottomTrailing)
        .rotationEffect(.degrees(24))
        .offset(x: CGFloat(motion.roll) * 80, y: CGFloat(motion.pitch) * 60)
        .blendMode(.softLight)
        .opacity(flip ? 1 : 0)
    }

    // MARK: - 카드 설명

    private var cardCaption: some View {
        VStack(spacing: 10) {
            Text(drawn.position)
                .font(DT.sans(12, .semibold))
                .foregroundStyle(DT.accent)
            HStack(spacing: 6) {
                Text(drawn.card.nameKo)
                    .font(DT.serif(24, .bold))
                    .foregroundStyle(.white)
                if drawn.isReversed {
                    Text("역방향")
                        .font(DT.sans(11, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(hex: 0xD45555), in: Capsule())
                }
            }
            Text(drawn.card.name)
                .font(DT.sans(12))
                .foregroundStyle(.white.opacity(0.6))

            // 키워드 칩
            let keywords = drawn.isReversed ? drawn.card.keywordsReversed : drawn.card.keywords
            HStack(spacing: 8) {
                ForEach(keywords, id: \.self) { kw in
                    Text(kw)
                        .font(DT.sans(12, .medium))
                        .foregroundStyle(.white.opacity(0.92))
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

    // MARK: - AI 리딩 (기존 재사용)

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
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.14), in: Circle())
        }
        .padding(.trailing, 16)
        .padding(.top, 8)
        .accessibilityLabel("닫기")
    }

    private var background: some View {
        ZStack {
            RadialGradient(colors: [Color(hex: 0x2A2F50), Color(hex: 0x0E1018)],
                           center: .top, startRadius: 20, endRadius: 640)
            // ✨ 은은한 별빛
            ForEach(0..<18, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.5))
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
            // 과한 흔들림 방지 — 살짝 감쇠 + 클램프
            self.roll = max(-1, min(1, m.attitude.roll * 1.2))
            self.pitch = max(-1, min(1, m.attitude.pitch * 1.2))
        }
    }

    func stop() { mgr.stopDeviceMotionUpdates() }
}
