// 골든 픽스처 검증 — 라이선스 클린 천체력 (VSOP87B + Meeus + JPL)
//
// 기준 픽스처는 기존 웹 엔진(Moshier 이론)으로 생성됐고 새 구현은 다른 이론을 쓰므로
// 비트 일치가 아닌 천문학적 허용오차로 검증한다:
//   행성 0.01° / 달 0.02° / 키론 0.03° / 커스프·축 0.05°
//   별자리·하우스·역행·어스펙트는 경계 슬랙을 두고 동일성 확인

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
            fatalError("natal.json 리소스 없음")
        }
        do {
            return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
        } catch {
            fatalError("natal.json 디코딩 실패: \(error)")
        }
    }()

    // 천체별 황경 허용오차 (deg)
    private static func lonTolerance(_ id: String) -> Double {
        switch id {
        case "Moon": return 0.02
        case "Chiron": return 0.03
        case "Fortuna": return 0.07   // ASC + 달 - 태양 합성
        default: return 0.01
        }
    }
    private static let cuspTolerance = 0.05
    private static let aspectMaxOrbs: [String: Double] = [
        "conjunction": 8, "sextile": 6, "square": 8, "trine": 8, "opposition": 8,
    ]
    private static let aspectAngles: [String: Double] = [
        "conjunction": 0, "sextile": 60, "square": 90, "trine": 120, "opposition": 180,
    ]

    private func angleDiff(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
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

    func test출생차트_골든픽스처_허용오차일치() throws {
        var failures: [String] = []
        var maxDiffByBody: [String: Double] = [:]
        var maxCuspDiff = 0.0

        for c in Self.fixture.cases {
            if c.output.error != nil {
                do {
                    _ = try NatalEngine.calculateNatal(makeInput(c.input))
                    failures.append("\(describe(c.input)) [\(c.tag)]: 에러를 던져야 하는데 성공함")
                } catch { /* 정답 */ }
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
            let expCusps = c.output.houses ?? []

            // 행성: 황경 허용오차 + 별자리/하우스/역행 (경계 슬랙)
            if chart.planets.count != expPlanets.count {
                failures.append("\(describe(c.input)): 행성 수 \(chart.planets.count) vs \(expPlanets.count)")
                continue
            }
            for (got, exp) in zip(chart.planets, expPlanets) {
                guard got.id == exp.id else {
                    failures.append("\(describe(c.input)): 행성 순서 \(got.id) vs \(exp.id)")
                    break
                }
                let tol = Self.lonTolerance(got.id)
                let diff = angleDiff(got.longitude, exp.longitude)
                maxDiffByBody[got.id] = max(maxDiffByBody[got.id] ?? 0, diff)
                if diff > tol {
                    failures.append("\(describe(c.input)): \(got.id) 황경 차이 \(String(format: "%.4f", diff))° (\(got.longitude) vs \(exp.longitude))")
                    break
                }
                // 별자리: 기대 황경이 경계에서 tol 안이면 슬랙
                if got.sign != exp.sign {
                    let toBoundary = abs(exp.longitude.truncatingRemainder(dividingBy: 30))
                    let boundaryDist = min(toBoundary, 30 - toBoundary)
                    if boundaryDist > tol {
                        failures.append("\(describe(c.input)): \(got.id) 별자리 \(got.sign) vs \(exp.sign) (경계距 \(String(format: "%.3f", boundaryDist))°)")
                        break
                    }
                }
                // 하우스: 기대 황경이 커스프에서 (tol+커스프tol) 안이면 슬랙
                if got.house != exp.house {
                    let nearCusp = expCusps.contains { angleDiff(exp.longitude, $0) <= tol + Self.cuspTolerance }
                    if !nearCusp {
                        failures.append("\(describe(c.input)): \(got.id) 하우스 \(String(describing: got.house)) vs \(String(describing: exp.house))")
                        break
                    }
                }
                // 역행: 정류(stationary) 부근만 슬랙
                if got.isRetrograde != exp.retrograde && abs(got.speed) > 0.02 {
                    failures.append("\(describe(c.input)): \(got.id) 역행 \(got.isRetrograde) vs \(exp.retrograde) (speed \(got.speed))")
                    break
                }
            }

            // 하우스 커스프
            if !expCusps.isEmpty {
                let gotCusps = chart.houses.map(\.cuspLongitude)
                if gotCusps.count == expCusps.count {
                    for (got, exp) in zip(gotCusps, expCusps) {
                        let d = angleDiff(got, exp)
                        maxCuspDiff = max(maxCuspDiff, d)
                        if d > Self.cuspTolerance {
                            failures.append("\(describe(c.input)): 커스프 차이 \(String(format: "%.4f", d))° (\(got) vs \(exp))")
                            break
                        }
                    }
                } else {
                    failures.append("\(describe(c.input)): 하우스 수 \(gotCusps.count) vs \(expCusps.count)")
                }
            }

            // 4대 축
            if let expAngles = c.output.angles {
                guard let gotAngles = chart.angles else {
                    failures.append("\(describe(c.input)): angles 누락")
                    continue
                }
                if angleDiff(gotAngles.asc.longitude, expAngles.asc) > Self.cuspTolerance {
                    failures.append("\(describe(c.input)): ASC \(gotAngles.asc.longitude) vs \(expAngles.asc)")
                }
                if angleDiff(gotAngles.mc.longitude, expAngles.mc) > Self.cuspTolerance {
                    failures.append("\(describe(c.input)): MC \(gotAngles.mc.longitude) vs \(expAngles.mc)")
                }
            } else if chart.angles != nil {
                failures.append("\(describe(c.input)): angles는 null이어야 함 (시간미상)")
            }

            // 어스펙트 — orb 경계 슬랙: 기대 황경으로 재계산한 orb가 maxOrb±0.06 안이면 허용
            if let expAspects = c.output.aspects {
                let expLon = Dictionary(uniqueKeysWithValues: expPlanets.map { ($0.id, $0.longitude) })
                let gotKeys = Dictionary(uniqueKeysWithValues: chart.aspects.map { ("\($0.planet1)|\($0.planet2)|\($0.type)", $0.orb) })
                let expKeys = Dictionary(uniqueKeysWithValues: expAspects.map { ("\($0.p1)|\($0.p2)|\($0.type)", $0.orb) })

                func nearOrbBoundary(_ key: String) -> Bool {
                    let parts = key.split(separator: "|").map(String.init)
                    guard parts.count == 3,
                          let l1 = expLon[parts[0]], let l2 = expLon[parts[1]],
                          let angle = Self.aspectAngles[parts[2]],
                          let maxOrb = Self.aspectMaxOrbs[parts[2]] else { return false }
                    let orb = abs(angleDiff(l1, l2) - angle)
                    return abs(orb - maxOrb) <= 0.06
                }

                for key in Set(expKeys.keys).subtracting(gotKeys.keys) where !nearOrbBoundary(key) {
                    failures.append("\(describe(c.input)): 어스펙트 누락 \(key)")
                    break
                }
                for key in Set(gotKeys.keys).subtracting(expKeys.keys) where !nearOrbBoundary(key) {
                    failures.append("\(describe(c.input)): 어스펙트 초과 \(key)")
                    break
                }
                for (key, expOrb) in expKeys {
                    if let gotOrb = gotKeys[key], abs(gotOrb - expOrb) > 0.15 {
                        failures.append("\(describe(c.input)): \(key) orb \(gotOrb) vs \(expOrb)")
                        break
                    }
                }
            }
        }

        let stats = maxDiffByBody.sorted { $0.key < $1.key }
            .map { "\($0.key)=\(String(format: "%.4f", $0.value))°" }
            .joined(separator: ", ")
        print("📐 최대 황경 차이: \(stats) / 커스프 최대 \(String(format: "%.4f", maxCuspDiff))°")

        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 10건:\n" + failures.prefix(10).joined(separator: "\n"))
    }
}
