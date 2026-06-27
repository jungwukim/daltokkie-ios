// 자미두수 명반 4×4 그리드 — 웹 ziwei-grid-chart 포팅
// 12지지 고정 배치(巳午未申 / 辰·酉 / 卯·戌 / 寅丑子亥) + 중앙 2×2 정보

import SwiftUI
import ZiweiKit

struct ZiweiGridChart: View {
    let chart: ZiweiChart
    let daxian: [DaxianInfo]?
    let palaceKo: [String: String]

    // 지지 → 그리드 (행,열). 중앙(1~2행,1~2열)은 정보 영역
    private let cells: [(zhi: String, r: Int, c: Int)] = [
        ("巳", 0, 0), ("午", 0, 1), ("未", 0, 2), ("申", 0, 3),
        ("辰", 1, 0),                             ("酉", 1, 3),
        ("卯", 2, 0),                             ("戌", 2, 3),
        ("寅", 3, 0), ("丑", 3, 1), ("子", 3, 2), ("亥", 3, 3),
    ]
    private let cellH: CGFloat = 104

    // 인스트루먼트 팔레트 (출생차트 다이얼과 통일 — 고정색)
    private let ivoryHi = Color(hex: 0xF8F2E6)
    private let ivoryLo = Color(hex: 0xE7DBC2)
    private let mingHi  = Color(hex: 0xF4E9CE)
    private let mingLo  = Color(hex: 0xE4D0A4)
    private let brass   = Color(hex: 0xB8975A)
    private let brassSoft = Color(hex: 0x8C6E3C)
    private let insInk  = Color(hex: 0x2C2620)
    private let insInkSoft = Color(hex: 0x6E5C3C)

    private func palace(_ zhi: String) -> ZiweiPalace? {
        chart.palaces.values.first { $0.zhi == zhi }
    }
    private func ageRange(_ palaceName: String) -> String? {
        guard let d = daxian?.first(where: { $0.palaceName == palaceName }) else { return nil }
        return "\(d.ageStart)–\(d.ageEnd)"
    }

    // 밝기 색상 — 깊고 차분한 톤(네온 배제)으로 절제
    private func brightnessColor(_ b: String) -> Color {
        switch b {
        case "廟", "旺": return Color(hex: 0xB07D2E)   // 강 — 깊은 골드
        case "得", "利": return Color(hex: 0x3C6E82)   // 중 — 머스키 블루
        case "陷":       return Color(hex: 0xA8455A)   // 약 — 깊은 로즈
        default:         return Color(hex: 0x9A9082)   // 平·기타
        }
    }
    // 사화 — 파스텔 배지 대신 텍스트 색만(절제)
    private func siHuaColor(_ s: String) -> Color? {
        switch s {
        case "化祿": return Color(hex: 0x3E7D54)
        case "化權": return Color(hex: 0xA83F4E)
        case "化科": return Color(hex: 0x5A5AA0)
        case "化忌": return Color(hex: 0x6A6E74)
        default: return nil
        }
    }

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / 4
            ZStack {
                ForEach(cells.indices, id: \.self) { i in
                    let cell = cells[i]
                    paletteCell(cell.zhi)
                        .frame(width: cellW, height: cellH)
                        .position(x: cellW * (CGFloat(cell.c) + 0.5),
                                  y: cellH * (CGFloat(cell.r) + 0.5))
                }
                centerInfo
                    .frame(width: cellW * 2, height: cellH * 2)
                    .position(x: geo.size.width / 2, y: cellH * 2)
            }
        }
        .frame(height: cellH * 4)
        .accessibilityElement()
        .accessibilityLabel("자미두수 명반 — 12궁 성요 배치도")
    }

    @ViewBuilder
    private func paletteCell(_ zhi: String) -> some View {
        let p = palace(zhi)
        let isMing = (p?.name == "命宮")
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Text(p.map { palaceKo[$0.name] ?? $0.name } ?? zhi)
                    .font(DT.sans(9.5, .bold))
                    .foregroundStyle(isMing ? brassSoft : insInk)
                if isMing { badge("命", brass, Color(hex: 0x2A2620)) }
                if p?.isShenGong == true { badge("身", Color(hex: 0xC9CBD0), Color(hex: 0x2A2620)) }
                Spacer(minLength: 0)
                Text(p?.ganZhi ?? zhi)
                    .font(DT.sans(8))
                    .foregroundStyle(insInkSoft.opacity(0.75))
            }
            if let p {
                ForEach(p.stars.indices, id: \.self) { si in
                    let star = p.stars[si]
                    HStack(spacing: 2) {
                        Text(star.name).font(DT.sans(9.5, .medium)).foregroundStyle(insInk)
                        if !star.brightness.isEmpty {
                            Text(star.brightness).font(DT.sans(8.5, .bold))
                                .foregroundStyle(brightnessColor(star.brightness))
                        }
                        if let c = siHuaColor(star.siHua) {
                            Text(star.siHua.replacingOccurrences(of: "化", with: ""))
                                .font(DT.sans(8, .bold)).foregroundStyle(c)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if let p, let age = ageRange(p.name) {
                Text("\(age)세").font(DT.sans(7.5))
                    .foregroundStyle(insInkSoft)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(LinearGradient(colors: isMing ? [mingHi, mingLo] : [ivoryHi, ivoryLo],
                                   startPoint: .top, endPoint: .bottom))
        .overlay(Rectangle().stroke(brass.opacity(0.42), lineWidth: 0.7))
    }

    private var centerInfo: some View {
        VStack(spacing: 5) {
            Text("紫微斗數").font(DT.serif(15, .bold)).tracking(2).foregroundStyle(brassSoft)
            Rectangle().fill(brass.opacity(0.5)).frame(width: 52, height: 0.8)
            VStack(spacing: 2) {
                Text("\(chart.solarYear)년 \(chart.solarMonth)월 \(chart.solarDay)일 \(String(format: "%02d:%02d", chart.hour, chart.minute))")
                Text("\(chart.isMale ? "남" : "여") · \(chart.yearGan)\(chart.yearZhi)년")
                Text("명궁 \(chart.mingGongZhi) · 신궁 \(chart.shenGongZhi)")
                Text(chart.wuXingJu.name).foregroundStyle(brassSoft)
            }
            .font(DT.sans(9))
            .foregroundStyle(insInkSoft)
            .multilineTextAlignment(.center)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [ivoryHi, ivoryLo], startPoint: .top, endPoint: .bottom))
        .overlay(Rectangle().stroke(brass.opacity(0.42), lineWidth: 0.7))
    }

    private func badge(_ t: String, _ bg: Color, _ fg: Color) -> some View {
        Text(t).font(DT.sans(7.5, .bold)).foregroundStyle(fg)
            .padding(.horizontal, 2.5).padding(.vertical, 0.5)
            .background(bg).clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
