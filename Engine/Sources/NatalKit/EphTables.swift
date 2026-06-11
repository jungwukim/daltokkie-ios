// 천체력 수치 테이블 로더 — natal-tables.json
// (saju-api generate-natal-tables.ts가 TS 원본에서 자동 추출, 손 전사 금지)

import Foundation

struct PlanetTable: Decodable, Sendable {
    let maxHarmonic: [Int]
    let maxPowerOfT: Int
    let argTbl: [Int]
    let lonTbl: [Double]
    let latTbl: [Double]
    let radTbl: [Double]
    let distance: Double
}

struct EphTables: Decodable, Sendable {
    struct DeltaTTables: Decodable, Sendable {
        let dt: [Double]
        let dtcf16: [[Double]]
    }
    struct NutationTables: Decodable, Sendable {
        let terms: [Double]   // ENDMARK = 9999
    }
    struct PlanetTables: Decodable, Sendable {
        let mer404: PlanetTable
        let ven404: PlanetTable
        let ear404: PlanetTable
        let mar404: PlanetTable
        let jup404: PlanetTable
        let sat404: PlanetTable
        let ura404: PlanetTable
        let nep404: PlanetTable
        let plu404: PlanetTable

        var ordered: [PlanetTable] {
            [mer404, ven404, ear404, mar404, jup404, sat404, ura404, nep404, plu404]
        }
    }
    struct MoonTables: Decodable, Sendable {
        let Z: [Double]
        let NLR: Int
        let LR: [Double]
        let NMB: Int
        let MB: [Double]
        let NLRT: Int
        let LRT: [Double]
        let NBT: Int
        let BT: [Double]
        let NLRT2: Int
        let LRT2: [Double]
        let NBT2: Int
        let BT2: [Double]
    }
    struct ChironTables: Decodable, Sendable {
        let jdStart: Double
        let jdStep: Double
        let n: Int
        let lon: [Double]
        let speed: [Double]
    }

    let deltat: DeltaTTables
    let nutation: NutationTables
    let planets: PlanetTables
    let moon: MoonTables
    let chiron: ChironTables

    static let shared: EphTables = {
        guard let url = Bundle.module.url(forResource: "natal-tables", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tables = try? JSONDecoder().decode(EphTables.self, from: data)
        else { fatalError("NatalKit: natal-tables.json 리소스 로드 실패") }
        return tables
    }()
}
