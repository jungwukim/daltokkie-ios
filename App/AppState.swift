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
