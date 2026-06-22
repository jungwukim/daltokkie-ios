// 사주 상세 — 웹 detailed/full-analysis 섹션 이관 (오행분포·지장간·합충형파해·공망·신살·세운)
// 데이터는 온디바이스 EngineAnalysis 공개 함수에서 직접 계산

import SwiftUI
import SajuKit

struct SajuAnalysisSections: View {
    let r: FortuneTellerResult
    let pillars: SajuPillars

    private static let elementKo = ["Wood": "목", "Fire": "화", "Earth": "토", "Metal": "금", "Water": "수"]
    private func elColor(_ e: String) -> Color {
        switch e {
        case "Wood", "목": return Color(hex: 0x4E9A51)
        case "Fire", "화": return Color(hex: 0xD1495B)
        case "Earth", "토": return Color(hex: 0xC79A3B)
        case "Metal", "금": return Color(hex: 0x9AA0A6)
        case "Water", "수": return Color(hex: 0x3F6CB0)
        default: return DT.inkSoft
        }
    }
    private func relColor(_ type: String) -> Color {
        if type.contains("합") { return Color(hex: 0x059669) }
        if type.contains("충") { return Color(hex: 0xDC2626) }
        if type.contains("형") { return Color(hex: 0xEA580C) }
        if type.contains("파") { return Color(hex: 0x7C3AED) }
        if type.contains("해") { return Color(hex: 0xE11D48) }
        return Color(hex: 0x64748B)
    }
    private func salColor(_ type: String) -> Color {
        switch type {
        case "길신": return Color(hex: 0x059669)
        case "흉살": return Color(hex: 0xDC2626)
        default: return Color(hex: 0x8B7E6A)
        }
    }

    var body: some View {
        let hidden = EngineAnalysis.calculateHiddenStems(pillars: pillars, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang)
        let branchRels = EngineAnalysis.calculateBranchRelations(pillars: pillars)
        let multiRels = EngineAnalysis.calculateMultiRelations(pillars: pillars)
        let stemRels = EngineAnalysis.calculateStemRelations(pillars: pillars)
        let dayBranchHanja = r.pillars.day.branch.hanja
        let gongmang = EngineAnalysis.calculateGongMang(dayStemHanja: r.dayMaster.hanja, dayBranchHanja: dayBranchHanja, pillars: pillars)
        let spirits = EngineAnalysis.calculateTwelveSpirits(yearBranchHanja: r.pillars.year.branch.hanja, pillars: pillars)
        let stems = [r.pillars.year.stem.hanja, r.pillars.month.stem.hanja, r.pillars.day.stem.hanja, r.pillars.hour?.stem.hanja].compactMap { $0 }
        let branchArr = [r.pillars.year.branch.hanja, r.pillars.month.branch.hanja, r.pillars.day.branch.hanja, r.pillars.hour?.branch.hanja].compactMap { $0 }
        let specialSals = EngineAnalysis.calculateSpecialSals(stems: stems, branches: branchArr, dayPillar: "\(r.pillars.day.stem.hanja)\(dayBranchHanja)")

        VStack(spacing: 16) {
            elementsCard
            hiddenStemsCard(hidden)
            if !branchRels.isEmpty || !stemRels.isEmpty || !multiRels.isEmpty {
                relationsCard(branchRels, multiRels, stemRels)
            }
            gongmangCard(gongmang)
            if !spirits.isEmpty || !specialSals.isEmpty {
                sinsalCard(spirits, specialSals)
            }
            yearFortuneCard
        }
    }

