// 사주팔자 상세 — 온디바이스 전체 분석 + AI 심층 해석
// (웹 mobile-saju-page.tsx 대응 — 핵심 섹션)

import SwiftUI
import SajuKit

struct SajuDetailView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            if let r = appState.ensureSaju(), let profile = appState.profile {
                let pillars = SajuPillars(year: r.pillars.year, month: r.pillars.month, day: r.pillars.day, hour: r.pillars.hour)
                let strength = EngineAnalysis.buildStrengthFromLibrary(raw: r.raw, pillars: pillars)
                let yongsin = EngineAnalysis.buildYongsinFromLibrary(
                    raw: r.raw, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang,
                    isStrong: strength.isStrong, strengthLevel: r.raw.dayMasterStrength?.level
                )
                let tenGods = EngineAnalysis.calculateTenGods(dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang, pillars: pillars)
                let stages = EngineAnalysis.calculateTwelveStages(dayMasterHanja: r.dayMaster.hanja, pillars: pillars)
                let hidden = EngineAnalysis.calculateHiddenStems(pillars: pillars, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang)
                let spirits = EngineAnalysis.calculateTwelveSpirits(yearBranchHanja: r.pillars.year.branch.hanja, pillars: pillars)
                let daeun = HoshinDaeUn.calculateDaeUn(r.raw)
                let chartColumns = makeChartColumns(r: r, tenGods: tenGods, stages: stages, hidden: hidden, spirits: spirits)

