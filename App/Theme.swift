// 달토끼 디자인 토큰 — 웹 /mobile 크래프트지 컨셉 (DESIGN.md 11-1)

import SwiftUI

enum DT {
    // 색상 팔레트
    static let bg = Color(hex: 0xF8F2E8)          // 크래프트지 배경
    static let card = Color(hex: 0xFAF6EE)        // 카드 크림
    static let accent = Color(hex: 0xD4789C)      // 포인트 핑크
    static let accentSoft = Color(hex: 0xF0DDE4)  // 버튼 연핑크
    static let ink = Color(hex: 0x2A2520)         // 본문 잉크
    static let inkSoft = Color(hex: 0x8B7E6A)     // 보조 텍스트
    static let line = Color(hex: 0xE8DCC4)        // 보더
    static let night = Color(hex: 0x2A2F50)       // 밤하늘 (CTA/탭 로고 배경)
    static let strokeBrown = Color(hex: 0x8B7355) // SVG 선 톤

    // 코너/간격
    static let radius: CGFloat = 16
    static let pagePadding: CGFloat = 20          // 웹 px-5

    // 타이포 (시스템 폰트 — Noto 번들은 후속 작업)
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// 크래프트지 카드 컨테이너
struct CraftCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DT.card)
            .clipShape(RoundedRectangle(cornerRadius: DT.radius))
            .overlay(
                RoundedRectangle(cornerRadius: DT.radius)
                    .stroke(DT.line, lineWidth: 1)
            )
    }
}

/// 섹션 타이틀 (세리프 + 잉크)
struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(DT.serif(15, .bold))
            .foregroundStyle(DT.ink)
    }
}