    // MARK: 세운(올해)
    private var yearFortuneCard: some View {
        let year = Calendar.current.component(.year, from: Date())
        let yf = EngineAnalysis.calculateYearFortune(targetYear: year, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang, dayMasterHanja: r.dayMaster.hanja)
        return CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "세운(歲運) · \(year)년")
                HStack(spacing: 10) {
                    Text("\(yf.stemHanja)\(yf.branchHanja)")
                        .font(DT.serif(26, .bold)).foregroundStyle(DT.ink)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(yf.stemKorean)\(yf.branchKorean) · \(yf.branchAnimal)띠 해")
                            .font(DT.sans(12, .semibold)).foregroundStyle(DT.accent)
                        Text("천간 \(yf.tenGodStem) · 지지 \(yf.tenGodBranch) · \(yf.twelveStage)")
                            .font(DT.sans(11)).foregroundStyle(DT.inkSoft)
                    }
                }
            }
        }
    }

    // MARK: 오행 분포 (가로 막대)
    private var elementsCard: some View {
        let order = ["Wood", "Fire", "Earth", "Metal", "Water"]
        let counts = order.map { r.elements.counts[$0] ?? 0 }
        let maxC = max(counts.max() ?? 1, 1)
        return CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "오행 분포")
                ForEach(order.indices, id: \.self) { i in
                    let c = counts[i]
                    HStack(spacing: 8) {
                        Text(Self.elementKo[order[i]]!)
                            .font(DT.sans(12, .bold)).foregroundStyle(elColor(order[i]))
                            .frame(width: 20)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(DT.line.opacity(0.4)).frame(height: 10)
                                Capsule().fill(elColor(order[i]))
                                    .frame(width: max(6, geo.size.width * CGFloat(c) / CGFloat(maxC)), height: 10)
                            }
                        }.frame(height: 10)
                        Text("\(c)").font(DT.sans(12, .semibold)).foregroundStyle(DT.inkSoft).frame(width: 16)
                    }
                }
                HStack(spacing: 6) {
                    Text("강 \(Self.elementKo[r.elements.dominant] ?? r.elements.dominant)")
                        .font(DT.sans(11, .semibold)).foregroundStyle(elColor(r.elements.dominant))
                    Text("·").foregroundStyle(DT.inkSoft)
                    Text("약 \(Self.elementKo[r.elements.weakest] ?? r.elements.weakest)")
                        .font(DT.sans(11, .semibold)).foregroundStyle(DT.inkSoft)
                }
            }
        }
    }

    // MARK: 지장간
    private func hiddenStemsCard(_ h: HiddenStemsChart) -> some View {
        let cols: [(String, [HiddenStem])] = [("년주", h.year), ("월주", h.month), ("일주", h.day), ("시주", h.hour ?? [])]
        return CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "지장간(地藏干)")
                ForEach(cols.indices, id: \.self) { i in
                    let (label, list) = cols[i]
                    if !list.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text(label).font(DT.sans(11, .semibold)).foregroundStyle(DT.inkSoft).frame(width: 36, alignment: .leading)
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(list.indices, id: \.self) { j in
                                    let s = list[j]
                                    HStack(spacing: 6) {
                                        Text(s.stem).font(DT.serif(14, .bold)).foregroundStyle(elColor(s.element))
                                        Text(s.type).font(DT.sans(9)).foregroundStyle(DT.inkSoft)
                                        if let tg = s.tenGod { Text(tg).font(DT.sans(10, .medium)).foregroundStyle(DT.accent) }
                                        Spacer(minLength: 4)
                                        Text("\(s.ratio)%").font(DT.sans(10)).foregroundStyle(DT.inkSoft)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: 합충형파해 + 삼합 + 천간합충
    private func relationsCard(_ br: [BranchRelation], _ mr: [MultiRelation], _ sr: [StemRelation]) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "합충형파해 · 천간 관계")
                ForEach(br.indices, id: \.self) { i in relRow(br[i].type, br[i].typeName, br[i].branchesKorean, br[i].pillars, br[i].description) }
                ForEach(mr.indices, id: \.self) { i in relRow(mr[i].type, mr[i].typeName, mr[i].branchesKorean, mr[i].pillars, "\(mr[i].description) · \(mr[i].resultElement)") }
                ForEach(sr.indices, id: \.self) { i in relRow(sr[i].type, sr[i].typeName, sr[i].stemsKorean, sr[i].pillars, sr[i].description) }
            }
        }
    }
    private func relRow(_ type: String, _ name: String, _ items: [String], _ pillars: [String], _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(type).font(DT.sans(10, .bold)).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(relColor(type)).clipShape(Capsule())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(name) · \(pillars.joined(separator: "↔"))").font(DT.sans(12, .semibold)).foregroundStyle(DT.ink)
                Text(desc).font(DT.sans(11)).foregroundStyle(DT.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: 공망
    private func gongmangCard(_ g: GongMangResult) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "공망(空亡)")
                HStack(spacing: 6) {
                    ForEach(g.voidBranchesKorean, id: \.self) { b in
                        Text(b).font(DT.sans(12, .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(hex: 0x64748B)).clipShape(Capsule())
                    }
                    if !g.affectedPillars.isEmpty {
                        Text("→ \(g.affectedPillars.joined(separator: ", "))").font(DT.sans(11)).foregroundStyle(DT.inkSoft)
                    }
                }
                Text(g.description).font(DT.sans(12)).foregroundStyle(DT.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: 신살 (12신살 + 특수살)
    private func sinsalCard(_ spirits: [TwelveSpiritEntry], _ special: [SpecialSalEntry]) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "신살(神殺)")
                ForEach(spirits.indices, id: \.self) { i in
                    let s = spirits[i]
                    salRow(s.spiritHangul, s.spiritHanja, s.spiritType, "\(s.pillar) · \(s.branchKorean)", s.description)
                }
                ForEach(special.indices, id: \.self) { i in
                    let s = special[i]
                    salRow(s.name, s.hanja, s.type, "", s.description)
                }
            }
        }
    }
    private func salRow(_ name: String, _ hanja: String, _ type: String, _ loc: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(type).font(DT.sans(10, .bold)).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(salColor(type)).clipShape(Capsule())
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(name)(\(hanja))").font(DT.sans(12, .semibold)).foregroundStyle(DT.ink)
                    if !loc.isEmpty { Text(loc).font(DT.sans(10)).foregroundStyle(DT.inkSoft) }
                }
                if !desc.isEmpty {
                    Text(desc).font(DT.sans(11)).foregroundStyle(DT.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
