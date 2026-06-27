// 점성술 + 자미두수 상세 (웹 mobile-natal-page / mobile-ziwei-page 대응)
// 점성술: 밤하늘 히어로 + Big3 + 네이티브 카드 섹션 리디자인

import SwiftUI
import NatalKit
import ZiweiKit

// MARK: - 점성술 공용 (원소색/별자리 인덱스)

private let natalSignIndex: [String: Int] = [
    "Aries": 0, "Taurus": 1, "Gemini": 2, "Cancer": 3, "Leo": 4, "Virgo": 5,
    "Libra": 6, "Scorpio": 7, "Sagittarius": 8, "Capricorn": 9, "Aquarius": 10, "Pisces": 11,
]
/// 원소색 (불=테라코타 / 흙=초록 / 바람=골드 / 물=블루) — 크래프트지 카드용 채도
private func natalElementColor(_ sign: String) -> Color {
    switch (natalSignIndex[sign] ?? 0) % 4 {
    case 0:  return dtDyn(0xC2714E, 0xD89472)   // Fire
    case 1:  return dtDyn(0x5E9A6E, 0x83BE92)   // Earth
    case 2:  return dtDyn(0xB58A2E, 0xD4AD55)   // Air
    default: return dtDyn(0x4E7FA8, 0x77A8CE)   // Water
    }
}
private func natalElementKo(_ sign: String) -> String {
    switch (natalSignIndex[sign] ?? 0) % 4 {
    case 0:  return "불"
    case 1:  return "흙"
    case 2:  return "바람"
    default: return "물"
    }
}

/// 밤하늘 별 배경 (결정적 — Date/random 미사용)
struct StarField: View {
    var body: some View {
        Canvas { ctx, size in
            func frac(_ v: Double) -> Double { v - floor(v) }
            for i in 0..<48 {
                let fx = frac(sin(Double(i) * 12.9898) * 43758.5453)
                let fy = frac(sin(Double(i) * 78.233) * 12543.123)
                let r  = 0.6 + frac(sin(Double(i) * 3.17) * 991.0) * 1.7
                let op = 0.18 + frac(sin(Double(i) * 5.71) * 557.0) * 0.55
                let x = fx * size.width, y = fy * size.height
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(.white.opacity(op)))
            }
        }
    }
}

/// 밤하늘 히어로용 요약 칩 (값 + 라벨, 선택적 원소색 틴트)
struct DarkStatChip: View {
    let value: String
    let label: String
    var tint: Color? = nil

    private static let brass = Color(hex: 0xB8975A)

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DT.sans(13, .bold)).foregroundStyle(DT.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(label)
                .font(DT.sans(9)).foregroundStyle(DT.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background((tint ?? Self.brass).opacity(tint == nil ? 0.08 : 0.14),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke((tint ?? Self.brass).opacity(0.38), lineWidth: 0.7))
    }
}

// MARK: - 점성술

struct NatalDetailView: View {
    @EnvironmentObject var appState: AppState

    private let planetKo: [String: String] = [
        "Sun": "태양", "Moon": "달", "Mercury": "수성", "Venus": "금성",
        "Mars": "화성", "Jupiter": "목성", "Saturn": "토성", "Uranus": "천왕성",
        "Neptune": "해왕성", "Pluto": "명왕성", "Chiron": "키론",
        "NorthNode": "북교점", "SouthNode": "남교점", "Fortuna": "행운점",
    ]
    private let planetGlyph: [String: String] = [
        "Sun": "☉", "Moon": "☽", "Mercury": "☿", "Venus": "♀", "Mars": "♂",
        "Jupiter": "♃", "Saturn": "♄", "Uranus": "♅", "Neptune": "♆", "Pluto": "♇",
        "Chiron": "⚷", "NorthNode": "☊", "SouthNode": "☋", "Fortuna": "⊗",
    ]
    private let zodiacKo: [String: String] = [
        "Aries": "양자리", "Taurus": "황소자리", "Gemini": "쌍둥이자리", "Cancer": "게자리",
        "Leo": "사자자리", "Virgo": "처녀자리", "Libra": "천칭자리", "Scorpio": "전갈자리",
        "Sagittarius": "궁수자리", "Capricorn": "염소자리", "Aquarius": "물병자리", "Pisces": "물고기자리",
    ]
    private let aspectKo: [String: String] = [
        "conjunction": "합", "sextile": "육분", "square": "사각", "trine": "삼분", "opposition": "충",
    ]
    private let aspectGlyph: [String: String] = [
        "conjunction": "☌", "sextile": "⚹", "square": "□", "trine": "△", "opposition": "☍",
    ]
    private func aspectColor(_ type: String) -> Color {
        switch type {
        case "conjunction": return dtDyn(0x8B5CF6, 0xA98CF0)
        case "sextile":     return dtDyn(0x22A06B, 0x46C68E)
        case "trine":       return dtDyn(0x3B7FD4, 0x6BA3E6)
        case "square":      return dtDyn(0xD9534F, 0xE87B77)
        case "opposition":  return dtDyn(0xE07B2E, 0xED9B57)
        default:            return DT.inkSoft
        }
    }

