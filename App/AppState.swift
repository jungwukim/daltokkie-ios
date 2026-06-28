// 앱 전역 상태 — 프로필 + 엔진 계산 결과 캐시
// 모든 계산은 온디바이스 (서버 의존: AI 심층 해석만)

import Foundation
import SwiftUI
import SajuKit
import NatalKit
import ZiweiKit

@MainActor
final class AppState: ObservableObject {
    @Published var profile: UserProfile? {
        didSet {
            profile?.save()
            if profile != oldValue { invalidate() }
        }
    }
    @Published var selectedTab: Tab = .home

    /// 홈 히어로 'AI 한 줄' — 날짜별 캐시(주간 7일치 한 번에 생성). 없으면 규칙 기반 요약으로 폴백
    @Published var heroLines: [String: MoonLetter] = [:]
    private var heroLinesLoading: Set<String> = []

    enum Tab: String, CaseIterable {
        case home, talisman, fortune, tarot, my
    }

    // 계산 캐시 (프로필 변경 시 무효화)
    private(set) var sajuResult: FortuneTellerResult?
    private(set) var dailyBundle: DailyFortuneBundle?
    private(set) var natalChart: NatalChart?
    private(set) var ziweiChart: ZiweiChart?
    private(set) var ziweiLiunian: LiuNianInfo?
    private(set) var ziweiDaxian: [DaxianInfo]?
    var lastError: String?

    init() {
        profile = UserProfile.load()
    }

    private func invalidate() {
        sajuResult = nil
        dailyBundle = nil
        heroLines = [:]
        heroLinesLoading = []
        natalChart = nil
        ziweiChart = nil
        ziweiLiunian = nil
        ziweiDaxian = nil
        objectWillChange.send()
    }

    /// 당겨서 새로고침 — 캐시를 비우고 오늘 기준으로 재계산(날짜 변경·오류 후 복구)
    func refresh() {
        invalidate()
        _ = ensureDailyBundle()
    }

    private static func todayComponents() -> (y: Int, m: Int, d: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let c = cal.dateComponents([.year, .month, .day], from: Date())
        return (c.year!, c.month!, c.day!)
    }

    // MARK: - 사주

    @discardableResult
    func ensureSaju() -> FortuneTellerResult? {
        if let cached = sajuResult { return cached }
        guard let p = profile else { return nil }
        do {
            let r = try SajuCalculator.calculate(
                year: p.year, month: p.month, day: p.day,
                hour: p.hour, gender: p.gender,
                calendar: p.calendar, isLeapMonth: p.isLeapMonth,
                useTrueSolarTime: p.useTrueSolarTime, region: p.region,
                minute: p.minute
            )
            sajuResult = r
            return r
        } catch {
            lastError = "\(error)"
            return nil
        }
    }

    /// 사주 시점 타임라인(실제 연도) — LLM이 연도를 환각하지 않도록 대운/세운/월운을 직접 제공
    func sajuTimelineJSON() -> [String: Any]? {
        guard let r = ensureSaju(), let p = profile else { return nil }
        let cy = Self.todayComponents().y
        let age = cy - p.year
        let dme = r.dayMaster.element, dmy = r.dayMaster.yin_yang, dmh = r.dayMaster.hanja

        let daeun = HoshinDaeUn.calculateDaeUn(r.raw)
        let daeunArr: [[String: Any]] = daeun.map { d in
            ["startAge": d.startAge, "endAge": d.endAge,
             "startYear": p.year + d.startAge, "endYear": p.year + d.endAge,
             "ganzhi": "\(d.stem)\(d.branch)", "stemElement": d.stemElement, "branchElement": d.branchElement]
        }
        let currentDaeun = daeunArr.first {
            ($0["startAge"] as? Int ?? 0) <= age && age <= ($0["endAge"] as? Int ?? 0)
        }
        var saeun: [[String: Any]] = []
        for y in cy...(cy + 4) {
            let yf = EngineAnalysis.calculateYearFortune(targetYear: y, dayMasterElement: dme, dayMasterYinYang: dmy, dayMasterHanja: dmh)
            saeun.append(["year": y, "ganzhi": "\(yf.stemHanja)\(yf.branchHanja)",
                          "tenGodStem": yf.tenGodStem, "tenGodBranch": yf.tenGodBranch, "element": yf.stemElement])
        }
        let months = EngineAnalysis.calculateMonthlyPillars(targetYear: cy, dayMasterElement: dme, dayMasterYinYang: dmy, dayMasterHanja: dmh)
        let monthly: [[String: Any]] = months.map {
            ["month": $0.month, "ganzhi": "\($0.stemHanja)\($0.branchHanja)", "tenGodStem": $0.tenGodStem]
        }
        var t: [String: Any] = ["currentYear": cy, "age": age, "daeun": daeunArr, "saeun": saeun, "monthlyOfCurrentYear": monthly]
        if let cd = currentDaeun { t["currentDaeun"] = cd }
        return t
    }

