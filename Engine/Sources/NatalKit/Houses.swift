// 하우스 커스프 계산 — houses.ts 포팅
// 앱은 Placidus("P")만 사용. 극지방 폴백용 Porphyrius("O") 포함.

import Foundation

struct HousesResult {
    let cusps: [Double]   // [1...12] 사용 (인덱스 0 미사용)
    let ascmc: [Double]   // [0]=ASC, [1]=MC, [2]=ARMC
}

enum Houses {
    private static let VERY_SMALL = 1e-10

    private static func sind(_ x: Double) -> Double { sin(x * Eph.DEG_TO_RAD) }
    private static func cosd(_ x: Double) -> Double { cos(x * Eph.DEG_TO_RAD) }
    private static func tand(_ x: Double) -> Double { tan(x * Eph.DEG_TO_RAD) }
    private static func asind(_ x: Double) -> Double { asin(x) * Eph.RAD_TO_DEG }
    private static func atand(_ x: Double) -> Double { atan(x) * Eph.RAD_TO_DEG }

    private static func clamp1(_ x: Double) -> Double {
        if x > 1 { return 1 }
        if x < -1 { return -1 }
        return x
    }

    // MARK: - ASC 보조 함수

    private static func asc1(_ x1in: Double, _ f: Double, _ sine: Double, _ cose: Double) -> Double {
        let x1 = Eph.degnorm(x1in)
        let n = Int(floor(x1 / 90)) + 1
        if abs(90 - f) < VERY_SMALL { return 180 }
        if abs(90 + f) < VERY_SMALL { return 0 }
        var ass: Double
        if n == 1 {
            ass = asc2(x1, f, sine, cose)
        } else if n == 2 {
            ass = 180 - asc2(180 - x1, -f, sine, cose)
        } else if n == 3 {
            ass = 180 + asc2(x1 - 180, -f, sine, cose)
        } else {
            ass = 360 - asc2(360 - x1, f, sine, cose)
        }
        ass = Eph.degnorm(ass)
        if abs(ass - 90) < VERY_SMALL { ass = 90 }
        if abs(ass - 180) < VERY_SMALL { ass = 180 }
        if abs(ass - 270) < VERY_SMALL { ass = 270 }
        if abs(ass - 360) < VERY_SMALL { ass = 0 }
        return ass
    }

    private static func asc2(_ x: Double, _ f: Double, _ sine: Double, _ cose: Double) -> Double {
        var ass = -tand(f) * sine + cose * cosd(x)
        if abs(ass) < VERY_SMALL { ass = 0 }
        var sinx = sind(x)
        if abs(sinx) < VERY_SMALL { sinx = 0 }
        if sinx == 0 {
            ass = (ass < 0) ? -VERY_SMALL : VERY_SMALL
        } else if ass == 0 {
            ass = (sinx < 0) ? -90 : 90
        } else {
            ass = atand(sinx / ass)
        }
        if ass < 0 { ass = 180 + ass }
        return ass
    }

    /// p1 - p2 정규화 차이, (-180, 180]
    private static func difdeg2n(_ p1: Double, _ p2: Double) -> Double {
        var d = Eph.degnorm(p1 - p2)
        if d > 180 { d -= 360 }
        return d
    }

    // MARK: - 항성시 (IAU 1976)

    private static func sidtime0(_ tjdUt: Double, _ eps: Double, _ nut: Double) -> Double {
        let jd = tjdUt
        var jd0 = floor(jd)
        var secs = tjdUt - jd0
        if secs < 0.5 {
            jd0 -= 0.5
            secs += 0.5
        } else {
            jd0 += 0.5
            secs -= 0.5
        }
        secs *= 86400.0
        let tu = (jd0 - 2451545.0) / 36525.0
        var gmst = ((-6.2e-6 * tu + 9.3104e-2) * tu + 8640184.812866) * tu + 24110.54841
        let msday = 1.0 + ((-1.86e-5 * tu + 0.186208) * tu + 8640184.812866) / (86400 * 36525)
        gmst += msday * secs
        let eqeq = 240.0 * nut * cos(eps * Eph.DEG_TO_RAD)
        gmst += eqeq
        gmst = gmst - 86400.0 * floor(gmst / 86400.0)
        return gmst / 3600
    }

    // MARK: - 하우스 시스템

