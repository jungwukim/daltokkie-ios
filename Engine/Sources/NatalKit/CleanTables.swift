// 천체력 데이터 로더 — clean-ephemeris.json + chiron-jpl.json
// 출처: VSOP87B(Bretagnon & Francou) + Meeus 주기항 (astronomia MIT 경유),
//       키론은 JPL Horizons (NASA/JPL, 퍼블릭 도메인)

import Foundation

struct CleanTables: Decodable, Sendable {
    struct Vsop87Series: Decodable, Sendable {
        let L: [[[Double]]]   // [power 0..5][term][A, B, C]
        let B: [[[Double]]]
        let R: [[[Double]]]
    }
    struct MoonTables: Decodable, Sendable {
        let ta: [[Double]]    // [d, m, m', f, Σl, Σr] × 60
        let tb: [[Double]]    // [d, m, m', f, Σb] × 60
    }

    let planets: [String: Vsop87Series]
    let moon: MoonTables
    let pluto: [[Double]]     // [i, j, k, lA, lB, bA, bB, rA, rB] × 43

    static let shared: CleanTables = {
        guard let url = Bundle.module.url(forResource: "clean-ephemeris", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tables = try? JSONDecoder().decode(CleanTables.self, from: data)
        else { fatalError("NatalKit: clean-ephemeris.json 로드 실패") }
        return tables
    }()
}

struct ChironTable: Decodable, Sendable {
    let jdStart: Double
    let jdStep: Double
    let lon: [Double]

    static let shared: ChironTable = {
        guard let url = Bundle.module.url(forResource: "chiron-jpl", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let table = try? JSONDecoder().decode(ChironTable.self, from: data)
        else { fatalError("NatalKit: chiron-jpl.json 로드 실패") }
        return table
    }()
}
