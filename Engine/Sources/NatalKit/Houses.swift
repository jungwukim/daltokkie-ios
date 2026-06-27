// 하우스 커스프 — Placidus (반호 분할 반복법) 신규 구현
//
// 공개 수식 기반: GMST(IAU 1982), MC/ASC 표준 구면삼각 공식,
// Placidus 반복법(상승차 보정 — 점성학 문헌의 공개 알고리즘).
// Swiss Ephemeris 코드 미참조 신규 작성.

import Foundation

struct HousesResult {
    let cusps: [Double]   // [1...12] 사용 (인덱스 0 미사용)
    let ascmc: [Double]   // [0]=ASC, [1]=MC, [2]=ARMC
}

enum Houses {
    private static let CONVERGENCE = 1e-9

    /// 그리니치 평균 항성시 (시간 단위) — IAU 1982 공식 + 분점차
    private static func siderealTimeHours(jdUT: Double, trueObliquityDeg: Double, nutLonDeg: Double) -> Double {
        // 자정 기준 jd0 + 당일 경과초
        var jd0 = floor(jdUT)
        var daySec = (jdUT - jd0) * 86400
        if daySec < 43200 {
            jd0 -= 0.5
            daySec += 43200
        } else {
            jd0 += 0.5
            daySec -= 43200
        }
        let tu = (jd0 - Eph.J2000) / 36525
        var gmstSec = Eph.horner(tu, [24110.54841, 8640184.812866, 0.093104, -6.2e-6])
        let siderealRate = 1.0 + Eph.horner(tu, [8640184.812866, 0.372416, -1.86e-5]) / (86400 * 36525)
        gmstSec += daySec * siderealRate
        // 분점차 (equation of equinoxes): Δψ·cos ε — 1° = 240초
        gmstSec += 240 * nutLonDeg * cos(trueObliquityDeg * Eph.DEG_TO_RAD)
        gmstSec -= 86400 * floor(gmstSec / 86400)
        return gmstSec / 3600
    }

    /// 사승각 x에서 위도 φ 지평선에 떠오르는 황경 — 표준 상승점 공식
    /// λ = atan2( sin x, cos x · cos ε − tan φ · sin ε );  x = ARMC + 90° 가 동쪽 지평선(ASC)
    private static func eclipticLonRising(at x: Double, latitude phi: Double, sinE: Double, cosE: Double) -> Double {
        let xr = Eph.degnorm(x) * Eph.DEG_TO_RAD
        let phir = phi * Eph.DEG_TO_RAD
        let lon = atan2(sin(xr), cos(xr) * cosE - tan(phir) * sinE)
        return Eph.degnorm(lon * Eph.RAD_TO_DEG)
    }

    /// Placidus 단일 커스프 반복: 황경 추정 → 적위 → 상승차(AD) → 사승각 보정 반복
    private static func placidusCusp(
        armc: Double, latitude phi: Double, sinE: Double, cosE: Double,
        offset: Double, fraction: Double, direction: Double
    ) -> Double {
        let phir = phi * Eph.DEG_TO_RAD
        var lon = eclipticLonRising(at: armc + offset, latitude: phi, sinE: sinE, cosE: cosE)
        for _ in 0..<100 {
            let dec = asin(min(1, max(-1, sin(lon * Eph.DEG_TO_RAD) * sinE)))
            let ad = asin(min(1, max(-1, tan(dec) * tan(phir)))) * Eph.RAD_TO_DEG
            let next = eclipticLonRising(
                at: armc + offset + direction * ad * fraction,
                latitude: phi, sinE: sinE, cosE: cosE
            )
            if abs(next - lon) < CONVERGENCE { return next }
            lon = next
        }
        return lon
    }

