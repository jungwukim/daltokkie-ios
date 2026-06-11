// 골든 픽스처 검증 — saju-api lib/ziwei 엔진 출력과 완전 일치 확인
// 픽스처: saju-api/tests/golden/fixtures/ziwei.json (366건: 명반 + 유년 2026 + 대한)

import XCTest
@testable import ZiweiKit

final class ZiweiGoldenTests: XCTestCase {
    struct Fixture: Decodable {
        struct Input: Decodable {
            let y: Int, m: Int, d: Int, h: Int, min: Int
            let isMale: Bool
            let tag: String
        }
        struct Output: Decodable {
            let chart: ZiweiChart
            let liunian: LiuNianInfo
            let daxianList: [DaxianInfo]
        }
        struct Case: Decodable {
            let input: Input
            let output: Output
        }
        let referenceYear: Int
        let cases: [Case]
    }

    static let fixture: Fixture = {
        guard let url = Bundle.module.url(forResource: "ziwei", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let fixture = try? JSONDecoder().decode(Fixture.self, from: data)
        else { fatalError("ziwei.json 픽스처 로드 실패") }
        return fixture
    }()

    private func describe(_ input: Fixture.Input) -> String {
        "\(input.y)-\(input.m)-\(input.d) \(input.h):\(input.min) \(input.isMale ? "남" : "여") [\(input.tag)]"
    }

    func test명반_골든픽스처_전건일치() throws {
        var failures: [String] = []
        for c in Self.fixture.cases {
            let chart = try ZiweiEngine.createChart(
                year: c.input.y, month: c.input.m, day: c.input.d,
                hour: c.input.h, minute: c.input.min, isMale: c.input.isMale
            )
            if chart != c.output.chart {
                var detail = describe(c.input)
                if chart.lunarYear != c.output.chart.lunarYear || chart.lunarMonth != c.output.chart.lunarMonth
                    || chart.lunarDay != c.output.chart.lunarDay || chart.isLeapMonth != c.output.chart.isLeapMonth {
                    detail += " 음력 불일치: \(chart.lunarYear)/\(chart.lunarMonth)/\(chart.lunarDay) vs \(c.output.chart.lunarYear)/\(c.output.chart.lunarMonth)/\(c.output.chart.lunarDay)"
                } else if chart.mingGongZhi != c.output.chart.mingGongZhi {
                    detail += " 명궁 불일치: \(chart.mingGongZhi) vs \(c.output.chart.mingGongZhi)"
                } else if chart.wuXingJu != c.output.chart.wuXingJu {
                    detail += " 오행국 불일치: \(chart.wuXingJu.name) vs \(c.output.chart.wuXingJu.name)"
                } else {
                    for name in chart.palaces.keys.sorted() where chart.palaces[name] != c.output.chart.palaces[name] {
                        detail += " [\(name)궁] \(chart.palaces[name]!.stars.map(\.name)) vs \(c.output.chart.palaces[name]!.stars.map(\.name))"
                        break
                    }
                }
                failures.append(detail)
            }
        }
        XCTAssertEqual(failures.count, 0, "명반 불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }

    func test유년_골든픽스처_전건일치() throws {
        var failures: [String] = []
        for c in Self.fixture.cases {
            let chart = try ZiweiEngine.createChart(
                year: c.input.y, month: c.input.m, day: c.input.d,
                hour: c.input.h, minute: c.input.min, isMale: c.input.isMale
            )
            let liunian = ZiweiEngine.calculateLiunian(chart: chart, year: Self.fixture.referenceYear)
            if liunian != c.output.liunian {
                failures.append(describe(c.input))
            }
        }
        XCTAssertEqual(failures.count, 0, "유년 불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }

    func test대한_골든픽스처_전건일치() throws {
        var failures: [String] = []
        for c in Self.fixture.cases {
            let chart = try ZiweiEngine.createChart(
                year: c.input.y, month: c.input.m, day: c.input.d,
                hour: c.input.h, minute: c.input.min, isMale: c.input.isMale
            )
            let list = ZiweiEngine.daxianList(chart: chart)
            if list != c.output.daxianList {
                failures.append(describe(c.input))
            }
        }
        XCTAssertEqual(failures.count, 0, "대한 불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }
}
