// ΔT (지구자전 보정) — deltat.ts 포팅 (Stephenson 2016 + Astronomical Almanac 테이블)

import Foundation

enum DeltaT {
    private static let J2000 = 2451545.0
    private static let SE_TIDAL_26 = -26.0
    private static let SE_TIDAL_STEPHENSON_2016 = -25.85
    private static let TABSTART = 1620

    private static func adjustForTidacc(
        _ ans: Double, _ Y: Double, _ tidAcc: Double, _ tidAcc0: Double, _ adjustAfter1955: Bool
    ) -> Double {
        var result = ans
        if Y < 1955.0 || adjustAfter1955 {
            let B = Y - 1955.0
            result += -0.000091 * (tidAcc - tidAcc0) * B * B
        }
        return result
    }

    private static func deltatStephenson2016(_ tjd: Double, _ tidAcc: Double) -> Double {
        let dtcf16 = EphTables.shared.deltat.dtcf16
        let Ygreg = 2000.0 + (tjd - J2000) / 365.2425
        var dtVal: Double
        var irec = -1
        for i in 0..<dtcf16.count {
            if tjd < dtcf16[i][0] { break }
            if tjd < dtcf16[i][1] { irec = i; break }
        }
        if irec >= 0 {
            let row = dtcf16[irec]
            let t = (tjd - row[0]) / (row[1] - row[0])
            let c0 = row[2]
            let c1 = row[3] * t
            let c2 = row[4] * t * t
            let c3 = row[5] * t * t * t
            dtVal = c0 + c1 + c2 + c3
        } else if Ygreg < -720 {
            let t = (Ygreg - 1825) / 100.0
            dtVal = -320 + 32.5 * t * t - 179.7337208
        } else {
            let t = (Ygreg - 1825) / 100.0
            dtVal = -320 + 32.5 * t * t + 269.4790417
        }
        dtVal = adjustForTidacc(dtVal, Ygreg, tidAcc, SE_TIDAL_STEPHENSON_2016, true)
        return dtVal / 86400.0
    }

    private static func deltatAA(_ tjd: Double, _ tidAcc: Double) -> Double {
        let dt = EphTables.shared.deltat.dt
        let tabsiz = dt.count
        let tabend = TABSTART + tabsiz - 1
        let Y = 2000.0 + (tjd - 2451544.5) / 365.25
        var d = [Double](repeating: 0, count: 6)

        if Y <= Double(tabend) {
            let p0 = floor(Y)
            let iy = Int(trunc(p0 - Double(TABSTART)))
            var ans = dt[iy]
            var k = iy + 1
            if k >= tabsiz { return adjustForTidacc(ans, Y, tidAcc, SE_TIDAL_26, false) / 86400.0 }
            let p = Y - p0
            ans += p * (dt[k] - dt[iy])
            if iy - 1 < 0 || iy + 2 >= tabsiz { return adjustForTidacc(ans, Y, tidAcc, SE_TIDAL_26, false) / 86400.0 }
            k = iy - 2
            for i in 0..<5 {
                d[i] = (k < 0 || k + 1 >= tabsiz) ? 0 : dt[k + 1] - dt[k]
                k += 1
            }
            for i in 0..<4 { d[i] = d[i + 1] - d[i] }
            var B = 0.25 * p * (p - 1.0)
            ans += B * (d[1] + d[2])
            if iy + 2 >= tabsiz { return adjustForTidacc(ans, Y, tidAcc, SE_TIDAL_26, false) / 86400.0 }
            for i in 0..<3 { d[i] = d[i + 1] - d[i] }
            B = 2.0 * B / 3.0
            ans += (p - 0.5) * B * d[1]
            if iy - 2 < 0 || iy + 3 > tabsiz { return adjustForTidacc(ans, Y, tidAcc, SE_TIDAL_26, false) / 86400.0 }
            for i in 0..<2 { d[i] = d[i + 1] - d[i] }
            B = 0.125 * B * (p + 1.0) * (p - 2.0)
            ans += B * (d[0] + d[1])
            return adjustForTidacc(ans, Y, tidAcc, SE_TIDAL_26, false) / 86400.0
        }

        let Bv = Y - 2000
        var ans: Double
        if Y < 2500 {
            ans = Bv * Bv * Bv * 121.0 / 30000000.0 + Bv * Bv / 1250.0 + Bv * 521.0 / 3000.0 + 64.0
            let B2 = Double(tabend - 2000)
            let ans2 = B2 * B2 * B2 * 121.0 / 30000000.0 + B2 * B2 / 1250.0 + B2 * 521.0 / 3000.0 + 64.0
            if Y <= Double(tabend + 100) {
                let ans3 = dt[tabsiz - 1]
                let dd = ans2 - ans3
                ans += dd * (Y - Double(tabend + 100)) * 0.01
            }
        } else {
            let Bc = 0.01 * (Y - 2000)
            ans = Bc * Bc * 32.5 + 42.5
        }
        return ans / 86400.0
    }

    static func deltaT(_ tjd: Double) -> Double {
        let tidAcc = SE_TIDAL_26
        if tjd < 2435108.5 {
            var d = deltatStephenson2016(tjd, tidAcc)
            if tjd >= 2434108.5 {
                d += (1.0 - (2435108.5 - tjd) / 1000.0) * 0.6610218 / 86400.0
            }
            return d
        }
        let Y = 2000.0 + (tjd - 2451544.5) / 365.25
        if Y >= Double(TABSTART) { return deltatAA(tjd, tidAcc) }
        return 0
    }
}
