// 장동(章動) 보정 — nutation.ts 포팅 (IAU 1980 계열)

import Foundation

enum Nutation {
    private static let J2000 = 2451545.0
    private static let ENDMARK = 9999.0

    /// 반환: (dpsi, deps) 라디안
    static func calcNutation(_ tjd: Double) -> (Double, Double) {
        let nt = EphTables.shared.nutation.terms
        let T = (tjd - J2000) / 36525.0
        let T2 = T * T

        let OM = Eph.degnorm((-6962890.539 * T + 450160.280 + (0.008 * T + 7.455) * T2) / 3600) * Eph.DEG_TO_RAD
        let MS = Eph.degnorm((129596581.224 * T + 1287099.804 - (0.012 * T + 0.577) * T2) / 3600) * Eph.DEG_TO_RAD
        let MM = Eph.degnorm((1717915922.633 * T + 485866.733 + (0.064 * T + 31.310) * T2) / 3600) * Eph.DEG_TO_RAD
        let FF = Eph.degnorm((1739527263.137 * T + 335778.877 + (0.011 * T - 13.257) * T2) / 3600) * Eph.DEG_TO_RAD
        let DD = Eph.degnorm((1602961601.328 * T + 1072261.307 + (0.019 * T - 6.891) * T2) / 3600) * Eph.DEG_TO_RAD

        let args = [MM, MS, FF, DD, OM]
        let ns = [3, 2, 4, 4, 2]

        var ss = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 5)
        var cc = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 5)
        for k in 0...4 {
            let arg = args[k]
            let n = ns[k]
            let su = sin(arg)
            let cu = cos(arg)
            ss[k][0] = su
            cc[k][0] = cu
            var sv = 2.0 * su * cu
            var cv = cu * cu - su * su
            ss[k][1] = sv
            cc[k][1] = cv
            var i = 2
            while i < n {
                let s = su * cv + cu * sv
                cv = cu * cv - su * sv
                sv = s
                ss[k][i] = sv
                cc[k][i] = cv
                i += 1
            }
        }

        var C = (-0.01742 * T - 17.1996) * ss[4][0]
        var D = (0.00089 * T + 9.2025) * cc[4][0]

        var p = 0
        while nt[p] != ENDMARK {
            var k1 = 0
            var cv = 0.0
            var sv = 0.0
            for m in 0..<5 {
                var j = Int(nt[p + m])
                if j > 100 { j = 0 }
                if j != 0 {
                    var k = j
                    if j < 0 { k = -k }
                    var su = ss[m][k - 1]
                    if j < 0 { su = -su }
                    let cu = cc[m][k - 1]
                    if k1 == 0 {
                        sv = su
                        cv = cu
                        k1 = 1
                    } else {
                        let sw = su * cv + cu * sv
                        cv = cu * cv - su * sv
                        sv = sw
                    }
                }
            }

            var f = nt[p + 5] * 0.0001
            if nt[p + 6] != 0 { f += 0.00001 * T * nt[p + 6] }

            var g = nt[p + 7] * 0.0001
            if nt[p + 8] != 0 { g += 0.00001 * T * nt[p + 8] }

            if nt[p] >= 100 {
                f *= 0.1
                g *= 0.1
            }

            if nt[p] != 102 {
                C += f * sv
                D += g * cv
            } else {
                C += f * cv
                D += g * sv
            }

            p += 9
        }

        let dpsi = Eph.DEG_TO_RAD * C / 3600.0
        let deps = Eph.DEG_TO_RAD * D / 3600.0
        return (dpsi, deps)
    }
}
