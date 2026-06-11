// LunarKit — 음력 변환 엔진
// saju-api의 lunar-javascript(자미두수 경로) + ft-lib 테이블(사주 음력 입력 경로) 포팅.
// 골든 픽스처(tests/golden/fixtures/lunar-conversion.json) 100% 일치가 정확성 기준.

import Foundation

public struct SolarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
}

public struct LunarDate: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool

    public init(year: Int, month: Int, day: Int, isLeapMonth: Bool) {
        self.year = year
        self.month = month
        self.day = day
        self.isLeapMonth = isLeapMonth
    }
}

public enum LunarError: Error, CustomStringConvertible {
    case outOfRange(String)
    case invalidDate(String)

    public var description: String {
        switch self {
        case .outOfRange(let msg): return "지원 범위 밖: \(msg)"
        case .invalidDate(let msg): return "유효하지 않은 날짜: \(msg)"
        }
    }
}

/// 율리우스 적일(JDN) — 그레고리력 기준. 1899~2100 범위에서 모든 중간값이 양수이므로
/// Swift의 0방향 절삭 나눗셈과 floor 나눗셈이 일치한다.
/// SajuKit의 일주(日柱) 일수 차 계산에서도 사용하므로 public.
public enum JulianDay {
    public static func jdn(_ year: Int, _ month: Int, _ day: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3
        return day + (153 * m + 2) / 5 + 365 * y + y / 4 - y / 100 + y / 400 - 32045
    }

    public static func toDate(_ jdn: Int) -> (year: Int, month: Int, day: Int) {
        let a = jdn + 32044
        let b = (4 * a + 3) / 146097
        let c = a - 146097 * b / 4
        let d = (4 * c + 3) / 1461
        let e = c - 1461 * d / 4
        let m = (5 * e + 2) / 153
        let day = e - (153 * m + 2) / 5 + 1
        let month = m + 3 - 12 * (m / 10)
        let year = 100 * b + d - 4800 + m / 10
        return (year, month, day)
    }
}
