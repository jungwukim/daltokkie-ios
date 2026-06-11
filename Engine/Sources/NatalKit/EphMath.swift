// NatalKit — Moshier 천체력 (saju-api lib/natal/ephemeris 포팅)
// 수학 유틸 + 율리우스일. 부동소수점 연산 순서를 TS 원본과 동일하게 유지한다.
//
// 원본 출처: Swiss Ephemeris (AGPL) 유래 Moshier 이론 구현.

import Foundation

enum Eph {
    static let TWOPI = 2 * Double.pi
    static let DEG_TO_RAD = Double.pi / 180
    static let RAD_TO_DEG = 180 / Double.pi
    static let J2000 = 2451545.0

    static func degnorm(_ x: Double) -> Double {
        var y = x.truncatingRemainder(dividingBy: 360.0)
        if abs(y) < 1e-13 { y = 0 }
        if y < 0.0 { y += 360.0 }
        return y
    }

    static func mods3600(_ x: Double) -> Double {
        x - 1296000.0 * floor(x / 1296000.0)
    }

    /// 율리우스일 (UT). TS julian.ts와 동일 알고리즘.
    static func julday(_ year: Int, _ month: Int, _ day: Int, _ hour: Double) -> Double {
        var u = Double(year)
        if month < 3 { u -= 1 }
        let u0 = u + 4712.0
        var u1 = Double(month) + 1.0
        if u1 < 4 { u1 += 12.0 }
        var jd = floor(u0 * 365.25)
            + floor(30.6 * u1 + 0.000001)
            + Double(day) + hour / 24.0 - 63.5
        var u2 = floor(abs(u) / 100) - floor(abs(u) / 400)
        if u < 0.0 { u2 = -u2 }
        jd = jd - u2 + 2
        if u < 0.0 && u / 100 == floor(u / 100) && u / 400 != floor(u / 400) {
            jd -= 1
        }
        return jd
    }

    /// 직교 → 극좌표 (속도 포함 6원소 또는 3원소)
    static func cartpol(_ x: [Double]) -> [Double] {
        let r2 = x[0] * x[0] + x[1] * x[1]
        let rr = r2 + x[2] * x[2]
        var result = [Double](repeating: 0, count: x.count)

        if r2 == 0 && x[2] == 0 {
            result[0] = 0
        } else {
            result[0] = atan2(x[1], x[0])
            if result[0] < 0 { result[0] += TWOPI }
        }

        result[1] = x[2] == 0 ? 0 : atan(x[2] / sqrt(r2))
        result[2] = sqrt(rr)

        if x.count >= 6 {
            let sqr2 = sqrt(r2)
            if sqr2 > 0 {
                result[3] = (x[0] * x[4] - x[1] * x[3]) / r2
                result[4] = (x[2] * (x[0] * x[3] + x[1] * x[4]) - r2 * x[5]) / (rr * sqr2) * -1
            } else {
                result[3] = 0
                result[4] = 0
            }
            result[5] = rr > 0 ? (x[0] * x[3] + x[1] * x[4] + x[2] * x[5]) / sqrt(rr) : 0
        }
        return result
    }

    /// 극 → 직교좌표
    static func polcart(_ l: [Double]) -> [Double] {
        var result = [Double](repeating: 0, count: l.count)
        let cosB = cos(l[1]), sinB = sin(l[1])
        let cosL = cos(l[0]), sinL = sin(l[0])

        result[0] = l[2] * cosB * cosL
        result[1] = l[2] * cosB * sinL
        result[2] = l[2] * sinB

        if l.count >= 6 {
            result[3] = l[5] * cosB * cosL - l[2] * sinB * cosL * l[4] - l[2] * cosB * sinL * l[3]
            result[4] = l[5] * cosB * sinL - l[2] * sinB * sinL * l[4] + l[2] * cosB * cosL * l[3]
            result[5] = l[5] * sinB + l[2] * cosB * l[4]
        }
        return result
    }

    /// 황도↔적도 회전 (6원소)
    static func coortrf2(_ x: [Double], _ eps: Double) -> [Double] {
        let cosEps = cos(eps), sinEps = sin(eps)
        return [
            x[0],
            x[1] * cosEps + x[2] * sinEps,
            -x[1] * sinEps + x[2] * cosEps,
            x[3],
            x[4] * cosEps + x[5] * sinEps,
            -x[4] * sinEps + x[5] * cosEps,
        ]
    }

    /// 평균 황도경사 (라디안)
    static func calcObliquity(_ tjd: Double) -> Double {
        let T = (tjd - J2000) / 36525.0
        return (((1.813e-3 * T - 5.9e-4) * T - 46.8150) * T + 84381.448) * DEG_TO_RAD / 3600
    }

    /// 세차운동 보정 — R의 처음 3개 원소를 제자리 변환
    static func precess(_ R: inout [Double], _ J: Double, _ direction: Int) {
        let T = (J - J2000) / 36525.0

        let Z = (((((-0.0000002 * T - 0.0000327) * T + 0.0179663) * T
            + 0.3019015) * T + 2306.2181) * T + 0.0) * DEG_TO_RAD / 3600
        let z = (((((-0.0000003 * T - 0.000047) * T + 0.0182237) * T
            + 1.0947790) * T + 2306.2181) * T + 0.0) * DEG_TO_RAD / 3600
        let TH = ((((-0.0000001 * T - 0.0000601) * T - 0.0418251) * T
            - 0.4269353) * T + 2004.3109) * T * DEG_TO_RAD / 3600

        let sinTH = sin(TH), cosTH = cos(TH)
        let sinZ = sin(Z), cosZ = cos(Z)
        let sinz = sin(z), cosz = cos(z)
        let A = cosZ * cosTH
        let B = sinZ * cosTH

        var x = [Double](repeating: 0, count: 3)
        if direction < 0 {
            x[0] = (A * cosz - sinZ * sinz) * R[0] - (B * cosz + cosZ * sinz) * R[1] - sinTH * cosz * R[2]
            x[1] = (A * sinz + sinZ * cosz) * R[0] - (B * sinz - cosZ * cosz) * R[1] - sinTH * sinz * R[2]
            x[2] = cosZ * sinTH * R[0] - sinZ * sinTH * R[1] + cosTH * R[2]
        } else {
            x[0] = (A * cosz - sinZ * sinz) * R[0] + (A * sinz + sinZ * cosz) * R[1] + cosZ * sinTH * R[2]
            x[1] = -(B * cosz + cosZ * sinz) * R[0] - (B * sinz - cosZ * cosz) * R[1] - sinZ * sinTH * R[2]
            x[2] = -sinTH * cosz * R[0] - sinTH * sinz * R[1] + cosTH * R[2]
        }
        R[0] = x[0]
        R[1] = x[1]
        R[2] = x[2]
    }
}
