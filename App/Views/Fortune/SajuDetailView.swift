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
                    // 히어로: 일간 프로필
                    CraftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(r.displayHanja)
                                .font(DT.serif(19, .bold))
                                .foregroundStyle(DT.ink)
                            if let p = r.dayMasterProfile {
                                Text("\(p.name) · \(p.image)")
                                    .font(DT.sans(13, .semibold))
                                    .foregroundStyle(DT.accent)
                                Text(p.traits)
                                    .font(DT.sans(13))
                                    .foregroundStyle(DT.inkSoft)
                                    .lineSpacing(4)
                            }
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "사주팔자")
                            PillarGrid(result: r)
                            DetailRow(label: "오행", value: elementsLine(r))
                            DetailRow(label: "운의 흐름", value: r.energyFlow)
                            DetailRow(label: "띠", value: r.animal)
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "십성 · 12운성")
                            tenGodRow("년주", tenGods.year.stem, tenGods.year.branch, stages.year.stage)
                            tenGodRow("월주", tenGods.month.stem, tenGods.month.branch, stages.month.stage)
                            tenGodRow("일주", tenGods.day.stem, tenGods.day.branch, stages.day.stage)
                            if let hourGods = tenGods.hour, let hourStage = stages.hour {
                                tenGodRow("시주", hourGods.stem, hourGods.branch, hourStage.stage)
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

                    // 웹 상세 이관: 오행분포·지장간·합충형파해·공망·신살
                    SajuAnalysisSections(r: r, pillars: pillars)

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

                    AIInterpretationView(title: "달토끼 AI 심층 해석") {
                        AIProxy.interpretSaju(result: r, gender: profile.gender, birthYear: profile.year)
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

    private func elementsLine(_ r: FortuneTellerResult) -> String {
        let ko = ["Wood": "목", "Fire": "화", "Earth": "토", "Metal": "금", "Water": "수"]
        return ["Wood", "Fire", "Earth", "Metal", "Water"]
            .map { "\(ko[$0]!) \(r.elements.counts[$0] ?? 0)" }
            .joined(separator: " · ")
    }

    private func tenGodRow(_ title: String, _ stemGod: String, _ branchGod: String, _ stage: String) -> some View {
        HStack {
            Text(title)
                .font(DT.sans(12))
                .foregroundStyle(DT.inkSoft)
                .frame(width: 44, alignment: .leading)
            Text("천간 \(stemGod)")
                .font(DT.sans(12, .medium))
                .foregroundStyle(DT.ink)
            Text("지지 \(branchGod)")
                .font(DT.sans(12, .medium))
                .foregroundStyle(DT.ink)
            Spacer()
            Text(stage)
                .font(DT.sans(12, .bold))
                .foregroundStyle(DT.accent)
        }
    }

    private func stemHanja(_ korean: String) -> String {
        SajuTables.stems.first { $0.korean == korean }?.hanja ?? korean
    }
    private func branchHanja(_ korean: String) -> String {
        SajuTables.branches.first { $0.korean == korean }?.hanja ?? korean
    }
}
