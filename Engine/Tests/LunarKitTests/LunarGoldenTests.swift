// 골든 픽스처 검증 — saju-api TS 엔진의 출력과 비트 단위 일치 확인
// 픽스처 출처: saju-api/tests/golden/fixtures/lunar-conversion.json (npm run golden)

import XCTest
@testable import LunarKit

final class LunarGoldenTests: XCTestCase {
    struct Fixture: Decodable {
        // solarToLunar: [sy, sm, sd, ly, lm, ld, isLeap] — lunar-javascript 기준
        let solarToLunar: [[Int]]
        // lunarToSolar: [ly, lm, ld, isLeap, sy, sm, sd] — ft-lib 테이블 기준
        let lunarToSolar: [[Int]]
    }

    static let fixture: Fixture = {
        guard let url = Bundle.module.url(forResource: "lunar-conversion", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let fixture = try? JSONDecoder().decode(Fixture.self, from: data)
        else { fatalError("lunar-conversion.json 픽스처 로드 실패") }
        return fixture
    }()

    func test양력에서음력_골든픽스처_전건일치() throws {
        var failures: [String] = []
        for c in Self.fixture.solarToLunar {
            let result = try LunarConverter.solarToLunar(year: c[0], month: c[1], day: c[2])
            let expected = LunarDate(year: c[3], month: c[4], day: c[5], isLeapMonth: c[6] == 1)
            if result != expected {
                failures.append("양력 \(c[0])-\(c[1])-\(c[2]): 기대 \(expected) 실제 \(result)")
            }
        }
        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }

    func test음력에서양력_레거시테이블_전건일치() throws {
        var failures: [String] = []
        for c in Self.fixture.lunarToSolar {
            let result = try LegacyLunarConverter.lunarToSolar(year: c[0], month: c[1], day: c[2], isLeapMonth: c[3] == 1)
            let expected = SolarDate(year: c[4], month: c[5], day: c[6])
            if result != expected {
                failures.append("음력 \(c[0])/\(c[1])/\(c[2])\(c[3] == 1 ? "윤" : ""): 기대 \(expected) 실제 \(result)")
            }
        }
        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }

    func test음력에서양력_테이블_왕복변환() throws {
        // solarToLunar 픽스처를 역방향으로: 음력 → 양력이 원래 양력 날짜로 복원되는지
        var failures: [String] = []
        for c in Self.fixture.solarToLunar {
            let solar = try LunarConverter.lunarToSolar(year: c[3], month: c[4], day: c[5], isLeapMonth: c[6] == 1)
            if solar != SolarDate(year: c[0], month: c[1], day: c[2]) {
                failures.append("음력 \(c[3])/\(c[4])/\(c[5]): 기대 \(c[0])-\(c[1])-\(c[2]) 실제 \(solar)")
            }
        }
        XCTAssertEqual(failures.count, 0, "왕복 불일치 \(failures.count)건 — 처음 5건:\n" + failures.prefix(5).joined(separator: "\n"))
    }

    func test범위밖_에러() {
        XCTAssertThrowsError(try LunarConverter.solarToLunar(year: 1850, month: 1, day: 1))
        XCTAssertThrowsError(try LegacyLunarConverter.lunarToSolar(year: 1899, month: 1, day: 1, isLeapMonth: false))
    }

    func test존재하지않는윤달_에러() {
        // 2023년 윤달은 2월 — 윤5월 요청은 에러
        XCTAssertThrowsError(try LunarConverter.lunarToSolar(year: 2023, month: 5, day: 1, isLeapMonth: true))
    }
}
