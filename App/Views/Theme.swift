// 달토끼 디자인 토큰 — 웹 /mobile 크래프트지 컨셉 (DESIGN.md 11-1)

import SwiftUI
import CoreText

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
    static let pagePadding: CGFloat = 14          // 시안 측정값(카드행 13.5pt)

    // 타이포 — Pretendard 단일 통일 (번들 OFL). serif/sans 모두 Pretendard로 매핑
    // weight별 정적 파일을 직접 참조 → faux-bold 없이 진짜 굵기 사용
    private static func pretendard(_ weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "Pretendard-Bold"
        case .semibold:             return "Pretendard-SemiBold"
        case .medium:               return "Pretendard-Medium"
        default:                    return "Pretendard-Regular"
        }
    }
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(pretendard(weight), size: size)
    }
    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(pretendard(weight), size: size)
    }
}

/// 번들 커스텀 폰트 런타임 등록 (Info.plist UIAppFonts 대신 — GENERATE_INFOPLIST_FILE 유지)
enum DTFonts {
    static func register() {
        let names = ["Pretendard-Regular", "Pretendard-Medium", "Pretendard-SemiBold", "Pretendard-Bold"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "otf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

/// 오행(목·화·토·금·수) 색 — 한국 전통 톤 + 다크/라이트 가독성 보정
func sajuElementColor(_ element: String) -> Color {
    switch element {
    case "Wood":  return Color(hex: 0x6FA876)   // 목 — 청록
    case "Fire":  return Color(hex: 0xD9785E)   // 화 — 적
    case "Earth": return Color(hex: 0xC9A24B)   // 토 — 황
    case "Metal": return Color(hex: 0xAEB2BC)   // 금 — 은백
    case "Water": return Color(hex: 0x5B8FB9)   // 수 — 청
    default:      return DT.inkSoft
    }
}
func sajuElementKo(_ element: String) -> String {
    ["Wood": "목", "Fire": "화", "Earth": "토", "Metal": "금", "Water": "수"][element] ?? element
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

/// 모달 닫기 버튼 — 동그라미 + X (시스템 뒤로 버튼 원형과 통일)
struct CircleCloseButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(DT.ink)
                .frame(width: 30, height: 30)
                .background(DT.card, in: Circle())
                .overlay(Circle().stroke(DT.line, lineWidth: 1))
        }
        .accessibilityLabel("닫기")
    }
}

extension View {
    /// 상단 우측에 동그라미 X 닫기 버튼 추가 (모달/시트 공통)
    func dtCloseToolbar(_ action: @escaping () -> Void) -> some View {
        toolbar { ToolbarItem(placement: .topBarTrailing) { CircleCloseButton(action: action) } }
    }
}
