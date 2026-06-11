// 평균 교점(NorthNode) + 키론 — node.ts / chiron.ts 포팅

import Foundation

enum MeanNode {
    private static let J2000 = 2451545.0

    private static func calcMeanNode(_ tjd: Double) -> Double {
        let T = (tjd - J2000) / 36525.0
        let T2 = T * T
        let T3 = T2 * T
        let T4 = T3 * T
        let omega = 125.0445479 - 1934.1362891 * T + 0.0020754 * T2 + T3 / 467441.0 - T4 / 60616000.0
        return Eph.degnorm(omega)
    }

    static func calcMeanNodeFull(_ tjd: Double) -> (longitude: Double, speed: Double) {
        let lon = calcMeanNode(tjd)
        let dt = 0.1
        let lon2 = calcMeanNode(tjd - dt)
        var speed = (lon - lon2) / dt
        if speed > 180 { speed -= 360 }
        if speed < -180 { speed += 360 }
        return (lon, speed)
    }
}

enum Chiron {
    static func calcChiron(_ tjd: Double) throws -> (longitude: Double, speed: Double) {
        let tbl = EphTables.shared.chiron
        let jdEnd = tbl.jdStart + Double(tbl.n - 1) * tbl.jdStep
        guard tjd >= tbl.jdStart, tjd <= jdEnd else {
            throw NatalError.chironOutOfRange("JD \(tjd) (지원: \(tbl.jdStart)~\(jdEnd))")
        }

        let fractionalIdx = (tjd - tbl.jdStart) / tbl.jdStep
        let i = Int(floor(fractionalIdx))
        let frac = fractionalIdx - Double(i)
        let i0 = min(i, tbl.n - 2)
        let i1 = i0 + 1

        let p0 = tbl.lon[i0]
        var dp = tbl.lon[i1] - p0
        if dp > 180 { dp -= 360 }
        if dp < -180 { dp += 360 }
        let p1u = p0 + dp

        let m0 = tbl.speed[i0] * tbl.jdStep
        let m1 = tbl.speed[i1] * tbl.jdStep

        // Hermite 보간
        let t = frac
        let t2 = t * t
        let t3 = t2 * t
        let lon = (2 * t3 - 3 * t2 + 1) * p0 + (t3 - 2 * t2 + t) * m0
            + (-2 * t3 + 3 * t2) * p1u + (t3 - t2) * m1

        let speed = ((6 * t2 - 6 * t) * p0 + (3 * t2 - 4 * t + 1) * m0
            + (-6 * t2 + 6 * t) * p1u + (3 * t2 - 2 * t) * m1) / tbl.jdStep

        var lonNorm = lon.truncatingRemainder(dividingBy: 360)
        if lonNorm < 0 { lonNorm += 360 }
        return (lonNorm, speed)
    }
}
