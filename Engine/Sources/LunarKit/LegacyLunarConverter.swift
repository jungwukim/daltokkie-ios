// 사주 음력 입력 경로 — saju-api lib/saju/ft-lib.ts의 lunarToSolar 포팅 (manseryeok 계열 비트팩 테이블)
//
// ⚠️ LunarConverter(lunar-javascript 기준)와 별개로 유지한다.
// 사주 엔진의 음력 입력은 웹 서비스에서 이 테이블을 사용했으므로,
// 동일 입력 → 동일 사주팔자를 보장하려면 알고리즘을 비트 단위로 동일하게 재현해야 한다.
// 골든 픽스처 lunar-conversion.json의 lunarToSolar 섹션이 이 구현의 정답 소스.

import Foundation

public enum LegacyLunarConverter {
    /// 1900~2100 음력 연도별 비트팩 데이터 (ft-lib.ts LUNAR_DATA 그대로)
    /// 하위 4비트: 윤달 번호, 비트 4~15: 12개월 대소(30/29일), 비트 16: 윤달 대소
    private static let lunarData: [Int] = [
        0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, 0x04ae0,
        0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, 0x04970, 0x0a4b0,
        0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, 0x06566, 0x0d4a0, 0x0ea50,
        0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, 0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0,
        0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, 0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0,
        0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, 0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260,
        0x0f263, 0x0d950, 0x05b57, 0x056a0, 0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558,
        0x0b540, 0x0b6a0, 0x195a6, 0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46,
        0x0ab60, 0x09570, 0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5,
        0x092e0, 0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
        0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, 0x07954,
        0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, 0x05aa0, 0x076a3,
        0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, 0x0b5a0, 0x056d0, 0x055b2,
        0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 0x14b63, 0x09370, 0x049f8, 0x04970,
        0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, 0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0,
        0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, 0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50,
        0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, 0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60,
        0x0a570, 0x054e4, 0x0d160, 0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0,
        0x0d150, 0x0f252, 0x0d520,
    ]

    private static func data(_ year: Int) -> Int { lunarData[year - 1900] }

    private static func leapMonth(_ year: Int) -> Int { data(year) & 0xf }

    private static func leapMonthDays(_ year: Int) -> Int {
        guard leapMonth(year) != 0 else { return 0 }
        return (data(year) & 0x10000) != 0 ? 30 : 29
    }

    private static func lunarMonthDays(_ year: Int, _ month: Int) -> Int {
        (data(year) & (0x10000 >> month)) != 0 ? 30 : 29
    }

    private static func lunarYearDays(_ year: Int) -> Int {
        var sum = 348
        var mask = 0x8000
        while mask > 0x8 {
            sum += (data(year) & mask) != 0 ? 1 : 0
            mask >>= 1
        }
        return sum + leapMonthDays(year)
    }

    /// 음력 → 양력. ft-lib.ts lunarToSolar와 동일 알고리즘.
    /// 기준일: 1900-01-31 (음력 1900/1/1)
    public static func lunarToSolar(year: Int, month: Int, day: Int, isLeapMonth: Bool) throws -> SolarDate {
        guard year >= 1900, year - 1900 < lunarData.count else {
            throw LunarError.outOfRange("음력 \(year)년 (지원: 1900~\(1900 + lunarData.count - 1))")
        }
        var offset = 0
        for y in 1900..<year {
            offset += lunarYearDays(y)
        }
        let leap = leapMonth(year)
        // 원본 JS 루프 재현: 윤달 도달 시 윤달 일수 먼저 가산 후 같은 달을 다시 처리
        var leapAdded = false
        var i = 1
        while i < month {
            if leap > 0 && i == leap && !leapAdded {
                offset += leapMonthDays(year)
                leapAdded = true
            } else {
                offset += lunarMonthDays(year, i)
                i += 1
            }
        }
        if isLeapMonth && leap == month {
            offset += lunarMonthDays(year, month)
        }
        offset += day - 1

        let baseJDN = JulianDay.jdn(1900, 1, 31)
        let (y, m, d) = JulianDay.toDate(baseJDN + offset)
        return SolarDate(year: y, month: m, day: d)
    }
}
