// 양력↔음력 변환 (lunar-javascript 호환 — 자미두수 경로)

import Foundation

public enum LunarConverter {
    /// 양력 → 음력. 자미두수 명반 생성의 입력 경로.
    /// lunar-javascript의 Solar.fromYmd().getLunar()와 동일 결과를 보장한다.
    public static func solarToLunar(year: Int, month: Int, day: Int) throws -> LunarDate {
        let t = JulianDay.jdn(year, month, day)
        guard let entry = LunarTable.shared.yearContaining(jdn: t) else {
            throw LunarError.outOfRange("\(year)-\(month)-\(day) (지원: \(LunarTable.shared.from)~\(LunarTable.shared.to))")
        }
        var offset = t - entry.newYearJDN
        for m in entry.months {
            if offset < m.days {
                return LunarDate(year: entry.year, month: m.number, day: offset + 1, isLeapMonth: m.isLeap)
            }
            offset -= m.days
        }
        // 다음 해 설날 이전 날짜는 반드시 위에서 반환됨 (테이블 일관성 검증 완료)
        throw LunarError.invalidDate("\(year)-\(month)-\(day)")
    }

    /// 음력 → 양력 (lunar-javascript 테이블 기준)
    public static func lunarToSolar(year: Int, month: Int, day: Int, isLeapMonth: Bool) throws -> SolarDate {
        guard let entry = LunarTable.shared.year(year) else {
            throw LunarError.outOfRange("음력 \(year)년 (지원: \(LunarTable.shared.from)~\(LunarTable.shared.to))")
        }
        if isLeapMonth && entry.leapMonth != month {
            throw LunarError.invalidDate("음력 \(year)년에는 윤\(month)월이 없습니다")
        }
        var acc = 0
        for m in entry.months {
            if m.number == month && m.isLeap == isLeapMonth {
                guard day >= 1, day <= m.days else {
                    throw LunarError.invalidDate("음력 \(year)/\(month)/\(day) — 해당 월은 \(m.days)일까지")
                }
                let (y, mm, d) = JulianDay.toDate(entry.newYearJDN + acc + day - 1)
                return SolarDate(year: y, month: mm, day: d)
            }
            acc += m.days
        }
        throw LunarError.invalidDate("음력 \(year)/\(month) 없음")
    }
}
