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

    // MARK: - 점성술

    @discardableResult
    func ensureNatal() -> NatalChart? {
        if let cached = natalChart { return cached }
        guard let p = profile else { return nil }
        do {
            let geo = RegionCoords.coords(for: p.region)
            let chart = try NatalEngine.calculateNatal(NatalInput(
                year: p.year, month: p.month, day: p.day,
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
            let chart = try ZiweiEngine.createChart(
                year: p.year, month: p.month, day: p.day,
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
