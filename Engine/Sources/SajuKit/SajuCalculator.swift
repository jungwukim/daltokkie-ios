// ftCalculateSaju 등가 — saju-api lib/saju/fortuneteller.ts + time-utils.ts 포팅
// 입력(벽시계) → KDT 보정(항상) → 진태양시 보정(옵션) → SajuCore → KR→EN 변환

import Foundation
import LunarKit

public enum SajuCalculator {
    static let seoul = TimeZone(identifier: "Asia/Seoul")!

    // MARK: - 시간 보정 유틸 (time-utils.ts)

    /// JS Math.round 재현 (half-up; 음수 -0.5 → 0)
    static func jsRound(_ x: Double) -> Int {
        Int(floor(x + 0.5))
    }

    /// Intl longOffset의 분 단위 파싱 재현 — 초 단위는 절삭
    static func offsetMinutesTruncated(_ seconds: Int) -> Int {
        let sign = seconds < 0 ? -1 : 1
        let absSec = abs(seconds)
        return sign * ((absSec / 3600) * 60 + (absSec % 3600) / 60)
    }

    /// 한국 역사적 DST 델타 (분) — KDT(+10:00)면 +60, 1954~61 표준시 +8:30이면 -30
    static func koreanDstDelta(year: Int, month: Int, day: Int, hour: Int) -> Int {
        // TS: new Date(Date.UTC(year, month-1, day, hour-9, 0))
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour - 9
        comps.minute = 0
        guard let approxUtc = utcCal.date(from: comps) else { return 0 }
        let actualOffsetMin = offsetMinutesTruncated(seoul.secondsFromGMT(for: approxUtc))
        return actualOffsetMin - 540
    }