    var body: some View {
        ScrollView {
            if let chart = appState.ensureNatal() {
                VStack(spacing: 16) {
                    celestialHero(chart)
                    if let angles = chart.angles { axisSection(angles) }
                    planetSection(chart)
                    if !chart.houses.isEmpty { houseSection(chart) }
                    if !chart.aspects.isEmpty { aspectSection(chart) }

                    if let profile = appState.profile {
                        AIInterpretationView(title: "달토끼 점성 해석") {
                            AIProxy.interpretNatal(chart: chart, gender: profile.gender, birthYear: profile.year)
                        }
                        AIContentPanel(title: "점성술 세부 해석", sections: AIContentSections.natal) { id, tone in
                            AIProxy.content(id: id, tone: tone, gender: profile.gender, birthYear: profile.year,
                                            birthMonth: profile.month, birthDay: profile.day, birthHour: profile.hour, birthMinute: profile.minute,
                                            natalChart: chart)
                        }
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 12)
            } else {
                ContentUnavailableView("출생 차트를 계산할 수 없어요", systemImage: "moon.stars",
                                       description: Text("생년월일시 정보를 확인해 주세요."))
                    .padding(.top, 40)
            }
        }
        .background(DT.bg)
        .navigationTitle("점성술")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 밤하늘 히어로 (원형 차트 + Big3)
    private func celestialHero(_ chart: NatalChart) -> some View {
        let hasWheel = chart.angles != nil && !chart.houses.isEmpty
        return ZStack {
            // 크래프트지 라이트 하우징 — 메탈 다이얼/브라스만 포인트
            RoundedRectangle(cornerRadius: DT.radius).fill(DT.card)
            VStack(spacing: 14) {
                HStack {
                    Text("출생 차트")
                        .font(DT.serif(16, .bold))
                        .foregroundStyle(DT.ink)
                    Spacer()
                    Text("☽").font(.system(size: 15)).foregroundStyle(Color(hex: 0x8C6E3C))
                }
                if hasWheel {
                    NatalDialChart(chart: chart)
                        .padding(.horizontal, 2)
                }
                big3Row(chart)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: DT.radius))
        .overlay(RoundedRectangle(cornerRadius: DT.radius).stroke(Color(hex: 0xB8975A).opacity(0.30), lineWidth: 1))
    }

    private func big3Row(_ chart: NatalChart) -> some View {
        let sun = chart.planets.first { $0.id == "Sun" }
        let moon = chart.planets.first { $0.id == "Moon" }
        return HStack(spacing: 10) {
            if let sun { big3Cell(glyph: "☉", title: "태양", sign: sun.sign) }
            if let moon { big3Cell(glyph: "☽", title: "달", sign: moon.sign) }
            if let asc = chart.angles?.asc { big3Cell(glyph: "ASC", title: "상승궁", sign: asc.sign) }
        }
    }

    private func big3Cell(glyph: String, title: String, sign: String) -> some View {
        VStack(spacing: 4) {
            Text(glyph)
                .font(.system(size: glyph.count > 1 ? 14 : 22, weight: .semibold))
                .foregroundStyle(Color(hex: 0x8C6E3C))
                .frame(height: 26)
            Text(zodiacKo[sign] ?? sign)
                .font(DT.sans(12, .bold)).foregroundStyle(DT.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(title)
                .font(DT.sans(9)).foregroundStyle(DT.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Color(hex: 0xB8975A).opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: 0xB8975A).opacity(0.32), lineWidth: 0.7))
    }

    // MARK: 4대 축 (2×2 그리드)
    private func axisSection(_ a: NatalAngles) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "4대 축")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    axisCell("ASC", "상승점", a.asc)
                    axisCell("MC", "중천점", a.mc)
                    axisCell("DESC", "하강점", a.desc)
                    axisCell("IC", "천저점", a.ic)
                }
            }
        }
    }

    private func axisCell(_ code: String, _ ko: String, _ p: AnglePoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Text(code).font(DT.sans(11, .bold)).foregroundStyle(DT.accent)
                Text(ko).font(DT.sans(9)).foregroundStyle(DT.inkSoft)
            }
            HStack(spacing: 6) {
                Circle().fill(natalElementColor(p.sign)).frame(width: 6, height: 6)
                Text("\(zodiacKo[p.sign] ?? p.sign) \(String(format: "%.1f°", p.degreeInSign))")
                    .font(DT.sans(13, .semibold)).foregroundStyle(DT.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(DT.bg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: 행성 배치 (글리프 원 + 별자리 칩)
    private func planetSection(_ chart: NatalChart) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "행성 배치")
                ForEach(chart.planets, id: \.id) { p in planetRow(p) }
            }
        }
    }

    private func planetRow(_ p: PlanetPosition) -> some View {
        let col = natalElementColor(p.sign)
        return HStack(spacing: 11) {
            ZStack {
                Circle().fill(col.opacity(0.14)).frame(width: 36, height: 36)
                Text(planetGlyph[p.id] ?? "•").font(.system(size: 17)).foregroundStyle(col)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(planetKo[p.id] ?? p.id).font(DT.sans(13, .semibold)).foregroundStyle(DT.ink)
                HStack(spacing: 6) {
                    if let house = p.house {
                        Text("\(house)하우스").font(DT.sans(9)).foregroundStyle(DT.inkSoft)
                    }
                    if p.isRetrograde {
                        Text("℞ 역행").font(DT.sans(9, .semibold)).foregroundStyle(DT.accent)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(zodiacKo[p.sign] ?? p.sign)
                    .font(DT.sans(11, .semibold)).foregroundStyle(col)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(col.opacity(0.12), in: Capsule())
                Text(String(format: "%.1f°", p.degreeInSign)).font(DT.sans(10)).foregroundStyle(DT.inkSoft)
            }
        }
    }

    // MARK: 하우스 (2열 그리드)
    private func houseSection(_ chart: NatalChart) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "하우스 (홀사인)")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible())], spacing: 8) {
                    ForEach(chart.houses, id: \.number) { h in houseCell(h) }
                }
            }
        }
    }

    private func houseCell(_ h: NatalHouse) -> some View {
        HStack(spacing: 8) {
            Text("\(h.number)")
                .font(DT.sans(11, .bold)).foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(DT.night, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(zodiacKo[h.sign] ?? h.sign)
                    .font(DT.sans(12, .semibold)).foregroundStyle(natalElementColor(h.sign))
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text(String(format: "%.1f°", h.degreeInSign)).font(DT.sans(10)).foregroundStyle(DT.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(DT.bg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: 어스펙트 (글리프 + 색)
    private func aspectSection(_ chart: NatalChart) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "주요 어스펙트")
                ForEach(Array(chart.aspects.prefix(15).enumerated()), id: \.offset) { _, a in
                    let col = aspectColor(a.type)
                    HStack(spacing: 9) {
                        Text(aspectGlyph[a.type] ?? "•")
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(col)
                            .frame(width: 20)
                        Text("\(planetKo[a.planet1] ?? a.planet1) – \(planetKo[a.planet2] ?? a.planet2)")
                            .font(DT.sans(13)).foregroundStyle(DT.ink)
                        Spacer()
                        Text(aspectKo[a.type] ?? a.type)
                            .font(DT.sans(11, .semibold)).foregroundStyle(col)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(col.opacity(0.12), in: Capsule())
                        Text(String(format: "%.1f°", a.orb)).font(DT.sans(10)).foregroundStyle(DT.inkSoft)
                    }
                }
            }
        }
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
                    ziweiInstrument(chart)

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

                    if let profile = appState.profile {
                        AIInterpretationView(title: "달토끼 자미 해석") {
                            AIProxy.interpretZiwei(chart: chart, liunian: appState.ziweiLiunian, daxianList: appState.ziweiDaxian ?? [], gender: profile.gender, birthYear: profile.year)
                        }
                        AIContentPanel(title: "자미두수 세부 해석", sections: AIContentSections.ziwei) { id, tone in
                            AIProxy.content(id: id, tone: tone, gender: profile.gender, birthYear: profile.year,
                                            birthMonth: profile.month, birthDay: profile.day, birthHour: profile.hour, birthMinute: profile.minute)
                        }
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 12)
            } else {
                ContentUnavailableView("명반을 계산할 수 없어요", systemImage: "sparkles",
                                       description: Text("생년월일시 정보를 확인해 주세요."))
                    .padding(.top, 40)
            }
        }
        .background(DT.bg)
        .navigationTitle("자미두수")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 그래파이트 인스트루먼트 (출생차트 다이얼과 통일) — 명반 + 핵심 요약
    private func ziweiInstrument(_ chart: ZiweiChart) -> some View {
        let ming = chart.palaces.values.first { $0.name == "命宮" }
        let mingStars = ming.map { $0.stars.prefix(2).map { $0.name }.joined(separator: "·") } ?? ""
        return ZStack {
            RoundedRectangle(cornerRadius: DT.radius).fill(DT.card)
            VStack(spacing: 14) {
                HStack {
                    Text("紫微斗數 명반")
                        .font(DT.serif(16, .bold)).tracking(1).foregroundStyle(DT.ink)
                    Spacer()
                }
                // 명반 그리드 — 얇은 브라스 프레임
                ZiweiGridChart(chart: chart, daxian: appState.ziweiDaxian, palaceKo: palaceKo)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xB8975A).opacity(0.55), lineWidth: 1.2))
                HStack(spacing: 10) {
                    DarkStatChip(value: mingStars.isEmpty ? "—" : mingStars, label: "명궁 주성")
                    DarkStatChip(value: chart.wuXingJu.name, label: "오행국")
                    DarkStatChip(value: chart.shenGongZhi, label: "신궁")
                }
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: DT.radius))
        .overlay(RoundedRectangle(cornerRadius: DT.radius).stroke(Color(hex: 0xB8975A).opacity(0.30), lineWidth: 1))
    }
}