    /// 극권 폴백 — Porphyrius (사분면 3등분, 공개 정의)
    private static func porphyry(asc: Double, mc: Double) -> [Double] {
        var cusps = [Double](repeating: 0, count: 13)
        cusps[1] = asc
        cusps[10] = mc
        var arc = Eph.degnorm(asc - mc)
        var ascUsed = asc
        if arc > 180 {
            ascUsed = Eph.degnorm(asc + 180)
            arc = Eph.degnorm(ascUsed - mc)
        }
        cusps[11] = Eph.degnorm(mc + arc / 3)
        cusps[12] = Eph.degnorm(mc + arc * 2 / 3)
        cusps[2] = Eph.degnorm(ascUsed + (180 - arc) / 3)
        cusps[3] = Eph.degnorm(ascUsed + (180 - arc) * 2 / 3)
        fillOpposites(&cusps)
        return cusps
    }

    /// 대칭 커스프 채우기 — 1,2,3,10,11,12가 채워진 상태에서 맞은편 6개 계산
    private static func fillOpposites(_ cusps: inout [Double]) {
        cusps[4] = Eph.degnorm(cusps[10] + 180)
        cusps[5] = Eph.degnorm(cusps[11] + 180)
        cusps[6] = Eph.degnorm(cusps[12] + 180)
        cusps[7] = Eph.degnorm(cusps[1] + 180)
        cusps[8] = Eph.degnorm(cusps[2] + 180)
        cusps[9] = Eph.degnorm(cusps[3] + 180)
    }

    static func calcHouses(_ jdUT: Double, _ geolat: Double, _ geolon: Double, _ hsys: String) -> HousesResult {
        let jde = jdUT + Eph.deltaT(jdUT)
        let epsMean = Eph.meanObliquity(jde) * Eph.RAD_TO_DEG
        let (dpsi, deps) = Eph.nutation(jde)
        let nutLonDeg = dpsi * Eph.RAD_TO_DEG
        let epsTrue = epsMean + deps * Eph.RAD_TO_DEG
        let sinE = sin(epsTrue * Eph.DEG_TO_RAD)
        let cosE = cos(epsTrue * Eph.DEG_TO_RAD)

        let gmstH = siderealTimeHours(jdUT: jdUT, trueObliquityDeg: epsTrue, nutLonDeg: nutLonDeg)
        let armc = Eph.degnorm(gmstH * 15 + geolon)

        // MC: tan λ = tan ARMC / cos ε (사분면 보존)
        let armcRad = armc * Eph.DEG_TO_RAD
        let mc = Eph.degnorm(atan2(sin(armcRad), cos(armcRad) * cosE) * Eph.RAD_TO_DEG)

        // ASC: 동쪽 지평선 = 사승각 ARMC + 90°
        let asc = eclipticLonRising(at: armc + 90, latitude: geolat, sinE: sinE, cosE: cosE)

        // 홀사인(Whole Sign): 각 하우스 커스프 = ASC가 속한 사인의 0°부터 30°씩
        if hsys == "W" {
            let ascSign = (asc / 30).rounded(.down) * 30
            var wc = [Double](repeating: 0, count: 13)
            for i in 1...12 { wc[i] = Eph.degnorm(ascSign + Double(i - 1) * 30) }
            return HousesResult(cusps: wc, ascmc: [asc, mc, armc])
        }

        // 극권(|φ| ≥ 90 − ε)은 Placidus 정의 불능 → Porphyrius
        if abs(geolat) >= 90 - epsTrue {
            return HousesResult(cusps: porphyry(asc: asc, mc: mc), ascmc: [asc, mc, armc])
        }

        var cusps = [Double](repeating: 0, count: 13)
        cusps[1] = asc
        cusps[10] = mc
        cusps[11] = placidusCusp(armc: armc, latitude: geolat, sinE: sinE, cosE: cosE, offset: 30, fraction: 1.0 / 3, direction: 1)
        cusps[12] = placidusCusp(armc: armc, latitude: geolat, sinE: sinE, cosE: cosE, offset: 60, fraction: 2.0 / 3, direction: 1)
        cusps[2] = placidusCusp(armc: armc, latitude: geolat, sinE: sinE, cosE: cosE, offset: 120, fraction: 2.0 / 3, direction: -1)
        cusps[3] = placidusCusp(armc: armc, latitude: geolat, sinE: sinE, cosE: cosE, offset: 150, fraction: 1.0 / 3, direction: -1)
        fillOpposites(&cusps)

        return HousesResult(cusps: cusps, ascmc: [asc, mc, armc])
    }
}
