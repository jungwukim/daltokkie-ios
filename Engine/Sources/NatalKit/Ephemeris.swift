// 천체 위치 통합 계산 — ephemeris/index.ts 포팅

import Foundation

struct PlanetResult {
    let longitude: Double
    let latitude: Double
    let distance: Double
    let longitudeSpeed: Double
    let latitudeSpeed: Double
    let distanceSpeed: Double
}

enum Ephemeris {
    static let SE_SUN = 0
    static let SE_MOON = 1
    static let SE_MEAN_NODE = 10
    static let SE_CHIRON = 15

    private static let bodyToIpli: [Int: Int] = [
        0: 0, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9,
    ]

    /// 장동 적용 (6원소 제자리 변환)
    private static func nutate(_ p: inout [Double], _ dpsi: Double, _ deps: Double, _ meanObliquity: Double) {
        let soe = sin(meanObliquity)
        let coe = cos(meanObliquity)
        let A = dpsi * coe
        let B = dpsi * soe

        let x0 = p[0] - A * p[1] - B * p[2]
        let x1 = A * p[0] + p[1] - deps * p[2]
        let x2 = B * p[0] + deps * p[1] + p[2]
        p[0] = x0; p[1] = x1; p[2] = x2

        if p.count >= 6 {
            let x3 = p[3] - A * p[4] - B * p[5]
            let x4 = A * p[3] + p[4] - deps * p[5]
            let x5 = B * p[3] + deps * p[4] + p[5]
            p[3] = x3; p[4] = x4; p[5] = x5
        }
    }

    /// 적도 J2000 → 황도(of date) 극좌표
    private static func equ2000ToEclDate(_ xeqIn: [Double], _ tjde: Double) -> [Double] {
        var xeq = xeqIn
        let meanEps = Eph.calcObliquity(tjde)
        let (dpsi, deps) = Nutation.calcNutation(tjde)
        let trueEps = meanEps + deps

        Eph.precess(&xeq, tjde, -1)
        if xeq.count >= 6 {
            var vel = [xeq[3], xeq[4], xeq[5]]
            Eph.precess(&vel, tjde, -1)
            xeq[3] = vel[0]; xeq[4] = vel[1]; xeq[5] = vel[2]
        }

        nutate(&xeq, dpsi, deps, meanEps)
        let eclCart = Eph.coortrf2(xeq, trueEps)
        return Eph.cartpol(eclCart)
    }

    static func julday(_ y: Int, _ m: Int, _ d: Int, _ h: Double) -> Double {
        Eph.julday(y, m, d, h)
    }

    static func calcPlanet(_ jd: Double, _ body: Int) throws -> PlanetResult {
        let tjde = jd + DeltaT.deltaT(jd)

        if body == SE_MEAN_NODE {
            let node = MeanNode.calcMeanNodeFull(tjde)
            return PlanetResult(
                longitude: node.longitude, latitude: 0, distance: 0.002569,
                longitudeSpeed: node.speed, latitudeSpeed: 0, distanceSpeed: 0
            )
        }

        if body == SE_CHIRON {
            let chiron = try Chiron.calcChiron(jd)
            return PlanetResult(
                longitude: chiron.longitude, latitude: 0, distance: 0,
                longitudeSpeed: chiron.speed, latitudeSpeed: 0, distanceSpeed: 0
            )
        }

        if body == SE_MOON {
            let xp = MoonCalculator.calcMoon(jd)
            let polar = equ2000ToEclDate(xp, tjde)
            return PlanetResult(
                longitude: Eph.degnorm(polar[0] * Eph.RAD_TO_DEG),
                latitude: polar[1] * Eph.RAD_TO_DEG,
                distance: polar[2],
                longitudeSpeed: polar[3] * Eph.RAD_TO_DEG,
                latitudeSpeed: polar[4] * Eph.RAD_TO_DEG,
                distanceSpeed: polar[5]
            )
        }

        guard let ipli = bodyToIpli[body] else {
            throw NatalError.unsupportedBody(body)
        }

        let result = PlanetCalculator.moshplan(jd, ipli)
        var xgeo = [Double](repeating: 0, count: 6)
        if body == SE_SUN {
            for i in 0..<6 { xgeo[i] = -result.xe[i] }
        } else {
            for i in 0..<6 { xgeo[i] = result.xp[i] - result.xe[i] }
        }

        let polar = equ2000ToEclDate(xgeo, tjde)
        return PlanetResult(
            longitude: Eph.degnorm(polar[0] * Eph.RAD_TO_DEG),
            latitude: polar[1] * Eph.RAD_TO_DEG,
            distance: polar[2],
            longitudeSpeed: polar[3] * Eph.RAD_TO_DEG,
            latitudeSpeed: polar[4] * Eph.RAD_TO_DEG,
            distanceSpeed: polar[5]
        )
    }
}
