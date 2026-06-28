// 사주 상세 — 웹 detailed/full-analysis 섹션 이관 (오행분포·지장간·합충형파해·공망·신살·세운)
// 데이터는 온디바이스 EngineAnalysis 공개 함수에서 직접 계산

import SwiftUI
import SajuKit
import LunarKit

struct SajuAnalysisSections: View {
    enum Phase { case elements, relations, timeline }
    @EnvironmentObject var appState: AppState
    let r: FortuneTellerResult
    let pillars: SajuPillars
    let phase: Phase

    private static let elementKo = ["Wood": "목", "Fire": "화", "Earth": "토", "Metal": "금", "Water": "수"]
    private func elColor(_ e: String) -> Color {
        switch e {
        case "Wood", "목": return dtDyn(0x4E9A51, 0x6FBF73)
        case "Fire", "화": return dtDyn(0xD1495B, 0xE5757F)
        case "Earth", "토": return dtDyn(0xC79A3B, 0xDDBA62)
        case "Metal", "금": return dtDyn(0x9AA0A6, 0xBCC1C7)
        case "Water", "수": return dtDyn(0x3F6CB0, 0x6E97D2)
        default: return DT.inkSoft
        }
    }
    private func relColor(_ type: String) -> Color {
        if type.contains("합") { return dtDyn(0x059669, 0x34BD8E) }
        if type.contains("충") { return dtDyn(0xDC2626, 0xF06A6A) }
        if type.contains("형") { return dtDyn(0xEA580C, 0xF0884C) }
        if type.contains("파") { return dtDyn(0x7C3AED, 0xA77CF0) }
        if type.contains("해") { return dtDyn(0xE11D48, 0xF06080) }
        return dtDyn(0x64748B, 0x93A0B2)
    }
    private func salColor(_ type: String) -> Color {
        switch type {
        case "길신": return dtDyn(0x059669, 0x34BD8E)
        case "흉살": return dtDyn(0xDC2626, 0xF06A6A)
        default: return dtDyn(0x8B7E6A, 0xA99C88)
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

    // MARK: 운세 달력 (이번 달) — 간지·십성 + 날짜 탭 상세
    private var monthlyCalendarCard: some View {
        let now = Date()
        let year = Calendar.current.component(.year, from: now)
        let month = Calendar.current.component(.month, from: now)
        let today = Calendar.current.component(.day, from: now)
        let days = DailyFortuneEngine.calculateMonthlyCalendar(year: year, month: month, dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang, dayMasterHanja: r.dayMaster.hanja, birthYear: appState.profile?.year ?? year)
        var comp = DateComponents(); comp.year = year; comp.month = month; comp.day = 1
        let lead = (Calendar.current.dateComponents([.weekday], from: Calendar.current.date(from: comp) ?? now).weekday ?? 1) - 1
        return MonthlyFortuneCalendar(days: days, year: year, month: month, today: today, lead: lead)
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

    // MARK: 신살과 길성 — 기둥별(시·일·월·년) 표 + 상단 요약
    private func sinsalCard(_ spirits: [TwelveSpiritEntry], _ special: [SpecialSalEntry]) -> some View {
        let order = ["시주", "일주", "월주", "년주"]
        let headers = ["생시", "생일", "생월", "생년"]
        let idxOf = ["년주": 0, "월주": 1, "일주": 2, "시주": 3]   // pillarIndices: [년,월,일,시]
        func sals(_ key: String) -> [(name: String, type: String)] {
            var out: [(String, String)] = special
                .filter { $0.pillarIndices.contains(idxOf[key] ?? -1) }
                .map { ($0.name, $0.type) }
            out += spirits.filter { $0.pillar == key }.map { ($0.spiritHangul, $0.spiritType) }
            return out
        }
        // 요약 줄 — 전체 고유 신살·길성
        var seen = Set<String>(); var summary: [String] = []
        for key in order { for s in sals(key) where !seen.contains(s.name) { seen.insert(s.name); summary.append(s.name) } }

        return CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "신살과 길성(神殺·吉星)")
                if !summary.isEmpty {
                    Text(summary.joined(separator: ", "))
                        .font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                        .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
                }
                // 기둥별 표
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Color.clear.frame(width: 40)
                        ForEach(headers.indices, id: \.self) { i in
                            Text(headers[i]).font(DT.sans(11, .semibold)).foregroundStyle(DT.inkSoft)
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                        }
                    }
                    Rectangle().fill(DT.line).frame(height: 1)
                    HStack(spacing: 0) {
                        Text("신살\n길성").font(DT.sans(10, .semibold)).foregroundStyle(DT.inkSoft)
                            .frame(width: 40, alignment: .leading)
                        ForEach(order.indices, id: \.self) { i in
                            let list = sals(order[i])
                            VStack(spacing: 4) {
                                if list.isEmpty {
                                    Text("×").font(DT.sans(13)).foregroundStyle(DT.inkSoft.opacity(0.5))
                                } else {
                                    ForEach(list.indices, id: \.self) { j in
                                        Text(list[j].name)
                                            .font(DT.sans(11, .medium))
                                            .foregroundStyle(salColor(list[j].type))
                                            .lineLimit(1).minimumScaleFactor(0.7)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 운세 달력 (간지·십성 표시 + 날짜 탭 → 그날의 기운 상세)

struct MonthlyFortuneCalendar: View {
    let days: [MonthlyCalendarDay]
    let year: Int
    let month: Int
    let today: Int
    let lead: Int
    var showHeader: Bool = true
    @State private var selected: Int?
    @State private var showFull = false

    var body: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 10) {
                if showHeader {
                    HStack {
                        SectionTitle(text: "\(year)년 \(month)월 운세 달력")
                        Spacer()
                        Button { showFull = true } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(DT.accent)
                        }
                    }
                }
                // 주 단위 수동 그리드 (LazyVGrid는 풀스크린에서 높이 collapse 이슈가 있어 회피)
                HStack(spacing: 3) {
                    ForEach(Array(["일","월","화","수","목","금","토"].enumerated()), id: \.offset) { i, w in
                        Text(w).font(DT.sans(9))
                            .foregroundStyle(i == 0 ? DT.accent.opacity(0.85) : DT.inkSoft)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(weeks.indices, id: \.self) { wi in
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { di in
                            if let d = weeks[wi][di] {
                                cell(d)
                            } else {
                                Color.clear.frame(maxWidth: .infinity).frame(height: 52)
                            }
                        }
                    }
                }
                if let sel = selected, let d = days.first(where: { $0.day == sel }) {
                    detail(d)
                } else {
                    Text("날짜를 누르면 그날의 기운을 볼 수 있어요")
                        .font(DT.sans(10)).foregroundStyle(DT.inkSoft).padding(.top, 2)
                }
            }
        }
        .fullScreenCover(isPresented: $showFull) { FortuneCalendarView() }
    }

    /// 선행 빈칸 + 날짜를 7칸씩 끊어 주(週) 배열로 (마지막 주는 nil로 패딩)
    private var weeks: [[MonthlyCalendarDay?]] {
        var cells: [MonthlyCalendarDay?] = Array(repeating: nil, count: max(0, lead))
        cells += days.map { Optional($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0 + 7]) }
    }

    // 절기 맵 (양력 월 → [일: 절기명]) — 월당 ~2개
    private var terms: [Int: String] { SolarTermsTable.termsInMonth(year: year, month: month) }
    private func lunarOf(_ day: Int) -> LunarDate? { try? LunarConverter.solarToLunar(year: year, month: month, day: day) }

    /// 음력일 → 달 위상 SF Symbol (음력 날짜가 곧 달 모양)
    private func moonSymbol(_ lunarDay: Int) -> String {
        switch lunarDay {
        case 1:        return "moonphase.new"               // 삭(신월)
        case 2...6:    return "moonphase.waxing.crescent"   // 초승달
        case 7...9:    return "moonphase.first.quarter"     // 상현 반달
        case 10...14:  return "moonphase.waxing.gibbous"
        case 15:       return "moonphase.full"              // 보름달
        case 16...20:  return "moonphase.waning.gibbous"
        case 21...23:  return "moonphase.last.quarter"      // 하현 반달
        default:       return "moonphase.waning.crescent"   // 그믐달
        }
    }

    /// 셀 하단 마커 — 절기 우선, 그다음 음력(달 위상 아이콘 + 초하루/보름 강조)
    private func marker(_ day: Int) -> (icon: String?, text: String, color: Color, strong: Bool) {
        if let t = terms[day] { return (nil, t, DT.accent, true) }
        if let lu = lunarOf(day) {
            let icon = moonSymbol(lu.day)
            let gold = dtDyn(0x8C6E3C, 0xC0A368)
            if lu.day == 1 { return (icon, "\(lu.isLeapMonth ? "윤" : "")\(lu.month)월", gold, true) }
            if lu.day == 15 { return (icon, "보름", gold, true) }
            return (icon, "\(lu.day)", DT.inkSoft.opacity(0.75), false)
        }
        return (nil, "", DT.inkSoft, false)
    }

    private func cell(_ d: MonthlyCalendarDay) -> some View {
        let isToday = d.day == today
        let isSel = d.day == selected
        let mk = marker(d.day)
        let isSat = weekday(d.day) == "토"
        let isSun = weekday(d.day) == "일"
        return VStack(spacing: 2) {
            Text("\(d.day)")
                .font(DT.sans(11, isToday ? .bold : .medium))
                .foregroundStyle(isToday ? DT.accent : (isSun ? dtDyn(0xC0506A, 0xE08098) : (isSat ? dtDyn(0x3F6CB0, 0x6E97D2) : DT.ink)))
            Text("\(stemHanja(d.stemKorean))\(branchHanja(d.branchKorean))")
                .font(DT.serif(12, .semibold)).foregroundStyle(elColor(stemElement(d.stemKorean)))
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(d.tenGod)
                .font(DT.sans(8)).foregroundStyle(DT.inkSoft)
                .lineLimit(1).minimumScaleFactor(0.6)
            HStack(spacing: 2) {
                if let ic = mk.icon {
                    Image(systemName: ic).font(.system(size: 7)).foregroundStyle(mk.color)
                }
                if !mk.text.isEmpty {
                    Text(mk.text)
                        .font(DT.sans(8, mk.strong ? .semibold : .regular))
                        .foregroundStyle(mk.color)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
        }
        .frame(maxWidth: .infinity).frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSel ? DT.accentSoft : (isToday ? DT.accentSoft.opacity(0.4) : scoreColor(d.overallScore).opacity(0.06)))
        )
        .overlay(alignment: .topTrailing) {
            Circle().fill(scoreColor(d.overallScore)).frame(width: 5, height: 5).padding(4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSel ? DT.accent : (terms[d.day] != nil ? DT.accent.opacity(0.4) : .clear), lineWidth: isSel ? 1.2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { selected = (selected == d.day) ? nil : d.day }
    }

    private func detail(_ d: MonthlyCalendarDay) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Rectangle().fill(DT.line).frame(height: 1).padding(.vertical, 2)
            HStack(spacing: 6) {
                Text("\(month)월 \(d.day)일 (\(weekday(d.day)))")
                    .font(DT.sans(11, .semibold)).foregroundStyle(DT.inkSoft)
                if let lu = lunarOf(d.day) {
                    Image(systemName: moonSymbol(lu.day)).font(.system(size: 11)).foregroundStyle(dtDyn(0x8C6E3C, 0xC0A368))
                    Text("음력 \(lu.isLeapMonth ? "윤" : "")\(lu.month).\(lu.day)")
                        .font(DT.sans(11)).foregroundStyle(DT.inkSoft)
                }
                if let t = terms[d.day] {
                    Text(t).font(DT.sans(10, .bold)).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(DT.accent).clipShape(Capsule())
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Text("\(stemHanja(d.stemKorean))\(branchHanja(d.branchKorean))")
                    .font(DT.serif(20, .bold)).foregroundStyle(elColor(stemElement(d.stemKorean)))
                Text("\(d.stemKorean)\(d.branchKorean) · \(d.tenGod)의 날")
                    .font(DT.sans(13, .semibold)).foregroundStyle(DT.ink)
                Spacer()
                Text("\(d.overallScore)점")
                    .font(DT.sans(13, .bold)).foregroundStyle(scoreColor(d.overallScore))
            }
            Text(tendency(d.tenGod, d.overallScore))
                .font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
        }
    }

    // MARK: 헬퍼
    private func scoreColor(_ s: Int) -> Color {
        if s >= 70 { return dtDyn(0x5A9E6F, 0x7FC093) }
        if s >= 50 { return dtDyn(0xE0B450, 0xEBC873) }
        if s >= 35 { return DT.accent }
        return dtDyn(0xB0A088, 0x8E826E)
    }
    private func elColor(_ e: String) -> Color {
        switch e {
        case "Wood", "목": return dtDyn(0x4E9A51, 0x6FBF73)
        case "Fire", "화": return dtDyn(0xD1495B, 0xE5757F)
        case "Earth", "토": return dtDyn(0xC79A3B, 0xDDBA62)
        case "Metal", "금": return dtDyn(0x9AA0A6, 0xBCC1C7)
        case "Water", "수": return dtDyn(0x3F6CB0, 0x6E97D2)
        default: return DT.inkSoft
        }
    }
    private func stemHanja(_ k: String) -> String { SajuTables.stems.first { $0.korean == k }?.hanja ?? k }
    private func branchHanja(_ k: String) -> String { SajuTables.branches.first { $0.korean == k }?.hanja ?? k }
    private func stemElement(_ k: String) -> String { SajuTables.stems.first { $0.korean == k }?.element ?? "" }

    private func weekday(_ day: Int) -> String {
        var c = DateComponents(); c.year = year; c.month = month; c.day = day
        let wd = Calendar.current.date(from: c).map { Calendar.current.component(.weekday, from: $0) } ?? 1
        return ["일","월","화","수","목","금","토"][(wd - 1) % 7]
    }

    private static let tenGodTendency: [String: String] = [
        "비견": "내 페이스대로 밀고 가기 좋은 날. 협업보다 단독 플레이가 편해요.",
        "겁재": "경쟁심·욕심이 커지기 쉬운 날. 하나에 힘을 모아보세요.",
        "식신": "여유와 즐거움이 복이 되는 날. 좋아하는 일로 충전해요.",
        "상관": "표현·아이디어가 빛나는 날. 하고 싶은 말은 꺼내보세요.",
        "편재": "기회가 여기저기 열리는 활동적인 날. 제안을 살펴봐요.",
        "정재": "착실함이 쌓이는 날. 할 일·지출을 차근차근 정리해요.",
        "편관": "긴장·압박이 느껴지는 날. 큰일은 핵심부터 끊어서 처리해요.",
        "정관": "원칙과 책임이 빛나는 날. 약속·마감을 먼저 챙겨요.",
        "편인": "생각이 깊어지는 날. 혼자 몰입하거나 새 분야를 살펴봐요.",
        "정인": "마음이 차분히 채워지는 날. 책·휴식으로 나를 돌봐요.",
    ]
    private func tendency(_ tenGod: String, _ score: Int) -> String {
        let base = Self.tenGodTendency[tenGod] ?? "무난하게 흐르는 하루예요."
        let tail = score >= 65 ? " 흐름이 좋으니 적극적으로 움직여 봐요."
                 : (score >= 40 ? " 평소 리듬을 지키면 충분해요." : " 무리하지 말고 충전하는 날로 삼아요.")
        return base + tail
    }
}

// MARK: - 운세 달력 전체 화면 (월 전환 + 그날의 기운)

struct FortuneCalendarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var year: Int
    @State private var month: Int

    init() {
        let now = Date()
        _year = State(initialValue: Calendar.current.component(.year, from: now))
        _month = State(initialValue: Calendar.current.component(.month, from: now))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let r = appState.ensureSaju() {
                    let days = DailyFortuneEngine.calculateMonthlyCalendar(
                        year: year, month: month,
                        dayMasterElement: r.dayMaster.element, dayMasterYinYang: r.dayMaster.yin_yang,
                        dayMasterHanja: r.dayMaster.hanja, birthYear: appState.profile?.year ?? year)
                    let comp = DateComponents(year: year, month: month, day: 1)
                    let firstWd = Calendar.current.date(from: comp).map { Calendar.current.component(.weekday, from: $0) } ?? 1
                    let lead = firstWd - 1
                    let now = Date()
                    let isCurMonth = year == Calendar.current.component(.year, from: now)
                        && month == Calendar.current.component(.month, from: now)
                    let today = isCurMonth ? Calendar.current.component(.day, from: now) : -1

                    VStack(spacing: 16) {
                        monthSwitcher
                        MonthlyFortuneCalendar(days: days, year: year, month: month,
                                               today: today, lead: lead, showHeader: false)
                            .id("\(year)-\(month)")   // 월 전환 시 선택 초기화
                        legend
                    }
                    .padding(.horizontal, DT.pagePadding)
                    .padding(.vertical, 12)
                } else {
                    ContentUnavailableView("사주 정보가 필요해요", systemImage: "calendar",
                                           description: Text("생년월일을 먼저 입력해 주세요."))
                        .padding(.top, 60)
                }
            }
            .background(DT.bg)
            .navigationTitle("운세 달력")
            .navigationBarTitleDisplayMode(.inline)
            .dtCloseToolbar { dismiss() }
        }
    }

    private var monthSwitcher: some View {
        HStack {
            Button { shift(-1) } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DT.ink).frame(width: 44, height: 38)
            }
            Spacer()
            Text("\(String(year))년 \(month)월").font(DT.serif(18, .bold)).foregroundStyle(DT.ink)
            Spacer()
            Button { shift(1) } label: {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DT.ink).frame(width: 44, height: 38)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendDot(dtDyn(0x5A9E6F, 0x7FC093), "좋음")
            legendDot(dtDyn(0xE0B450, 0xEBC873), "보통")
            legendDot(DT.accent, "주의")
            legendDot(dtDyn(0xB0A088, 0x8E826E), "휴식")
        }
        .font(DT.sans(10)).foregroundStyle(DT.inkSoft)
        .frame(maxWidth: .infinity)
    }
    private func legendDot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 3) { Circle().fill(c).frame(width: 6, height: 6); Text(t) }
    }

    private func shift(_ d: Int) {
        var m = month + d, y = year
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        month = m; year = y
    }
}