    /// 균시차(EoT, 분) — dayOfYear는 Seoul 로컬 자정 간 차이의 floor (TS와 동일, DST 영향 포함)
    static func equationOfTime(year: Int, month: Int, day: Int) -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = seoul
        var dc = DateComponents()
        dc.year = year; dc.month = month; dc.day = day
        var dc0 = DateComponents()
        dc0.year = year - 1; dc0.month = 12; dc0.day = 31
        guard let date = cal.date(from: dc), let startOfYear = cal.date(from: dc0) else { return 0 }
        let dayOfYear = Int(floor(date.timeIntervalSince(startOfYear) / 86400.0))
        let b = (2 * Double.pi * Double(dayOfYear - 81)) / 364
        return jsRound(9.87 * sin(2 * b) - 7.53 * cos(b) - 1.5 * sin(b))
    }

    /// 진태양시용 타임존 오프셋 (분) — 지역 타임존의 해당 시점 오프셋
    static func timezoneOffsetMin(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Int {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour - 9
        comps.minute = minute
        guard let approxUtc = utcCal.date(from: comps) else { return 540 }
        return offsetMinutesTruncated(seoul.secondsFromGMT(for: approxUtc))
    }

    /// 비한국 출생지용 타임존 오프셋 (분) — 해당 타임존의 벽시계 시각 기준 실제 오프셋(DST 반영)
    static func timezoneOffsetMin(tzId: String, year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Int {
        guard let tz = TimeZone(identifier: tzId) else { return 0 }
        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = tz
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        guard let date = localCal.date(from: comps) else { return 0 }
        return offsetMinutesTruncated(tz.secondsFromGMT(for: date))
    }

    // MARK: - 메인 (ftCalculateSaju)

    public static func calculate(
        year: Int, month: Int, day: Int,
        hour: Int? = nil,
        gender: String = "other",
        calendar: String = "solar",
        isLeapMonth: Bool = false,
        useTrueSolarTime: Bool = true,
        region: String = "서울",
        minute: Int = 0,
        overrideTimezone: String? = nil,
        overrideLongitude: Double? = nil
    ) throws -> FortuneTellerResult {
        let ftGender = gender == "male" ? "male" : "female"

        // 음력 → 양력 (ft-lib 비트팩 테이블 — LegacyLunarConverter)
        var solarYear = year, solarMonth = month, solarDay = day
        if calendar == "lunar" {
            let solar = try LegacyLunarConverter.lunarToSolar(year: year, month: month, day: day, isLeapMonth: isLeapMonth)
            solarYear = solar.year
            solarMonth = solar.month
            solarDay = solar.day
        }

        // KDT 보정 (항상) — TS 엔진과 동일. 비한국 모던 출생은 0이라 무영향.
        let dstDelta = koreanDstDelta(year: year, month: month, day: day, hour: hour ?? 12)
        var deltaMin = -dstDelta

        if useTrueSolarTime {
            // deltaMin = -tzOffset + longitude×4 + EoT + 2
            // 비한국 출생지면 출생지 타임존·경도로 진태양시 보정(서버 REGION_TIMEZONES 룩업과 동일 결과).
            // 한국(override 없음)은 기존 서울 경로 그대로 — 골든 픽스처/정통 재현 유지.
            let eot = equationOfTime(year: year, month: month, day: day)
            if let tzId = overrideTimezone, let lng = overrideLongitude {
                let tzOffsetMin = timezoneOffsetMin(tzId: tzId, year: year, month: month, day: day, hour: hour ?? 12, minute: minute)
                deltaMin = -tzOffsetMin + jsRound(lng * 4) + eot + 2
            } else {
                let regionLng = SajuTables.regionLongitudes[region] ?? 126.98
                let tzOffsetMin = timezoneOffsetMin(year: year, month: month, day: day, hour: hour ?? 12, minute: minute)
                deltaMin = -tzOffsetMin + jsRound(regionLng * 4) + eot + 2
            }
        }

        let h = hour ?? 12
        let m = hour == nil ? 0 : minute
        let totalMin = h * 60 + m + deltaMin
        let wrapped = ((totalMin % 1440) + 1440) % 1440
        let adjH = wrapped / 60
        let adjM = wrapped % 60

        // hoshin 계산 (반시법 — 내부 -32분 보정 포함)
        var raw = try SajuCore.calculateRaw(
            solarYear: solarYear, solarMonth: solarMonth, solarDay: solarDay,
            hour: adjH, minute: adjM, gender: ftGender
        )

        // 분석 레이어 (SajuAnalysis가 raw를 보강 — 코어 단계에서는 기둥만)
        SajuAnalysis.enrich(&raw)

        // KR→EN 변환
        let yearP = convertPillar(raw.year)
        let monthP = convertPillar(raw.month)
        let dayP = convertPillar(raw.day)
        let hourP = convertPillar(raw.hour)

        var counts: [String: Int] = ["Wood": 0, "Fire": 0, "Earth": 0, "Metal": 0, "Water": 0]
        for (krEl, count) in raw.wuxingCount {
            if let enEl = SajuTables.elementKrToEn[krEl] { counts[enEl] = count }
        }

        let hasHour = hour != nil
        if !hasHour {
            for key in counts.keys { counts[key] = 0 }
            for p in [yearP, monthP, dayP] {
                counts[p.stem.element]! += 1
                counts[p.branch.element]! += 1
            }
        }
        let total = counts.values.reduce(0, +)
        // TS reduce: 동률이면 첫 항목 유지 — Object.entries 순서(삽입 순) 재현
        let order = ["Wood", "Fire", "Earth", "Metal", "Water"]
        var dominant = order[0], weakest = order[0]
        for key in order.dropFirst() {
            if counts[key]! > counts[dominant]! { dominant = key }
            if counts[key]! < counts[weakest]! { weakest = key }
        }

        let yearYY = raw.year.yinYang
        let energyFlow = (yearYY == "양" && gender == "male") || (yearYY == "음" && gender == "female")
            ? "순행(順行)" : "역행(逆行)"

        let dayMaster = dayP.stem

        let fmtHanja = { (p: UIPillar) in "\(p.stem.hanja)\(p.branch.hanja)" }
        let fmtKorean = { (p: UIPillar) in "\(p.stem.korean)\(p.branch.korean)" }

        let displayHanja = hasHour
            ? [yearP, monthP, dayP, hourP].map(fmtHanja).joined(separator: " ")
            : [yearP, monthP, dayP].map(fmtHanja).joined(separator: " ") + " (시간미상)"
        let displayKorean = hasHour
            ? [yearP, monthP, dayP, hourP].map(fmtKorean).joined(separator: " ")
            : [yearP, monthP, dayP].map(fmtKorean).joined(separator: " ") + " (시간미상)"

        return FortuneTellerResult(
            pillars: (year: yearP, month: monthP, day: dayP, hour: hasHour ? hourP : nil),
            elements: SajuElements(counts: counts, dominant: dominant, weakest: weakest, total: total),
            energyFlow: energyFlow,
            gender: gender,
            dayMaster: dayMaster,
            dayMasterProfile: DayMasterProfiles.table[dayMaster.hanja],
            animal: yearP.branch.animal,
            displayHanja: displayHanja,
            displayKorean: displayKorean,
            raw: raw
        )
    }

    static func convertPillar(_ p: FtPillar) -> UIPillar {
        let stemData = SajuTables.stems.first { $0.korean == p.stem }
        let branchData = SajuTables.branches.first { $0.korean == p.branch }
        let branchYY = SajuTables.branchYinYang[p.branch] ?? p.yinYang
        return UIPillar(
            stem: UIStem(
                hanja: stemData?.hanja ?? p.stem,
                korean: p.stem,
                element: SajuTables.elementKrToEn[p.stemElement] ?? p.stemElement,
                yin_yang: SajuTables.yinYangKrToEn[p.yinYang] ?? p.yinYang
            ),
            branch: UIBranch(
                hanja: branchData?.hanja ?? p.branch,
                korean: p.branch,
                animal: SajuTables.branchAnimalEn[p.branch] ?? p.branch,
                element: SajuTables.elementKrToEn[p.branchElement] ?? p.branchElement,
                yin_yang: SajuTables.yinYangKrToEn[branchYY] ?? branchYY
            )
        )
    }
}

/// hoshin calculateSaju의 분석 파이프라인 — 원본과 동일한 순서로 raw를 보강
public enum SajuAnalysis {
    public static func enrich(_ raw: inout SajuRawData) {
        raw.tenGods = HoshinTenGods.generateTenGodsList(raw)
        raw.tenGodsDistribution = HoshinTenGods.calculateTenGodsDistribution(raw)
        raw.sinSals = HoshinSinSal.findSinSals(raw)

        let branches = [raw.year.branch, raw.month.branch, raw.day.branch, raw.hour.branch]
        raw.branchRelations = HoshinBranches.analyzeBranchRelations(branches)

        raw.jiJangGan = [
            "year": HoshinBranches.calculateJiJangGanStrength(branch: raw.year.branch, monthIndex: raw.monthIndex),
            "month": HoshinBranches.calculateJiJangGanStrength(branch: raw.month.branch, monthIndex: raw.monthIndex),
            "day": HoshinBranches.calculateJiJangGanStrength(branch: raw.day.branch, monthIndex: raw.monthIndex),
            "hour": HoshinBranches.calculateJiJangGanStrength(branch: raw.hour.branch, monthIndex: raw.monthIndex),
        ]

        raw.wolRyeong = HoshinBranches.checkWolRyeong(dayStem: raw.day.stem, monthBranch: raw.month.branch)
        raw.dayMasterStrength = HoshinStrength.analyzeDayMasterStrength(raw)
        raw.gyeokGuk = HoshinGyeokGuk.determineGyeokGuk(raw)
        raw.yongSin = HoshinYongSin.selectYongSin(raw)
    }
}
