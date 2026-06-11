// 천체 위치 이론 — VSOP87B 행성 + Meeus 달/명왕성 + JPL 키론 + 평균 교점
// (astronomia MIT 알고리즘 포팅 — NOTICE.md 참조. Swiss Ephemeris 코드 없음)

import Foundation

enum CleanBodies {

    // MARK: - VSOP87B (일심 황도 구면, J2000 분점)

    /// 반환: (L 황경 rad, B 황위 rad, R AU)
    static func vsop87(_ planet: String, jde: Double) -> (L: Double, B: Double, R: Double) {
        guard let series = CleanTables.shared.planets[planet] else {
            fatalError("VSOP87 시리즈 없음: \(planet)")
        }
        let tau = (jde - Eph.J2000) / 365250   // 율리우스 천년기

        func evaluate(_ powers: [[[Double]]]) -> Double {
            var sum = 0.0
            var tPow = 1.0
            for terms in powers {
                var inner = 0.0
                for t in terms {
                    inner += t[0] * cos(t[1] + t[2] * tau)
                }
                sum += inner * tPow
                tPow *= tau
            }
            return sum
        }

        return (Eph.radnorm(evaluate(series.L)), evaluate(series.B), evaluate(series.R))
    }

    // MARK: - 명왕성 (Meeus ch.37, 일심 황도 J2000, 1885~2099 유효)

    static func plutoHeliocentric(jde: Double) -> (L: Double, B: Double, R: Double) {
        let T = (jde - Eph.J2000) / 36525
        let J = 34.35 + 3034.9057 * T
        let S = 50.08 + 1222.1138 * T
        let P = 238.96 + 144.96 * T

        var l = 0.0, b = 0.0, r = 0.0
        for t in CleanTables.shared.pluto {
            let alpha = (t[0] * J + t[1] * S + t[2] * P) * Eph.DEG_TO_RAD
            let sa = sin(alpha), ca = cos(alpha)
            l += t[3] * sa + t[4] * ca
            b += t[5] * sa + t[6] * ca
            r += t[7] * sa + t[8] * ca
        }
        l = (l + 238.958116 + 144.96 * T) * Eph.DEG_TO_RAD
        b = (b - 3.908239) * Eph.DEG_TO_RAD
        r += 40.7241346
        return (Eph.radnorm(l), b, r)
    }

    // MARK: - 달 (Meeus ch.47 — 평균 분점 of date, 장동 미포함)

    /// 반환: (λ rad, β rad, Δ km)
    static func moonPosition(jde: Double) -> (lon: Double, lat: Double, rangeKm: Double) {
        let tbl = CleanTables.shared.moon
        let D2R = Eph.DEG_TO_RAD
        let T = (jde - Eph.J2000) / 36525

        let lp = Eph.horner(T, [218.3164477 * D2R, 481267.88123421 * D2R, -0.0015786 * D2R, D2R / 538841, -D2R / 65194000])
        let d = Eph.horner(T, [297.8501921 * D2R, 445267.1114034 * D2R, -0.0018819 * D2R, D2R / 545868, -D2R / 113065000])
        let m = Eph.horner(T, [357.5291092 * D2R, 35999.0502909 * D2R, -0.0001536 * D2R, D2R / 24490000])
        let mp = Eph.horner(T, [134.9633964 * D2R, 477198.8675055 * D2R, 0.0087414 * D2R, D2R / 69699, -D2R / 14712000])
        let f = Eph.horner(T, [93.272095 * D2R, 483202.0175233 * D2R, -0.0036539 * D2R, -D2R / 3526000, D2R / 863310000])

        let a1 = (119.75 + 131.849 * T) * D2R
        let a2 = (53.09 + 479264.29 * T) * D2R
        let a3 = (313.45 + 481266.484 * T) * D2R
        let e = Eph.horner(T, [1, -0.002516, -0.0000074])
        let e2 = e * e

        var sumL = 3958 * sin(a1) + 1962 * sin(lp - f) + 318 * sin(a2)
        var sumR = 0.0
        var sumB = -2235 * sin(lp) + 382 * sin(a3) + 175 * sin(a1 - f)
            + 175 * sin(a1 + f) + 127 * sin(lp - mp) - 115 * sin(lp + mp)

        for row in tbl.ta {
            let arg = d * row[0] + m * row[1] + mp * row[2] + f * row[3]
            let sa = sin(arg), ca = cos(arg)
            let factor: Double
            switch abs(Int(row[1])) {
            case 1: factor = e
            case 2: factor = e2
            default: factor = 1
            }
            sumL += row[4] * sa * factor
            sumR += row[5] * ca * factor
        }

        for row in tbl.tb {
            let sb = sin(d * row[0] + m * row[1] + mp * row[2] + f * row[3])
            let factor: Double
            switch abs(Int(row[1])) {
            case 1: factor = e
            case 2: factor = e2
            default: factor = 1
            }
            sumB += row[4] * sb * factor
        }

        let lon = Eph.radnorm(lp) + sumL * 1e-6 * D2R
        let lat = sumB * 1e-6 * D2R
        let rangeKm = 385000.56 + sumR * 1e-3
        return (Eph.radnorm(lon), lat, rangeKm)
    }

    // MARK: - 평균 교점 (표준 공식)

    static func meanNodeLongitude(jde: Double) -> Double {
        let T = (jde - Eph.J2000) / 36525
        let omega = 125.0445479 - 1934.1362891 * T + 0.0020754 * T * T
            + T * T * T / 467441 - T * T * T * T / 60616000
        return Eph.degnorm(omega)
    }

    // MARK: - 키론 (JPL Horizons 테이블 보간)

    static func chiron(jd: Double) throws -> (longitude: Double, speed: Double) {
        let tbl = ChironTable.shared
        let jdEnd = tbl.jdStart + Double(tbl.lon.count - 1) * tbl.jdStep
        guard jd >= tbl.jdStart, jd <= jdEnd else {
            throw NatalError.chironOutOfRange("JD \(jd) (지원: \(tbl.jdStart)~\(jdEnd))")
        }
        let fractionalIdx = (jd - tbl.jdStart) / tbl.jdStep
        let i0 = min(Int(floor(fractionalIdx)), tbl.lon.count - 2)
        let frac = fractionalIdx - Double(i0)

        let p0 = tbl.lon[i0]
        var dp = tbl.lon[i0 + 1] - p0
        if dp > 180 { dp -= 360 }
        if dp < -180 { dp += 360 }

        let lon = Eph.degnorm(p0 + dp * frac)
        let speed = dp / tbl.jdStep
        return (lon, speed)
    }
}
