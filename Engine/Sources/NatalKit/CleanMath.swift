// NatalKit 클린 천체력 — 수학/시각 기초
//
// 라이선스: 이 파일의 알고리즘은 공개 천문학 표준 공식(IAU 1976/1980/1982,
// J. Meeus "Astronomical Algorithms"의 수식)과 astronomia(MIT) 포팅으로 구성.
// Swiss Ephemeris 유래 코드 없음. 자세한 출처는 NOTICE.md 참조.

import Foundation

enum Eph {
    static let DEG_TO_RAD = Double.pi / 180
    static let RAD_TO_DEG = 180 / Double.pi
    static let J2000 = 2451545.0

    /// [0, 360) 정규화
    static func degnorm(_ x: Double) -> Double {
        var y = x.truncatingRemainder(dividingBy: 360)
        if y < 0 { y += 360 }
        return y
    }

    /// [0, 2π) 정규화
    static func radnorm(_ x: Double) -> Double {
        var y = x.truncatingRemainder(dividingBy: 2 * .pi)
        if y < 0 { y += 2 * .pi }
        return y
    }

    /// 호너법: c0 + x(c1 + x(c2 + ...))
    static func horner(_ x: Double, _ coeffs: [Double]) -> Double {
        var result = 0.0
        for c in coeffs.reversed() { result = result * x + c }
        return result
    }

    /// 율리우스일 (그레고리력, Meeus 7.1)
    static func julday(_ year: Int, _ month: Int, _ day: Int, _ hour: Double) -> Double {
        var y = Double(year)
        var m = Double(month)
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1))
            + Double(day) + b - 1524.5 + hour / 24
    }

    /// 평균 황도경사 (IAU 1980, 라디안)
    static func meanObliquity(_ jde: Double) -> Double {
        let T = (jde - J2000) / 36525
        let seconds = 84381.448 - 46.8150 * T - 0.00059 * T * T + 0.001813 * T * T * T
        return seconds / 3600 * DEG_TO_RAD
    }

    /// 간이 장동 (Meeus ch.22 저정밀 공식, 정확도 ~0.5″) — (Δψ, Δε) 라디안
    static func nutation(_ jde: Double) -> (dpsi: Double, deps: Double) {
        let T = (jde - J2000) / 36525
        let omega = (125.04452 - 1934.136261 * T) * DEG_TO_RAD
        let lSun = (280.4665 + 36000.7698 * T) * DEG_TO_RAD
        let lMoon = (218.3165 + 481267.8813 * T) * DEG_TO_RAD

        let dpsiArcsec = -17.20 * sin(omega) - 1.32 * sin(2 * lSun)
            - 0.23 * sin(2 * lMoon) + 0.21 * sin(2 * omega)
        let depsArcsec = 9.20 * cos(omega) + 0.57 * cos(2 * lSun)
            + 0.10 * cos(2 * lMoon) - 0.09 * cos(2 * omega)

        return (dpsiArcsec / 3600 * DEG_TO_RAD, depsArcsec / 3600 * DEG_TO_RAD)
    }

    /// ΔT (초) — Espenak & Meeus 다항식 (NASA 일월식 사이트 공개 자료)
    /// 1800~2150 구간. 입력: 십진 연도
    static func deltaTSeconds(decimalYear y: Double) -> Double {
        switch y {
        case ..<1860:
            let t = y - 1800
            return horner(t, [13.72, -0.332447, 0.0068612, 0.0041116, -0.00037436, 0.0000121272, -0.0000001699, 0.000000000875])
        case ..<1900:
            let t = y - 1860
            return horner(t, [7.62, 0.5737, -0.251754, 0.01680668, -0.0004473624, 1.0 / 233174])
        case ..<1920:
            let t = y - 1900
            return horner(t, [-2.79, 1.494119, -0.0598939, 0.0061966, -0.000197])
        case ..<1941:
            let t = y - 1920
            return horner(t, [21.20, 0.84493, -0.076100, 0.0020936])
        case ..<1961:
            let t = y - 1950
            return horner(t, [29.07, 0.407, -1.0 / 233, 1.0 / 2547])
        case ..<1986:
            let t = y - 1975
            return horner(t, [45.45, 1.067, -1.0 / 260, -1.0 / 718])
        case ..<2005:
            let t = y - 2000
            return horner(t, [63.86, 0.3345, -0.060374, 0.0017275, 0.000651814, 0.00002373599])
        case ..<2050:
            let t = y - 2000
            return horner(t, [62.92, 0.32217, 0.005589])
        case ..<2150:
            let u = (y - 1820) / 100
            return -20 + 32 * u * u - 0.5628 * (2150 - y)
        default:
            let u = (y - 1820) / 100
            return -20 + 32 * u * u
        }
    }

    /// ΔT (일 단위) — jd(UT) 기준
    static func deltaT(_ jd: Double) -> Double {
        let y = 2000.0 + (jd - 2451544.5) / 365.25
        return deltaTSeconds(decimalYear: y) / 86400
    }
}

/// 황도좌표 세차 (J2000 → 임의 시점) — Meeus (21.5)/(21.7)
/// astronomia(MIT) EclipticPrecessor 포팅
struct EclipticPrecessor {
    private let piAngle: Double   // Π
    private let p: Double
    private let sinEta: Double
    private let cosEta: Double

    /// epochTo: 율리우스년 (예: 2000 + (jde − J2000)/365.25)
    init(fromJ2000ToEpoch epochTo: Double) {
        let s = 1.0 / 3600 * Eph.DEG_TO_RAD   // arcsec → rad
        let d = Eph.DEG_TO_RAD
        // from-J2000 특화 계수 (Meeus 21.5)
        let etaCoeff = [47.0029 * s, -0.03302 * s, 0.000060 * s]
        let piCoeff = [174.876384 * d, -869.8089 * s, 0.03536 * s]
        let pCoeff = [5029.0966 * s, 1.11113 * s, -0.000006 * s]

        let t = (epochTo - 2000) * 0.01
        piAngle = Eph.horner(t, piCoeff)
        p = Eph.horner(t, pCoeff) * t
        let eta = Eph.horner(t, etaCoeff) * t
        sinEta = sin(eta)
        cosEta = cos(eta)
    }

    /// (λ, β) 라디안 J2000 → of-date
    func precess(lon: Double, lat: Double) -> (lon: Double, lat: Double) {
        let sb = sin(lat), cb = cos(lat)
        let sd = sin(piAngle - lon), cd = cos(piAngle - lon)
        let a = cosEta * cb * sd - sinEta * sb
        let b = cb * cd
        let c = cosEta * sb + sinEta * cb * sd
        let newLon = Eph.radnorm(p + piAngle - atan2(a, b))
        let newLat = asin(min(1, max(-1, c)))
        return (newLon, newLat)
    }
}
