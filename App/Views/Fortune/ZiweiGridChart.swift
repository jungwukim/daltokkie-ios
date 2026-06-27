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
    private let plateHi = Color(hex: 0x2A2723)
    private let plateLo = Color(hex: 0x141310)
    private let champagne = Color(hex: 0xCBAE72)
    private let plateText = Color(hex: 0xCFC4AC)

    private func palace(_ zhi: String) -> ZiweiPalace? {
        chart.palaces.values.first { $0.zhi == zhi }
    }
    private func ageRange(_ palaceName: String) -> String? {
        guard let d = daxian?.first(where: { $0.palaceName == palaceName }) else { return nil }
        return "\(d.ageStart)–\(d.ageEnd)"
    }

    // 밝기 색상
    private func brightnessColor(_ b: String) -> Color {
        switch b {
        case "廟": return dtDyn(0xD97706, 0xECA13C)
        case "旺": return dtDyn(0xEA580C, 0xF0884C)
        case "得": return dtDyn(0x0284C7, 0x3FA9E0)
        case "利": return dtDyn(0x0D9488, 0x3CC0B2)
        case "陷": return dtDyn(0xE11D48, 0xF06080)
        default:   return dtDyn(0x8B8378, 0xA89C8C)   // 平·기타
        }
    }
    // 사화 배지 색
    private func siHuaColors(_ s: String) -> (bg: Color, fg: Color)? {
        switch s {
        case "化祿": return (Color(hex: 0xD1FAE5), Color(hex: 0x047857))
        case "化權": return (Color(hex: 0xFFE4E6), Color(hex: 0xBE123C))
        case "化科": return (Color(hex: 0xEDE9FE), Color(hex: 0x6D28D9))
        case "化忌": return (Color(hex: 0xE2E8F0), Color(hex: 0x334155))
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
                        if let c = siHuaColors(star.siHua) {
                            Text(star.siHua).font(DT.sans(7, .bold))
                                .foregroundStyle(c.fg)
                                .padding(.horizontal, 2).padding(.vertical, 0.5)
                                .background(c.bg).clipShape(RoundedRectangle(cornerRadius: 3))
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
            Text("紫微斗數").font(DT.serif(15, .bold)).tracking(2).foregroundStyle(champagne)
            Rectangle().fill(brass.opacity(0.6)).frame(width: 56, height: 0.8)
            VStack(spacing: 2) {
                Text("\(chart.solarYear)년 \(chart.solarMonth)월 \(chart.solarDay)일 \(String(format: "%02d:%02d", chart.hour, chart.minute))")
                Text("음력 \(chart.lunarYear).\(chart.isLeapMonth ? "윤" : "")\(chart.lunarMonth).\(chart.lunarDay)")
                Text("\(chart.isMale ? "남" : "여") · \(chart.yearGan)\(chart.yearZhi)년")
                Text("명궁 \(chart.mingGongZhi) · 신궁 \(chart.shenGongZhi)")
                Text(chart.wuXingJu.name).foregroundStyle(champagne.opacity(0.9))
            }
            .font(DT.sans(9))
            .foregroundStyle(plateText)
            .multilineTextAlignment(.center)
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [plateHi, plateLo], startPoint: .top, endPoint: .bottom))
        .overlay(Rectangle().stroke(brass.opacity(0.5), lineWidth: 1))
    }

    private func badge(_ t: String, _ bg: Color, _ fg: Color) -> some View {
        Text(t).font(DT.sans(7.5, .bold)).foregroundStyle(fg)
            .padding(.horizontal, 2.5).padding(.vertical, 0.5)
            .background(bg).clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