                VStack(spacing: 16) {
                    // 밤하늘 히어로: 일간 정체성 + 사주팔자 + 핵심 요약
                    sajuHero(r)

                    // 명식표(만세력) — 천간·십성·지지·십성·지장간·12운성·12신살 한눈에
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "명식표(命式表)")
                            SajuChartTable(columns: chartColumns)
                        }
                    }

                    // 오행 분포
                    SajuAnalysisSections(r: r, pillars: pillars, phase: .elements)

                    if let gyeokguk = r.raw.gyeokGuk {
                        CraftCard {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionTitle(text: "격국(格局)")
                                Text("\(gyeokguk.name) (\(gyeokguk.hanja))")
                                    .font(DT.serif(16, .bold))
                                    .foregroundStyle(DT.ink)
                                Text(gyeokguk.description)
                                    .font(DT.sans(13))
                                    .foregroundStyle(DT.inkSoft)
                                    .lineSpacing(4)
                            }
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "신강 · 신약")
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(strength.label)
                                    .font(DT.serif(18, .bold))
                                    .foregroundStyle(DT.accent)
                                Text("\(strength.score)점")
                                    .font(DT.sans(13))
                                    .foregroundStyle(DT.inkSoft)
                            }
                            DetailRow(label: "득령", value: strength.details.deukryeong.description)
                            DetailRow(label: "득지", value: strength.details.deukji.description)
                            DetailRow(label: "득세", value: strength.details.deukse.description)
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "용신(用神)")
                            HStack(spacing: 8) {
                                Text(yongsin.yongsin.elementKo)
                                    .font(DT.serif(18, .bold))
                                    .foregroundStyle(DT.accent)
                                Text("희신 \(yongsin.heesin.elementKo)")
                                    .font(DT.sans(12))
                                    .foregroundStyle(DT.inkSoft)
                            }
                            Text(yongsin.yongsin.description)
                                .font(DT.sans(13))
                                .foregroundStyle(DT.ink)
                                .lineSpacing(4)
                        }
                    }

                    // 공망·합충형파해·삼합·천간합충·지장간·신살
                    SajuAnalysisSections(r: r, pillars: pillars, phase: .relations)

                    if !daeun.isEmpty {
                        CraftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SectionTitle(text: "대운(大運)")
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(daeun, id: \.startAge) { period in
                                            VStack(spacing: 4) {
                                                Text("\(period.startAge)세")
                                                    .font(DT.sans(10))
                                                    .foregroundStyle(DT.inkSoft)
                                                Text("\(stemHanja(period.stem))\(branchHanja(period.branch))")
                                                    .font(DT.serif(18, .bold))
                                                    .foregroundStyle(DT.ink)
                                                Text("\(period.stemElement)\(period.branchElement)")
                                                    .font(DT.sans(10))
                                                    .foregroundStyle(DT.inkSoft)
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

                    // 세운·오늘의 운세·월운·운세 달력
                    SajuAnalysisSections(r: r, pillars: pillars, phase: .timeline)

                    AIInterpretationView(title: "달토끼 심층 해석") {
                        AIProxy.interpretSaju(result: r, gender: profile.gender, birthYear: profile.year, region: profile.region, timeline: appState.sajuTimelineJSON())
                    }

                    AIContentPanel(title: "세부 해석", sections: AIContentSections.saju) { id, tone in
                        AIProxy.content(id: id, tone: tone, gender: profile.gender, birthYear: profile.year,
                                        birthMonth: profile.month, birthDay: profile.day, birthHour: profile.hour, birthMinute: profile.minute,
                                        sajuResult: r, region: profile.region, timeline: appState.sajuTimelineJSON())
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 12)
            } else {
                ContentUnavailableView("사주를 계산할 수 없어요", systemImage: "sparkles",
                                       description: Text("생년월일 정보를 확인해 주세요."))
                    .padding(.top, 40)
            }
        }
        .background(DT.bg)
        .navigationTitle("사주팔자")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func animalKo(_ en: String) -> String {
        ["Rat": "쥐", "Ox": "소", "Tiger": "호랑이", "Rabbit": "토끼", "Dragon": "용", "Snake": "뱀",
         "Horse": "말", "Goat": "양", "Monkey": "원숭이", "Rooster": "닭", "Dog": "개", "Pig": "돼지"][en] ?? en
    }

    // MARK: 밤하늘 히어로
    private func sajuHero(_ r: FortuneTellerResult) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: DT.radius).fill(DT.card)
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(r.displayHanja)
                            .font(DT.serif(20, .bold)).foregroundStyle(DT.ink)
                        Spacer()
                        Text("\(animalKo(r.animal)) 띠")
                            .font(DT.sans(12, .semibold)).foregroundStyle(Color(hex: 0x8C6E3C))
                    }
                    if let p = r.dayMasterProfile {
                        Text("\(p.name) · \(p.image)")
                            .font(DT.sans(13, .semibold)).foregroundStyle(Color(hex: 0x8C6E3C))
                        Text(p.traits)
                            .font(DT.sans(12)).foregroundStyle(DT.inkSoft).lineSpacing(4)
                    }
                }

                PillarGrid(result: r, instrument: true)

                HStack(spacing: 10) {
                    DarkStatChip(value: "\(r.dayMaster.korean)(\(r.dayMaster.hanja))",
                                 label: "일간(日干)", tint: sajuElementColor(r.dayMaster.element))
                    DarkStatChip(value: sajuElementKo(r.elements.dominant),
                                 label: "강한 오행", tint: sajuElementColor(r.elements.dominant))
                    DarkStatChip(value: sajuElementKo(r.elements.weakest),
                                 label: "약한 오행", tint: sajuElementColor(r.elements.weakest))
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: DT.radius))
        .overlay(RoundedRectangle(cornerRadius: DT.radius).stroke(Color(hex: 0xB8975A).opacity(0.30), lineWidth: 1))
    }

    /// 명식표 컬럼 조립 (시 → 일 → 월 → 년 순)
    private func makeChartColumns(
        r: FortuneTellerResult,
        tenGods: TenGodChart, stages: TwelveStageChart,
        hidden: HiddenStemsChart, spirits: [TwelveSpiritEntry]
    ) -> [SajuColumn] {
        func sinsal(_ key: String) -> String { spirits.first { $0.pillar == key }?.spiritHangul ?? "—" }
        func hid(_ list: [HiddenStem]) -> String { list.isEmpty ? "—" : list.map { $0.stem }.joined() }
        return [
            SajuColumn(header: "생시", stem: r.pillars.hour?.stem, branch: r.pillars.hour?.branch,
                       tenGodStem: tenGods.hour?.stem ?? "—", tenGodBranch: tenGods.hour?.branch ?? "—",
                       hidden: hid(hidden.hour ?? []), stage: stages.hour?.stage ?? "—", sinsal: sinsal("시주")),
            SajuColumn(header: "생일", stem: r.pillars.day.stem, branch: r.pillars.day.branch,
                       tenGodStem: tenGods.day.stem, tenGodBranch: tenGods.day.branch,
                       hidden: hid(hidden.day), stage: stages.day.stage, sinsal: sinsal("일주"), isDayMaster: true),
            SajuColumn(header: "생월", stem: r.pillars.month.stem, branch: r.pillars.month.branch,
                       tenGodStem: tenGods.month.stem, tenGodBranch: tenGods.month.branch,
                       hidden: hid(hidden.month), stage: stages.month.stage, sinsal: sinsal("월주")),
            SajuColumn(header: "생년", stem: r.pillars.year.stem, branch: r.pillars.year.branch,
                       tenGodStem: tenGods.year.stem, tenGodBranch: tenGods.year.branch,
                       hidden: hid(hidden.year), stage: stages.year.stage, sinsal: sinsal("년주")),
        ]
    }

    private func stemHanja(_ korean: String) -> String {
        SajuTables.stems.first { $0.korean == korean }?.hanja ?? korean
    }
    private func branchHanja(_ korean: String) -> String {
        SajuTables.branches.first { $0.korean == korean }?.hanja ?? korean
    }
}

