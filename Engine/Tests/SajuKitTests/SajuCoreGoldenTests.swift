// 골든 픽스처 검증 — saju-core.json 1,001건
// 절기/자시/서머타임/균시차/윤달 경계 포함 사주팔자 완전 일치 확인

import XCTest
@testable import SajuKit

final class SajuCoreGoldenTests: XCTestCase {
    struct Fixture: Decodable {
        struct Input: Decodable {
            let y: Int, m: Int, d: Int
            let h: Int?
            let min: Int
            let gender: String
            let calendar: String
            let leap: Bool
            let trueSolar: Bool
            let region: String
            let tag: String
        }
        struct Output: Decodable {
            struct Pillars: Decodable {
                let year: String?
                let month: String?
                let day: String?
                let hour: String?
            }
            struct Elements: Decodable {
                let counts: [String: Int]
                let dominant: String
                let weakest: String
                let total: Int
            }
            let pillars: Pillars
            let elements: Elements
            let dayMaster: String
            let animal: String
            let energyFlow: String
        }
        struct Case: Decodable {
            let input: Input
            let output: Output
        }
        let cases: [Case]
    }

    static let fixture: Fixture = {
        guard let url = Bundle.module.url(forResource: "saju-core", withExtension: "json") else {
            fatalError("saju-core.json 리소스 없음")
        }
        do {
            return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
        } catch {
            fatalError("saju-core.json 디코딩 실패: \(error)")
        }
    }()

    private func pillarStr(_ p: UIPillar?) -> String? {
        guard let p else { return nil }
        return "\(p.stem.hanja)\(p.branch.hanja)"
    }

    func test사주팔자_골든픽스처_전건일치() throws {
        var failures: [String] = []
        for c in Self.fixture.cases {
            let input = c.input
            let r: FortuneTellerResult
            do {
                r = try SajuCalculator.calculate(
                    year: input.y, month: input.m, day: input.d,
                    hour: input.h, gender: input.gender,
                    calendar: input.calendar, isLeapMonth: input.leap,
                    useTrueSolarTime: input.trueSolar, region: input.region,
                    minute: input.min
                )
            } catch {
                failures.append("\(input.y)-\(input.m)-\(input.d) [\(input.tag)]: 에러 \(error)")
                continue
            }

            let desc = "\(input.y)-\(input.m)-\(input.d) \(input.h.map(String.init) ?? "?"):\(input.min) \(input.calendar)\(input.leap ? "윤" : "") \(input.trueSolar ? "진태양" : "") \(input.region) [\(input.tag)]"

            if pillarStr(r.pillars.year) != c.output.pillars.year
                || pillarStr(r.pillars.month) != c.output.pillars.month
                || pillarStr(r.pillars.day) != c.output.pillars.day
                || pillarStr(r.pillars.hour) != c.output.pillars.hour {
                failures.append("\(desc): 기둥 \(pillarStr(r.pillars.year) ?? "")/\(pillarStr(r.pillars.month) ?? "")/\(pillarStr(r.pillars.day) ?? "")/\(pillarStr(r.pillars.hour) ?? "nil") vs \(c.output.pillars.year ?? "")/\(c.output.pillars.month ?? "")/\(c.output.pillars.day ?? "")/\(c.output.pillars.hour ?? "nil")")
                continue
            }
            if r.elements.counts != c.output.elements.counts
                || r.elements.dominant != c.output.elements.dominant
                || r.elements.weakest != c.output.elements.weakest
                || r.elements.total != c.output.elements.total {
                failures.append("\(desc): 오행 \(r.elements.counts) vs \(c.output.elements.counts)")
                continue
            }
            if r.dayMaster.hanja != c.output.dayMaster {
                failures.append("\(desc): 일간 \(r.dayMaster.hanja) vs \(c.output.dayMaster)")
                continue
            }
            if r.animal != c.output.animal {
                failures.append("\(desc): 띠 \(r.animal) vs \(c.output.animal)")
                continue
            }
            if r.energyFlow != c.output.energyFlow {
                failures.append("\(desc): 운행 \(r.energyFlow) vs \(c.output.energyFlow)")
                continue
            }
        }
        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 10건:\n" + failures.prefix(10).joined(separator: "\n"))
    }
}
