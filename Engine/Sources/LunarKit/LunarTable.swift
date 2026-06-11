// 음력 테이블 (lunar-javascript 1.7.x에서 추출, 1899~2100)
// 원본: saju-api/tests/golden — npm run golden 시점의 lunar-javascript 계산 결과.
// 자미두수 경로(양력→음력)의 정답 소스.

import Foundation

struct LunarTable: Sendable {
    struct Month: Sendable {
        let number: Int      // 1~12
        let isLeap: Bool
        let days: Int        // 29 | 30
    }

    struct Year: Sendable {
        let year: Int
        let newYearJDN: Int  // 음력 1/1의 양력 JDN
        let leapMonth: Int   // 0 = 윤달 없음
        let months: [Month]  // 달력 순서 (윤달은 해당 평달 뒤)
    }

    let from: Int
    let to: Int
    let years: [Year]        // index = year - from

    func year(_ y: Int) -> Year? {
        guard y >= from, y <= to else { return nil }
        return years[y - from]
    }

    /// JDN이 속한 음력 연도 엔트리 (설날 JDN 기준 이분 탐색)
    func yearContaining(jdn: Int) -> Year? {
        guard let first = years.first, jdn >= first.newYearJDN else { return nil }
        var lo = 0, hi = years.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if years[mid].newYearJDN <= jdn { lo = mid } else { hi = mid - 1 }
        }
        return years[lo]
    }

    static let shared: LunarTable = {
        guard let url = Bundle.module.url(forResource: "lunar-table", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawTable.self, from: data)
        else {
            fatalError("LunarKit: lunar-table.json 리소스를 로드할 수 없습니다")
        }
        let years = raw.years.map { entry in
            Year(
                year: entry.y,
                newYearJDN: JulianDay.jdn(entry.ny[0], entry.ny[1], entry.ny[2]),
                leapMonth: entry.leap,
                months: entry.months.map { Month(number: $0[0], isLeap: $0[1] == 1, days: $0[2]) }
            )
        }
        return LunarTable(from: raw.from, to: raw.to, years: years)
    }()

    private struct RawTable: Decodable {
        struct YearEntry: Decodable {
            let y: Int
            let ny: [Int]
            let leap: Int
            let months: [[Int]]
        }
        let from: Int
        let to: Int
        let years: [YearEntry]
    }
}
