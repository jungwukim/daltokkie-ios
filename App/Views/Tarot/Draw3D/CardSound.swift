// 타로 3D 뽑기 — 카드 사운드 + 햅틱 레이어
// 사운드 파일(card-slide / card-riffle)이 번들에 있으면 재생, 없으면 햅틱만으로 우아하게 폴백.
// 무음 스위치 존중(.ambient) — 점잖은 기본값.

import AVFoundation
import UIKit
import CoreHaptics

@MainActor
final class CardSound {
    static let shared = CardSound()

    private var players: [AVAudioPlayer] = []   // 겹침 재생용 풀
    private var poolIndex = 0
    private var hapticEngine: CHHapticEngine?
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let notify = UINotificationFeedbackGenerator()

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        prepareHaptics()
    }

    // MARK: - 사운드 (없으면 무음 — 햅틱이 대체)

    /// 카드 한 장 미끄러지는 짧은 소리. 풀에서 라운드로빈으로 꺼내 겹침 재생.
    func slide(volume: Float = 0.6) {
        guard let player = player(named: "card-slide") else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    /// 부채꼴 펼침 리플("사사삭") — 긴 샘플이 있으면 1회 재생.
    func riffle(volume: Float = 0.7) {
        guard let player = player(named: "card-riffle") else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    private func player(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "wav") else { return nil }
        // 같은 파일을 여러 인스턴스로 풀링(겹침 재생). 최대 4개 순환.
        if players.count < 4, let p = try? AVAudioPlayer(contentsOf: url) {
            p.prepareToPlay()
            players.append(p)
            return p
        }
        guard !players.isEmpty else { return nil }
        poolIndex = (poolIndex + 1) % players.count
        return players[poolIndex]
    }

    // MARK: - 햅틱

    func tick() { impact.impactOccurred(intensity: 0.5) }
    func thud() { impact.impactOccurred(intensity: 1.0) }
    func success() { notify.notificationOccurred(.success) }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }

    /// 펼침 텍스처 — 짧은 transient를 연속으로 흩뿌려 "드르륵" 리플감.
    func riffleHaptic(duration: TimeInterval = 0.9, count: Int = 14) {
        guard let engine = hapticEngine else {
            impact.impactOccurred(intensity: 0.6); return
        }
        var events: [CHHapticEvent] = []
        for i in 0..<count {
            let t = duration * Double(i) / Double(count)
            let intensity = Float(0.35 + 0.25 * Double(i) / Double(count))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    .init(parameterID: .hapticIntensity, value: intensity),
                    .init(parameterID: .hapticSharpness, value: 0.7),
                ],
                relativeTime: t))
        }
        if let pattern = try? CHHapticPattern(events: events, parameters: []),
           let player = try? engine.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}
