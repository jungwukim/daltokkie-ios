// 사주 상세 — 웹 detailed/full-analysis 섹션 이관 (오행분포·지장간·합충형파해·공망·신살·세운)
// 데이터는 온디바이스 EngineAnalysis 공개 함수에서 직접 계산

import SwiftUI
import SajuKit

struct SajuAnalysisSections: View {
    enum Phase { case elements, relations, timeline }
    @EnvironmentObject var appState: AppState
    let r: FortuneTellerResult
    let pillars: SajuPillars
    let phase: Phase

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
        switch phase {
        case .elements:
            elementsCard
        case .relations:
            relationsPhase
        case .timeline:
            VStack(spacing: 16) {
                yearFortuneCard
                todayFortuneCard
                monthlyCard
                monthlyCalendarCard
            }
        }
    }

    // 공망 → 합충형파해 → 삼합 → 천간합충 → 지장간 → 신살 (웹 모바일 순서)
    private var relationsPhase: some View {
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
        return VStack(spacing: 16) {
            gongmangCard(gongmang)
            if !branchRels.isEmpty { relListCard("합충형파해", branchRels.map { ($0.type, $0.typeName, $0.branchesKorean, $0.pillars, $0.description) }) }
            if !multiRels.isEmpty { relListCard("삼합·반합·방합", multiRels.map { ($0.type, $0.typeName, $0.branchesKorean, $0.pillars, "\($0.description) · \($0.resultElement)") }) }
            if !stemRels.isEmpty { relListCard("천간합·충", stemRels.map { ($0.type, $0.typeName, $0.stemsKorean, $0.pillars, $0.description) }) }
            hiddenStemsCard(hidden)
            if !spirits.isEmpty || !specialSals.isEmpty { sinsalCard(spirits, specialSals) }
        }
    }

    private func relListCard(_ title: String, _ rows: [(String, String, [String], [String], String)]) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: title)
                ForEach(rows.indices, id: \.self) { i in
                    relRow(rows[i].0, rows[i].1, rows[i].2, rows[i].3, rows[i].4)
                }
            }
        }
    }

    // MARK: 오늘의 운세
    private var todayFortuneCard: some View {
        Group {
            if let bundle = appState.ensureDailyBundle() {
                let t = bundle.today
                CraftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "오늘의 운세")
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(t.overallScore)").font(DT.sans(28, .bold)).foregroundStyle(DT.accent)
                            Text("점 · \(t.overallGrade)").font(DT.sans(13)).foregroundStyle(DT.inkSoft)
                        }
                        ForEach(HomeConditions.from(cards: t.cards), id: \.title) { c in
                            HStack {
                                Text(c.title).font(DT.sans(12, .medium)).foregroundStyle(DT.ink).frame(width: 60, alignment: .leading)
                                StarRatingView(value: HomeConditions.stars(c.score), size: 9)
                                Spacer()
                                Text("\(c.score)").font(DT.sans(11)).foregroundStyle(DT.inkSoft)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: 운세 달력 (이번 달)
    private var monthlyCalendarCard: some View {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)
        let today = Calendar.current.component(.day, from: now)
        let days = DailyFortuneEngine.calculateMonthlyCalendar(year: year, month: month, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang, dayMasterHanja: r.dayMaster.hanja, birthYear: appState.profile?.year ?? year)
        var comp = DateComponents(); comp.year = year; comp.month = month; comp.day = 1
        let lead = (Calendar.current.dateComponents([.weekday], from: Calendar.current.date(from: comp) ?? now).weekday ?? 1) - 1
        func scoreColor(_ s: Int) -> Color {
            if s >= 70 { return Color(hex: 0x5A9E6F) }
            if s >= 50 { return Color(hex: 0xE0B450) }
            if s >= 35 { return DT.accent }
            return Color(hex: 0xB0A088)
        }
        return CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "\(year)년 \(month)월 운세 달력")
                let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach(["일","월","화","수","목","금","토"], id: \.self) { w in
                        Text(w).font(DT.sans(9)).foregroundStyle(DT.inkSoft)
                    }
                    ForEach(0..<lead, id: \.self) { _ in Color.clear.frame(height: 30) }
                    ForEach(days, id: \.day) { d in
                        VStack(spacing: 1) {
                            Text("\(d.day)").font(DT.sans(10, d.day == today ? .bold : .regular))
                                .foregroundStyle(d.day == today ? DT.accent : DT.ink)
                            Circle().fill(scoreColor(d.overallScore)).frame(width: 5, height: 5)
                        }
                        .frame(height: 30)
                        .frame(maxWidth: .infinity)
                        .background(d.day == today ? DT.accentSoft.opacity(0.5) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    // MARK: 월운(올해 12개월)
    private var monthlyCard: some View {
        let year = Calendar.current.component(.year, from: Date())
        let months = EngineAnalysis.calculateMonthlyPillars(targetYear: year, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang, dayMasterHanja: r.dayMaster.hanja)
        let curMonth = Calendar.current.component(.month, from: Date())
        return CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "월운(月運) · \(year)년")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(months, id: \.month) { mp in
                            VStack(spacing: 3) {
                                Text("\(mp.month)월").font(DT.sans(10, .semibold))
                                    .foregroundStyle(mp.month == curMonth ? DT.accent : DT.inkSoft)
                                Text("\(mp.stemHanja)\(mp.branchHanja)")
                                    .font(DT.serif(18, .bold)).foregroundStyle(elColor(mp.stemElement))
                                Text(mp.tenGodStem).font(DT.sans(10, .medium)).foregroundStyle(DT.ink).lineLimit(1)
                                Text(mp.twelveStage).font(DT.sans(9)).foregroundStyle(DT.inkSoft)
                            }
                            .frame(width: 56)
                            .padding(.vertical, 8)
                            .background(mp.month == curMonth ? DT.accentSoft.opacity(0.5) : DT.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
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