    @discardableResult
    func ensureDailyBundle() -> DailyFortuneBundle? {
        let today = Self.todayComponents()
        if let cached = dailyBundle, cached.today.date == String(format: "%04d-%02d-%02d", today.y, today.m, today.d) {
            return cached
        }
        guard let p = profile, let saju = ensureSaju() else { return nil }
        // 오늘 중심 7일치 (오늘±3) — 오늘이 항상 7개 점의 정중앙(index 3)에 오도록
        let todayJDN = LunarKitJDN(today.y, today.m, today.d)
        let (by, bm, bd) = LunarKitJDNToDate(todayJDN - 3)
        let bundle = DailyFortuneService.build(
            saju: saju, birthYear: p.year,
            targetYear: by, targetMonth: bm, targetDay: bd,
            days: 7,
            todayYear: today.y, todayMonth: today.m, todayDay: today.d
        )
        dailyBundle = bundle
        return bundle
    }

    /// 오늘의 일진 payload — 콘텐츠/해석 라우트가 그날 간지를 추론(환각)하지 않도록 전달.
    /// daily-* AI 콘텐츠(오늘의 한마디·운세·할일피할일 등)의 명리 정확도용.
    func todayDailyPayload() -> [String: Any]? {
        guard let bundle = ensureDailyBundle() else { return nil }
        let t = bundle.today
        let sinsals = HoshinSinSal.transitSinSals(
            transitBranch: t.dayBranchKorean,
            natalDayStem: bundle.saju.raw.day.stem, natalDayBranch: bundle.saju.raw.day.branch)
        var relations: [String] = []
        for tr in t.transitRelations {
            for r in tr.stemRelations { relations.append("\(tr.natalPillar)와 \(r.type)") }
            for r in tr.branchRelations { relations.append("\(tr.natalPillar)와 \(r.type)") }
        }
        let conditions: [[String: Any]] = t.cards.map {
            ["name": $0.category, "score": $0.score, "grade": $0.grade]
        }
        return [
            "date": t.date,
            "weekday": Self.koWeekday(t.date),
            "dayPillarKo": "\(t.dayStemKorean)\(t.dayBranchKorean)",
            "tenGod": t.tenGodOfDay,
            "twelveStage": t.twelveStageOfDay,
            "overallScore": t.overallScore,
            "overallGrade": t.overallGrade,
            "conditions": conditions,
            "relations": relations,
            "sinsals": sinsals,
        ]
    }

    // MARK: - 홈 히어로 AI 한 줄 (하루 1회 생성·캐시, 실패/오프라인 시 규칙 기반 폴백)

    private func heroLineCacheKey(date: String, _ p: UserProfile) -> String {
        let sig = "\(p.year).\(p.month).\(p.day).\(p.hour ?? -1).\(p.minute).\(p.gender).\(p.calendar).\(p.region)"
        // v2: 시적 비유 → 구체적 한마디로 프롬프트 변경, 기존 캐시 무효화
        return "heroAILine.v2|\(date)|\(sig)"
    }

    /// 3줄 AI 텍스트 → MoonLetter(첫 줄=큰 글귀, 나머지=본문).
    /// 짧은 3줄 형식만 수용 — 긴 편지/마크다운(구버전 서버)·이상 출력은 nil로 거부(→ 규칙 기반 폴백)
    private static func parseHeroLine(_ text: String) -> MoonLetter? {
        func clean(_ s: Substring) -> String {
            s.trimmingCharacters(in: CharacterSet(charactersIn: " \t\"'“”‘’-•*#").union(.whitespaces))
        }
        let lines = text.split(separator: "\n").map(clean).filter { !$0.isEmpty }
        guard (1...3).contains(lines.count) else { return nil }       // 편지(여러 문단) 거부
        guard let first = lines.first, first.count <= 20 else { return nil }
        guard !lines.contains(where: { $0.count > 32 }) else { return nil }   // 긴 문장 거부
        let body = lines.dropFirst().prefix(2).joined(separator: "\n")
        return MoonLetter(title: first, body: body.isEmpty ? "오늘 하루도 잘 보내요." : body)
    }

