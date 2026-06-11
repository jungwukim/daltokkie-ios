// 점성술 + 자미두수 상세 (웹 mobile-natal-page / mobile-ziwei-page 대응)

import SwiftUI
import NatalKit
import ZiweiKit

// MARK: - 점성술

struct NatalDetailView: View {
    @EnvironmentObject var appState: AppState

    private let planetKo: [String: String] = [
        "Sun": "태양", "Moon": "달", "Mercury": "수성", "Venus": "금성",
        "Mars": "화성", "Jupiter": "목성", "Saturn": "토성", "Uranus": "천왕성",
        "Neptune": "해왕성", "Pluto": "명왕성", "Chiron": "키론",
        "NorthNode": "북교점", "SouthNode": "남교점", "Fortuna": "행운점",
    ]
    private let zodiacKo: [String: String] = [
        "Aries": "양자리", "Taurus": "황소자리", "Gemini": "쌍둥이자리", "Cancer": "게자리",
        "Leo": "사자자리", "Virgo": "처녀자리", "Libra": "천칭자리", "Scorpio": "전갈자리",
        "Sagittarius": "궁수자리", "Capricorn": "염소자리", "Aquarius": "물병자리", "Pisces": "물고기자리",
    ]
    private let aspectKo: [String: String] = [
        "conjunction": "합", "sextile": "육분", "square": "사각", "trine": "삼분", "opposition": "충",
    ]

    var body: some View {
        ScrollView {
            if let chart = appState.ensureNatal() {
                VStack(spacing: 16) {
                    if let angles = chart.angles {
                        CraftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "4대 축")
                                DetailRow(label: "ASC 상승점", value: angleText(angles.asc))
                                DetailRow(label: "MC 중천점", value: angleText(angles.mc))
                                DetailRow(label: "DESC 하강점", value: angleText(angles.desc))
                                DetailRow(label: "IC 천저점", value: angleText(angles.ic))
                            }
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "행성 배치")
                            ForEach(chart.planets, id: \.id) { p in
                                HStack {
                                    Text(planetKo[p.id] ?? p.id)
                                        .font(DT.sans(13, .medium))
                                        .foregroundStyle(DT.ink)
                                        .frame(width: 64, alignment: .leading)
                                    Text(zodiacKo[p.sign] ?? p.sign)
                                        .font(DT.sans(13))
                                        .foregroundStyle(DT.accent)
                                    Text(String(format: "%.1f°", p.degreeInSign))
                                        .font(DT.sans(12))
                                        .foregroundStyle(DT.inkSoft)
                                    if p.isRetrograde {
                                        Text("℞")
                                            .font(DT.sans(12, .bold))
                                            .foregroundStyle(DT.accent)
                                    }
                                    Spacer()
                                    if let house = p.house {
                                        Text("\(house)하우스")
                                            .font(DT.sans(12))
                                            .foregroundStyle(DT.inkSoft)
                                    }
                                }
                            }
                        }
                    }

                    if !chart.aspects.isEmpty {
                        CraftCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionTitle(text: "주요 어스펙트")
                                ForEach(Array(chart.aspects.prefix(15).enumerated()), id: \.offset) { _, a in
                                    HStack {
                                        Text("\(planetKo[a.planet1] ?? a.planet1) – \(planetKo[a.planet2] ?? a.planet2)")
                                            .font(DT.sans(13))
                                            .foregroundStyle(DT.ink)
                                        Spacer()
                                        Text(aspectKo[a.type] ?? a.type)
                                            .font(DT.sans(12, .semibold))
                                            .foregroundStyle(DT.accent)
                                        Text(String(format: "오차 %.1f°", a.orb))
                                            .font(DT.sans(11))
                                            .foregroundStyle(DT.inkSoft)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 12)
            } else {
                Text("차트를 계산할 수 없어요")
                    .font(DT.sans(14))
                    .foregroundStyle(DT.inkSoft)
                    .padding(.top, 60)
            }
        }
        .background(DT.bg)
        .navigationTitle("점성술")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func angleText(_ p: AnglePoint) -> String {
        "\(zodiacKo[p.sign] ?? p.sign) \(String(format: "%.1f°", p.degreeInSign))"
    }
}

