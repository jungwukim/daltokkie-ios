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
                let daeun = HoshinDaeUn.calculateDaeUn(r.raw)

                VStack(spacing: 16) {
                    // 밤하늘 히어로: 일간 정체성 + 사주팔자 + 핵심 요약
                    sajuHero(r)

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
                            SectionTitle(text: "십성(十神) 배치표")
                            tenGodRow("년주", tenGods.year.stem, tenGods.year.branch)
                            tenGodRow("월주", tenGods.month.stem, tenGods.month.branch)
                            tenGodRow("일주", tenGods.day.stem, tenGods.day.branch)
                            if let h = tenGods.hour { tenGodRow("시주", h.stem, h.branch) }
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "12운성")
                            stageRow("년주", stages.year.stage, stages.year.period)
                            stageRow("월주", stages.month.stage, stages.month.period)
                            stageRow("일주", stages.day.stage, stages.day.period)
                            if let h = stages.hour { stageRow("시주", h.stage, h.period) }
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

                    AIInterpretationView(title: "달토끼 AI 심층 해석") {
                        AIProxy.interpretSaju(result: r, gender: profile.gender, birthYear: profile.year)
                    }

                    AIContentPanel(title: "AI 콘텐츠", sections: AIContentSections.saju) { id, tone in
                        AIProxy.content(id: id, tone: tone, gender: profile.gender, birthYear: profile.year,
                                        birthMonth: profile.month, birthDay: profile.day, birthHour: profile.hour, birthMinute: profile.minute,
                                        sajuResult: r)
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.vertical, 12)
            } else {
                Text("사주를 계산할 수 없어요")
                    .font(DT.sans(14))
                    .foregroundStyle(DT.inkSoft)
                    .padding(.top, 60)
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
            RoundedRectangle(cornerRadius: DT.radius)
                .fill(LinearGradient(colors: [Color(hex: 0x303663), Color(hex: 0x1C1F38)],
                                     startPoint: .top, endPoint: .bottom))
            StarField()
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(r.displayHanja)
                            .font(DT.serif(20, .bold)).foregroundStyle(.white)
                        Spacer()
                        Text("\(animalKo(r.animal)) 띠")
                            .font(DT.sans(12, .semibold)).foregroundStyle(Color(hex: 0xE8C77A))
                    }
                    if let p = r.dayMasterProfile {
                        Text("\(p.name) · \(p.image)")
                            .font(DT.sans(13, .semibold)).foregroundStyle(Color(hex: 0xE8C77A))
                        Text(p.traits)
                            .font(DT.sans(12)).foregroundStyle(.white.opacity(0.72)).lineSpacing(4)
                    }
                }

                PillarGrid(result: r, onDark: true)

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
        .overlay(RoundedRectangle(cornerRadius: DT.radius).stroke(.white.opacity(0.10), lineWidth: 1))
    }

    private func tenGodRow(_ title: String, _ stemGod: String, _ branchGod: String) -> some View {
        HStack {
            Text(title)
                .font(DT.sans(12))
                .foregroundStyle(DT.inkSoft)
                .frame(width: 44, alignment: .leading)
            Text("천간 \(stemGod)")
                .font(DT.sans(12, .medium))
                .foregroundStyle(DT.ink)
            Spacer()
            Text("지지 \(branchGod)")
                .font(DT.sans(12, .medium))
                .foregroundStyle(DT.ink)
        }
    }

    private func stageRow(_ title: String, _ stage: String, _ period: String) -> some View {
        HStack {
            Text(title)
                .font(DT.sans(12))
                .foregroundStyle(DT.inkSoft)
                .frame(width: 44, alignment: .leading)
            Text(stage)
                .font(DT.sans(13, .bold))
                .foregroundStyle(DT.accent)
            Spacer()
            Text(period)
                .font(DT.sans(11))
                .foregroundStyle(DT.inkSoft)
        }
    }

    private func stemHanja(_ korean: String) -> String {
        SajuTables.stems.first { $0.korean == korean }?.hanja ?? korean
    }
    private func branchHanja(_ korean: String) -> String {
        SajuTables.branches.first { $0.korean == korean }?.hanja ?? korean
    }
}
