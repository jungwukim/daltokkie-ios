// 골든 픽스처 검증 — daily-fortune.json 53건
// 일일운세 전체(점수/등급/십성/12운성/합충/fortuneSummary) + 월간 달력
// fortuneSummary 일치 = seeded PRNG가 JS와 비트 단위로 동일하다는 증명

import XCTest
@testable import SajuKit

final class DailyFortuneGoldenTests: XCTestCase {
    static let fixture: [String: Any] = {
        guard let url = Bundle.module.url(forResource: "daily-fortune", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { fatalError("daily-fortune.json 로드 실패") }
        return obj
    }()

    private func compute(birth: [String: Any]) throws -> FortuneTellerResult {
        try SajuCalculator.calculate(
            year: birth["y"] as! Int, month: birth["m"] as! Int, day: birth["d"] as! Int,
            hour: birth["h"] as? Int, gender: birth["gender"] as! String,
            calendar: "solar", isLeapMonth: false,
            useTrueSolarTime: false, region: "서울", minute: 0
        )
    }

    func test일일운세_골든픽스처_전건일치() throws {
        let cases = Self.fixture["cases"] as! [[String: Any]]
        var failures: [String] = []

        for c in cases {
            let input = c["input"] as! [String: Any]
            let birth = input["birth"] as! [String: Any]
            let target = input["target"] as! [String: Any]
            let expected = c["output"] as! [String: Any]

            let r = try compute(birth: birth)
            let dm = r.dayMaster
            let pillars = SajuPillars(year: r.pillars.year, month: r.pillars.month, day: r.pillars.day, hour: r.pillars.hour)

            let fortune = DailyFortuneEngine.calculateDailyFortune(
                targetYear: target["y"] as! Int, targetMonth: target["m"] as! Int, targetDay: target["d"] as! Int,
                dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang, dayMasterHanja: dm.hanja,
                birthYear: birth["y"] as! Int,
                natalPillars: pillars
            )

            let computed = try SajuAnalysisGoldenTests.jsonObject(fortune)
            let desc = "\(birth["y"]!)-\(birth["m"]!)-\(birth["d"]!) → \(target["y"]!)-\(target["m"]!)-\(target["d"]!)"
            if let d = SajuAnalysisGoldenTests.diff(computed, expected, path: "fortune") {
                failures.append("\(desc): \(d)")
            }
        }
        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }

    func test월간달력_골든픽스처_전건일치() throws {
        let calendarCases = Self.fixture["calendarCases"] as! [[String: Any]]
        var failures: [String] = []

        for c in calendarCases {
            let input = c["input"] as! [String: Any]
            let birth = input["birth"] as! [String: Any]
            let cal = input["calendar"] as! [String: Any]
            let expected = c["output"] as! [Any]

            let r = try compute(birth: birth)
            let dm = r.dayMaster

            let calendar = DailyFortuneEngine.calculateMonthlyCalendar(
                year: cal["year"] as! Int, month: cal["month"] as! Int,
                dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang, dayMasterHanja: dm.hanja,
                birthYear: birth["y"] as! Int
            )
            let computed = try SajuAnalysisGoldenTests.jsonObject(calendar)
            if let d = SajuAnalysisGoldenTests.diff(computed, expected, path: "calendar") {
                failures.append("\(birth["y"]!)-\(birth["m"]!)-\(birth["d"]!): \(d)")
            }
        }
        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건:\n" + failures.joined(separator: "\n"))
    }
}