// MARK: - 명식표(만세력) — 4기둥 통합표

struct SajuColumn: Identifiable {
    let id = UUID()
    let header: String          // 생시/생일/생월/생년
    let stem: UIStem?
    let branch: UIBranch?
    let tenGodStem: String
    let tenGodBranch: String
    let hidden: String          // 지장간(한자 연결)
    let stage: String           // 12운성
    let sinsal: String          // 12신살
    var isDayMaster: Bool = false
}

/// 천간·십성·지지·십성·지장간·12운성·12신살을 시·일·월·년 4열로 정리한 만세력 표
struct SajuChartTable: View {
    let columns: [SajuColumn]
    private let labelW: CGFloat = 48

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            divider
            glyphRow("천간") { $0.stem.map { ($0.korean, $0.hanja, $0.element, $0.yin_yang) } }
            divider
            textRow("십성", \.tenGodStem, accent: false, small: true)
            divider
            glyphRow("지지") { $0.branch.map { ($0.korean, $0.hanja, $0.element, $0.yin_yang) } }
            divider
            textRow("십성", \.tenGodBranch, accent: false, small: true)
            divider
            textRow("지장간", \.hidden, accent: false)
            divider
            textRow("12운성", \.stage, accent: true)
            divider
            textRow("12신살", \.sinsal, accent: false)
        }
    }

    private var divider: some View { Rectangle().fill(DT.line).frame(height: 1) }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: labelW)
            ForEach(columns) { c in
                Text(c.header)
                    .font(DT.sans(11, .semibold))
                    .foregroundStyle(c.isDayMaster ? DT.accent : DT.inkSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(c.isDayMaster ? DT.accent.opacity(0.07) : .clear)
            }
        }
    }

    private func glyphRow(_ label: String,
                          _ pick: @escaping (SajuColumn) -> (String, String, String, String)?) -> some View {
        HStack(spacing: 0) {
            rowLabel(label)
            ForEach(columns) { c in
                cell(c) {
                    if let (ko, hj, el, yy) = pick(c) {
                        VStack(spacing: 1) {
                            HStack(alignment: .firstTextBaseline, spacing: 1) {
                                Text(ko).font(DT.serif(21, .bold))
                                Text(hj).font(DT.serif(13, .semibold))
                            }
                            .foregroundStyle(sajuElementColor(el))
                            Text(elTag(el, yy))
                                .font(DT.sans(9, .semibold))
                                .foregroundStyle(sajuElementColor(el).opacity(0.9))
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("?").font(DT.serif(21, .bold)).foregroundStyle(DT.inkSoft).padding(.vertical, 8)
                    }
                }
            }
        }
    }

    private func textRow(_ label: String, _ kp: KeyPath<SajuColumn, String>,
                         accent: Bool, small: Bool = false) -> some View {
        HStack(spacing: 0) {
            rowLabel(label)
            ForEach(columns) { c in
                let v = c[keyPath: kp]
                cell(c) {
                    Text(v)
                        .font(DT.sans(small ? 11 : 12, .medium))
                        .foregroundStyle(v == "—" ? DT.inkSoft.opacity(0.5) : (accent ? DT.accent : DT.ink))
                        .lineLimit(1).minimumScaleFactor(0.65)
                        .padding(.vertical, 7).padding(.horizontal, 2)
                }
            }
        }
    }

    private func rowLabel(_ t: String) -> some View {
        Text(t).font(DT.sans(10, .semibold)).foregroundStyle(DT.inkSoft)
            .frame(width: labelW, alignment: .leading)
    }

    private func cell<V: View>(_ c: SajuColumn, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .background(c.isDayMaster ? DT.accent.opacity(0.07) : .clear)
    }

    private func elTag(_ element: String, _ yinYang: String) -> String {
        (yinYang == "Yang" ? "+" : "−") + sajuElementKo(element)
    }
}