    private static func koWeekday(_ date: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Seoul")
        guard let d = f.date(from: date) else { return "" }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let wd = cal.component(.weekday, from: d)   // 1=일
        return ["일", "월", "화", "수", "목", "금", "토"][(wd - 1) % 7] + "요일"
    }

    /// 주간 7일치(오늘±3) AI 한 줄을 한 번에 확보 — 날짜별로 캐시 있으면 즉시,
    /// 없는 날만 비동기 생성 후 날짜별 캐시(실패/이상 출력은 거부 → 해당 날 규칙 폴백)
    func ensureHeroLines() {
        guard let p = profile, let bundle = ensureDailyBundle() else { return }
        let stem = bundle.saju.raw.day.stem, branch = bundle.saju.raw.day.branch
        for day in bundle.fortunes {
            if heroLines[day.date] != nil || heroLinesLoading.contains(day.date) { continue }
            let key = heroLineCacheKey(date: day.date, p)
            if let cached = UserDefaults.standard.string(forKey: key), let m = Self.parseHeroLine(cached) {
                heroLines[day.date] = m
                continue
            }
            heroLinesLoading.insert(day.date)
            let sinsals = HoshinSinSal.transitSinSals(transitBranch: day.dayBranchKorean,
                                                      natalDayStem: stem, natalDayBranch: branch)
            let weekday = Self.koWeekday(day.date)
            let target = day
            Task { [weak self] in
                guard let self else { return }
                var full = ""
                do {
                    for try await chunk in AIProxy.interpretDaily(
                        day: target, weekday: weekday, sinsals: sinsals,
                        gender: p.gender, birthYear: p.year, region: p.region, style: "oneline") {
                        full += chunk
                    }
                } catch {
                    await MainActor.run { self.heroLinesLoading.remove(target.date) }
                    return   // 폴백(규칙 기반) 유지
                }
                let text = full.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    self.heroLinesLoading.remove(target.date)
                    guard let m = Self.parseHeroLine(text) else { return }
                    UserDefaults.standard.set(text, forKey: key)
                    self.heroLines[target.date] = m
                }
            }
        }
    }

    /// 프로필 생년월일을 양력으로 — 음력 입력이면 양력 변환(사주와 동일 LegacyLunarConverter).
    /// 점성/자미 엔진은 양력 입력을 기대하므로 음력 프로필은 반드시 선변환해야 함.
    private func solarBirth(_ p: UserProfile) -> (year: Int, month: Int, day: Int) {
        if p.calendar == "lunar",
           let s = try? LegacyLunarConverter.lunarToSolar(
               year: p.year, month: p.month, day: p.day, isLeapMonth: p.isLeapMonth) {
            return (s.year, s.month, s.day)
        }
        return (p.year, p.month, p.day)
    }

    // MARK: - 점성술

    @discardableResult
    func ensureNatal() -> NatalChart? {
        if let cached = natalChart { return cached }
        guard let p = profile else { return nil }
        do {
            let geo = RegionCoords.coords(for: p.region)
            let s = solarBirth(p)
            let chart = try NatalEngine.calculateNatal(NatalInput(
                year: s.year, month: s.month, day: s.day,
                hour: p.hour ?? 12, minute: p.minute,
                latitude: geo.lat, longitude: geo.lon,
                unknownTime: p.hour == nil,
                timezone: "Asia/Seoul"
            ), houseSystem: "W", trueNode: true)
            natalChart = chart
            return chart
        } catch {
            lastError = "\(error)"
            return nil
        }
    }

    // MARK: - 자미두수

    @discardableResult
    func ensureZiwei() -> ZiweiChart? {
        if let cached = ziweiChart { return cached }
        guard let p = profile else { return nil }
        do {
            let s = solarBirth(p)
            let chart = try ZiweiEngine.createChart(
                year: s.year, month: s.month, day: s.day,
                hour: p.hour ?? 12, minute: p.minute,
                isMale: p.gender == "male"
            )
            ziweiChart = chart
            ziweiLiunian = ZiweiEngine.calculateLiunian(chart: chart, year: Self.todayComponents().y)
            ziweiDaxian = ZiweiEngine.daxianList(chart: chart)
            return chart
        } catch {
            lastError = "\(error)"
            return nil
        }
    }
}

// LunarKit JulianDay 브릿지 (모듈 경계 — 간단 재노출)
import LunarKit
func LunarKitJDN(_ y: Int, _ m: Int, _ d: Int) -> Int { JulianDay.jdn(y, m, d) }
func LunarKitJDNToDate(_ jdn: Int) -> (Int, Int, Int) { JulianDay.toDate(jdn) }