// MARK: - 자미두수

struct ZiweiDetailView: View {
    @EnvironmentObject var appState: AppState

    private let palaceOrder = [
        "命宮", "兄弟", "夫妻", "子女", "財帛", "疾厄",
        "遷移", "交友", "官祿", "田宅", "福德", "父母",
    ]
    private let palaceKo: [String: String] = [
        "命宮": "명궁", "兄弟": "형제궁", "夫妻": "부처궁", "子女": "자녀궁",
        "財帛": "재백궁", "疾厄": "질액궁", "遷移": "천이궁", "交友": "교우궁",
        "官祿": "관록궁", "田宅": "전택궁", "福德": "복덕궁", "父母": "부모궁",
    ]

    var body: some View {
        ScrollView {
            if let chart = appState.ensureZiwei() {
                VStack(spacing: 16) {
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "기본 정보")
                            DetailRow(label: "음력 생일", value: "\(chart.lunarYear)년 \(chart.isLeapMonth ? "윤" : "")\(chart.lunarMonth)월 \(chart.lunarDay)일")
                            DetailRow(label: "연주", value: "\(chart.yearGan)\(chart.yearZhi)")
                            DetailRow(label: "명궁", value: chart.mingGongZhi)
                            DetailRow(label: "신궁", value: chart.shenGongZhi)
                            DetailRow(label: "오행국", value: chart.wuXingJu.name)
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "12궁 성요 배치")
                            ForEach(palaceOrder, id: \.self) { name in
                                if let palace = chart.palaces[name] {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(palaceKo[name] ?? name)
                                                .font(DT.sans(12, .semibold))
                                                .foregroundStyle(palace.isShenGong ? DT.accent : DT.ink)
                                            Text(palace.ganZhi)
                                                .font(DT.sans(10))
                                                .foregroundStyle(DT.inkSoft)
                                        }
                                        .frame(width: 64, alignment: .leading)
                                        Text(palace.stars.isEmpty
                                             ? "—"
                                             : palace.stars.map { star in
                                                 star.name + (star.brightness.isEmpty ? "" : "(\(star.brightness))") + (star.siHua.isEmpty ? "" : "·\(star.siHua)")
                                             }.joined(separator: " "))
                                            .font(DT.sans(12))
                                            .foregroundStyle(DT.ink)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }

                    if let liunian = appState.ziweiLiunian {
                        CraftCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionTitle(text: "올해 유년 (\(String(liunian.year))년)")
                                DetailRow(label: "유년 간지", value: "\(liunian.gan)\(liunian.zhi)")
                                DetailRow(label: "유년 명궁", value: "\(liunian.mingGongZhi) (\(palaceKo[liunian.natalPalaceAtMing] ?? liunian.natalPalaceAtMing) 자리)")
                                DetailRow(label: "현재 대한", value: "\(palaceKo[liunian.daxianPalaceName] ?? liunian.daxianPalaceName) \(liunian.daxianAgeStart)~\(liunian.daxianAgeEnd)세")
                            }
                        }
                    }

                    if let daxianList = appState.ziweiDaxian {
                        CraftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "대한(大限) 흐름")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(daxianList, id: \.ageStart) { d in
                                            VStack(spacing: 4) {
                                                Text("\(d.ageStart)~\(d.ageEnd)세")
                                                    .font(DT.sans(10))
                                                    .foregroundStyle(DT.inkSoft)
                                                Text(palaceKo[d.palaceName] ?? d.palaceName)
                                                    .font(DT.sans(13, .bold))
                                                    .foregroundStyle(DT.ink)
                                                Text(d.mainStars.isEmpty ? "—" : d.mainStars.joined(separator: "·"))
                                                    .font(DT.sans(10))
                                                    .foregroundStyle(DT.accent)
                                                    .lineLimit(1)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(DT.bg)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 12)
            } else {
                Text("명반을 계산할 수 없어요")
                    .font(DT.sans(14))
                    .foregroundStyle(DT.inkSoft)
                    .padding(.top, 60)
            }
        }
        .background(DT.bg)
        .navigationTitle("자미두수")
        .navigationBarTitleDisplayMode(.inline)
    }
}
