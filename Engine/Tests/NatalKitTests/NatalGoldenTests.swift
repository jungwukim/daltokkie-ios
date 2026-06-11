// 골든 픽스처 검증 — saju-api lib/natal 엔진 출력과 일치 확인
// 픽스처: saju-api/tests/golden/fixtures/natal.json (408건)
// 비교 규칙: 천체 각도 ε=0.001°, 그 외(부호/역행/하우스/어스펙트 구성)는 완전 일치

import XCTest
@testable import NatalKit

final class NatalGoldenTests: XCTestCase {
    struct Fixture: Decodable {
        struct Input: Decodable {
            let year: Int, month: Int, day: Int, hour: Int, minute: Int
            let latitude: Double?
            let longitude: Double?
            let timezone: String
            let unknownTime: Bool?
        }
        struct FPlanet: Decodable {
            let id: String
            let longitude: Double
            let sign: String
            let retrograde: Bool
            let house: Int?
        }
        struct FAngles: Decodable {
            let asc: Double
            let mc: Double
        }
        struct FAspect: Decodable {
            let type: String
            let p1: String
            let p2: String
            let orb: Double
        }
        struct Output: Decodable {
            let error: String?
            let planets: [FPlanet]?
            let houses: [Double]?
            let angles: FAngles?
            let aspects: [FAspect]?
        }
        struct Case: Decodable {
            let input: Input
            let tag: String
            let output: Output
        }
        let cases: [Case]
    }

    static let fixture: Fixture = {
        guard let url = Bundle.module.url(forResource: "natal", withExtension: "json") else {
            fatalError("natal.json 리소스 없음 — 번들 내용: \(Bundle.module.paths(forResourcesOfType: "json", inDirectory: nil))")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Fixture.self, from: data)
        } catch {
            fatalError("natal.json 디코딩 실패: \(error)")
        }
    }()

    private static let epsilon = 0.001

    private func angleClose(_ a: Double, _ b: Double) -> Bool {
        let d = abs(a - b)
        return min(d, 360 - d) < Self.epsilon
    }

    private func describe(_ input: Fixture.Input) -> String {
        "\(input.year)-\(input.month)-\(input.day) \(input.hour):\(input.minute) \(input.timezone)"
    }

    private func makeInput(_ input: Fixture.Input) -> NatalInput {
        NatalInput(
            year: input.year, month: input.month, day: input.day,
            hour: input.hour, minute: input.minute,
            latitude: input.latitude, longitude: input.longitude,
            unknownTime: input.unknownTime ?? false,
            timezone: input.timezone
        )
    }

    func test출생차트_골든픽스처_전건일치() throws {
        var failures: [String] = []

        for c in Self.fixture.cases {
            // 에러 케이스(DST gap): throw가 정답
            if c.output.error != nil {
                do {
                    _ = try NatalEngine.calculateNatal(makeInput(c.input))
                    failures.append("\(describe(c.input)) [\(c.tag)]: 에러를 던져야 하는데 성공함")
                } catch {
                    // 정답
                }
                continue
            }

            let chart: NatalChart
            do {
                chart = try NatalEngine.calculateNatal(makeInput(c.input))
            } catch {
                failures.append("\(describe(c.input)) [\(c.tag)]: 예기치 않은 에러 \(error)")
                continue
            }

            guard let expPlanets = c.output.planets else { continue }

            // 행성
            if chart.planets.count != expPlanets.count {
                failures.append("\(describe(c.input)) [\(c.tag)]: 행성 수 \(chart.planets.count) vs \(expPlanets.count)")
                continue
            }
            for (got, exp) in zip(chart.planets, expPlanets) {
                if got.id != exp.id {
                    failures.append("\(describe(c.input)): 행성 순서 \(got.id) vs \(exp.id)")
                    break
                }
                if !angleClose(got.longitude, exp.longitude) {
                    failures.append("\(describe(c.input)): \(got.id) 황경 \(got.longitude) vs \(exp.longitude)")
                    break
                }
                if got.sign != exp.sign {
                    failures.append("\(describe(c.input)): \(got.id) 별자리 \(got.sign) vs \(exp.sign)")
                    break
                }
                if got.isRetrograde != exp.retrograde {
                    failures.append("\(describe(c.input)): \(got.id) 역행 \(got.isRetrograde) vs \(exp.retrograde)")
                    break
                }
                if got.house != exp.house {
                    failures.append("\(describe(c.input)): \(got.id) 하우스 \(String(describing: got.house)) vs \(String(describing: exp.house))")
                    break
                }
            }

            // 하우스 커스프
            if let expHouses = c.output.houses {
                let gotCusps = chart.houses.map(\.cuspLongitude)
                if gotCusps.count != expHouses.count {
                    failures.append("\(describe(c.input)): 하우스 수 \(gotCusps.count) vs \(expHouses.count)")
                } else {
                    for (i, (got, exp)) in zip(gotCusps, expHouses).enumerated() where !angleClose(got, exp) {
                        failures.append("\(describe(c.input)): 커스프\(i + 1) \(got) vs \(exp)")
                        break
                    }
                }
            }

            // 4대 축
            if let expAngles = c.output.angles {
                guard let gotAngles = chart.angles else {
                    failures.append("\(describe(c.input)): angles 누락")
                    continue
                }
                if !angleClose(gotAngles.asc.longitude, expAngles.asc) {
                    failures.append("\(describe(c.input)): ASC \(gotAngles.asc.longitude) vs \(expAngles.asc)")
                }
                if !angleClose(gotAngles.mc.longitude, expAngles.mc) {
                    failures.append("\(describe(c.input)): MC \(gotAngles.mc.longitude) vs \(expAngles.mc)")
                }
            } else if chart.angles != nil {
                failures.append("\(describe(c.input)): angles는 null이어야 함 (시간미상)")
            }

            // 어스펙트 — (p1,p2,type) 집합 일치 + orb 오차 ≤0.1
            if let expAspects = c.output.aspects {
                let gotKeys = Dictionary(uniqueKeysWithValues: chart.aspects.map { ("\($0.planet1)|\($0.planet2)|\($0.type)", $0.orb) })
                let expKeys = Dictionary(uniqueKeysWithValues: expAspects.map { ("\($0.p1)|\($0.p2)|\($0.type)", $0.orb) })
                if Set(gotKeys.keys) != Set(expKeys.keys) {
                    let missing = Set(expKeys.keys).subtracting(gotKeys.keys)
                    let extra = Set(gotKeys.keys).subtracting(expKeys.keys)
                    failures.append("\(describe(c.input)): 어스펙트 차이 — 누락 \(missing.prefix(2)), 초과 \(extra.prefix(2))")
                } else {
                    for (key, expOrb) in expKeys where abs(gotKeys[key]! - expOrb) > 0.11 {
                        failures.append("\(describe(c.input)): \(key) orb \(gotKeys[key]!) vs \(expOrb)")
                        break
                    }
                }
            }
        }

        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 10건:\n" + failures.prefix(10).joined(separator: "\n"))
    }
}