    private static func computeOpposites(_ cusps: inout [Double]) {
        cusps[4] = Eph.degnorm(cusps[10] + 180)
        cusps[5] = Eph.degnorm(cusps[11] + 180)
        cusps[6] = Eph.degnorm(cusps[12] + 180)
        cusps[7] = Eph.degnorm(cusps[1] + 180)
        cusps[8] = Eph.degnorm(cusps[2] + 180)
        cusps[9] = Eph.degnorm(cusps[3] + 180)
    }

    private static func housesPorphyry(_ cusps: inout [Double], _ ac: Double, _ mc: Double) {
        cusps[1] = ac
        cusps[10] = mc
        var acmc = difdeg2n(ac, mc)
        var acUsed = ac
        if acmc < 0 {
            acUsed = Eph.degnorm(ac + 180)
            acmc = difdeg2n(acUsed, mc)
        }
        cusps[11] = Eph.degnorm(mc + acmc / 3)
        cusps[12] = Eph.degnorm(mc + (acmc / 3) * 2)
        cusps[2] = Eph.degnorm(acUsed + (180 - acmc) / 3)
        cusps[3] = Eph.degnorm(acUsed + ((180 - acmc) / 3) * 2)
        computeOpposites(&cusps)
    }

    private static func placidusIter(
        _ th: Double, _ fi: Double, _ sine: Double, _ cose: Double,
        _ offset: Double, _ frac: Double, _ sign: Double
    ) -> Double {
        var x = asc1(th + offset, fi, sine, cose)
        for _ in 0..<100 {
            let dec = asind(clamp1(sind(x) * sine))
            let ad = asind(clamp1(tand(dec) * tand(fi)))
            let xNew = asc1(th + offset + sign * ad * frac, fi, sine, cose)
            if abs(xNew - x) < VERY_SMALL {
                return xNew
            }
            x = xNew
        }
        return x
    }

    private static func housesPlacidus(
        _ cusps: inout [Double],
        _ th: Double, _ fi: Double, _ ekl: Double,
        _ sine: Double, _ cose: Double,
        _ ac: Double, _ mc: Double
    ) {
        if abs(fi) >= 90 - ekl {
            housesPorphyry(&cusps, ac, mc)
            return
        }
        cusps[1] = ac
        cusps[10] = mc
        cusps[11] = placidusIter(th, fi, sine, cose, 30, 1.0 / 3, 1)
        cusps[12] = placidusIter(th, fi, sine, cose, 60, 2.0 / 3, 1)
        cusps[2] = placidusIter(th, fi, sine, cose, 120, 2.0 / 3, -1)
        cusps[3] = placidusIter(th, fi, sine, cose, 150, 1.0 / 3, -1)
        computeOpposites(&cusps)
    }

    // MARK: - 진입점

    static func calcHouses(_ tjdUt: Double, _ geolat: Double, _ geolon: Double, _ hsys: String) -> HousesResult {
        let tjde = tjdUt + DeltaT.deltaT(tjdUt)
        let epsMeanRad = Eph.calcObliquity(tjde)
        let epsMean = epsMeanRad * Eph.RAD_TO_DEG
        let (dpsi, deps) = Nutation.calcNutation(tjde)
        let nutloLon = dpsi * Eph.RAD_TO_DEG
        let nutloObl = deps * Eph.RAD_TO_DEG

        let armc = Eph.degnorm(sidtime0(tjdUt, epsMean + nutloObl, nutloLon) * 15 + geolon)

        let ekl = epsMean + nutloObl
        let cose = cos(ekl * Eph.DEG_TO_RAD)
        let sine = sin(ekl * Eph.DEG_TO_RAD)

        let th = Eph.degnorm(armc)
        var mc: Double
        if abs(th - 90) > VERY_SMALL && abs(th - 270) > VERY_SMALL {
            let tant = tan(th * Eph.DEG_TO_RAD)
            mc = atan(tant / cose) * Eph.RAD_TO_DEG
            if th > 90 && th <= 270 { mc += 180 }
        } else {
            mc = abs(th - 90) <= VERY_SMALL ? 90 : 270
        }
        mc = Eph.degnorm(mc)

        let ac = asc1(th + 90, geolat, sine, cose)

        var cusps = [Double](repeating: 0, count: 13)
        let fi = geolat

        switch hsys.uppercased() {
        case "O":
            housesPorphyry(&cusps, ac, mc)
        default:
            // 앱은 Placidus만 사용 — 그 외 시스템 코드는 Placidus로 처리
            housesPlacidus(&cusps, th, fi, ekl, sine, cose, ac, mc)
        }

        return HousesResult(cusps: cusps, ascmc: [ac, mc, armc])
    }
}
