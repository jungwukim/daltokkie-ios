// 행성 위치 계산 — planets.ts(moshplan) 포팅
// TS의 모듈 레벨 가변 상태(ssTbl/ccTbl)는 호출 단위 인스턴스로 캡슐화.

import Foundation

struct PlanetCalculator {
    private static let J2000 = 2451545.0
    private static let J1900 = 2415020.0
    private static let TIMESCALE = 3652500.0
    private static let STR = 4.8481368110953599359e-6
    private static let PLAN_SPEED_INTV = 0.1
    private static let EARTH_MOON_MRAT = 81.30056

    private static let pnoint2msh = [2, 2, 0, 1, 3, 4, 5, 6, 7, 8]

    private static let freqs: [Double] = [
        53810162868.8982, 21066413643.3548, 12959774228.3429,
        6890507749.3988, 1092566037.7991, 439960985.5372,
        154248119.3933, 78655032.0744, 52272245.1795,
    ]

    private static let phases: [Double] = [
        252.25090552 * 3600, 181.97980085 * 3600, 100.46645683 * 3600,
        355.43299958 * 3600, 34.35151874 * 3600, 50.07744430 * 3600,
        314.05500511 * 3600, 304.34866548 * 3600, 860492.1546,
    ]

    private var ssTbl = [[Double]](repeating: [Double](repeating: 0, count: 24), count: 9)
    private var ccTbl = [[Double]](repeating: [Double](repeating: 0, count: 24), count: 9)

    private mutating func sscc(_ k: Int, _ arg: Double, _ n: Int) {
        let su = sin(arg)
        let cu = cos(arg)
        ssTbl[k][0] = su
        ccTbl[k][0] = cu
        var sv = 2.0 * su * cu
        var cv = cu * cu - su * su
        ssTbl[k][1] = sv
        ccTbl[k][1] = cv
        var i = 2
        while i < n {
            let s = su * cv + cu * sv
            cv = cu * cv - su * sv
            sv = s
            ssTbl[k][i] = sv
            ccTbl[k][i] = cv
            i += 1
        }
    }

    private mutating func moshplan2(_ J: Double, _ plan: PlanetTable) -> [Double] {
        let T = (J - Self.J2000) / Self.TIMESCALE
        var pobj = [0.0, 0.0, 0.0]

        for i in 0..<9 {
            let j = plan.maxHarmonic[i]
            if j > 0 {
                let sr = (Eph.mods3600(Self.freqs[i] * T) + Self.phases[i]) * Self.STR
                sscc(i, sr, j)
            }
        }

        let argTbl = plan.argTbl
        let lonTbl = plan.lonTbl
        let latTbl = plan.latTbl
        let radTbl = plan.radTbl

        var sl = 0.0, sb = 0.0, sr = 0.0
        var pIdx = 0, plIdx = 0, pbIdx = 0, prIdx = 0

        while true {
            let np = argTbl[pIdx]; pIdx += 1
            if np < 0 { break }

            if np == 0 {
                let nt = argTbl[pIdx]; pIdx += 1
                var cu = lonTbl[plIdx]; plIdx += 1
                for _ in 0..<nt { cu = cu * T + lonTbl[plIdx]; plIdx += 1 }
                sl += Eph.mods3600(cu)
                cu = latTbl[pbIdx]; pbIdx += 1
                for _ in 0..<nt { cu = cu * T + latTbl[pbIdx]; pbIdx += 1 }
                sb += cu
                cu = radTbl[prIdx]; prIdx += 1
                for _ in 0..<nt { cu = cu * T + radTbl[prIdx]; prIdx += 1 }
                sr += cu
                continue
            }

            var k1 = 0
            var cv = 0.0, sv = 0.0
            for _ in 0..<np {
                let j = argTbl[pIdx]; pIdx += 1
                let m = argTbl[pIdx] - 1; pIdx += 1
                if j != 0 {
                    var k = j
                    if j < 0 { k = -k }
                    k -= 1
                    var su = ssTbl[m][k]
                    if j < 0 { su = -su }
                    let cu = ccTbl[m][k]
                    if k1 == 0 { sv = su; cv = cu; k1 = 1 }
                    else { let t = su * cv + cu * sv; cv = cu * cv - su * sv; sv = t }
                }
            }

            let nt = argTbl[pIdx]; pIdx += 1

            var cuL = lonTbl[plIdx]; plIdx += 1
            var suL = lonTbl[plIdx]; plIdx += 1
            for _ in 0..<nt {
                cuL = cuL * T + lonTbl[plIdx]; plIdx += 1
                suL = suL * T + lonTbl[plIdx]; plIdx += 1
            }
            sl += cuL * cv + suL * sv

            var cuB = latTbl[pbIdx]; pbIdx += 1
            var suB = latTbl[pbIdx]; pbIdx += 1
            for _ in 0..<nt {
                cuB = cuB * T + latTbl[pbIdx]; pbIdx += 1
                suB = suB * T + latTbl[pbIdx]; pbIdx += 1
            }
            sb += cuB * cv + suB * sv

            var cuR = radTbl[prIdx]; prIdx += 1
            var suR = radTbl[prIdx]; prIdx += 1
            for _ in 0..<nt {
                cuR = cuR * T + radTbl[prIdx]; prIdx += 1
                suR = suR * T + radTbl[prIdx]; prIdx += 1
            }
            sr += cuR * cv + suR * sv
        }

        pobj[0] = Self.STR * sl
        pobj[1] = Self.STR * sb
        pobj[2] = Self.STR * plan.distance * sr + plan.distance
        return pobj
    }

    /// 지구-달 질량중심 → 지구 중심 보정
    private static func embofsMosh(_ tjd: Double, _ xemb: inout [Double], _ epsDate: Double) {
        let T = (tjd - J1900) / 36525.0
        var a = Eph.degnorm(((1.44e-5 * T + 0.009192) * T + 477198.8491) * T + 296.104608)
        a *= Eph.DEG_TO_RAD
        let smp = sin(a)
        let cmp = cos(a)
        let s2mp = 2.0 * smp * cmp
        let c2mp = cmp * cmp - smp * smp
        a = Eph.degnorm(((1.9e-6 * T - 0.001436) * T + 445267.1142) * T + 350.737486)
        a = 2.0 * Eph.DEG_TO_RAD * a
        let s2d = sin(a)
        let c2d = cos(a)
        a = Eph.degnorm(((-3e-7 * T - 0.003211) * T + 483202.0251) * T + 11.250889)
        a *= Eph.DEG_TO_RAD
        let sf = sin(a)
        let cf = cos(a)
        let s2f = 2.0 * sf * cf
        let sx = s2d * cmp - c2d * smp
        var L = ((1.9e-6 * T - 0.001133) * T + 481267.8831) * T + 270.434164
        let Mv = Eph.degnorm(((-3.3e-6 * T - 1.50e-4) * T + 35999.0498) * T + 358.475833)
        L = L + 6.288750 * smp + 1.274018 * sx + 0.658309 * s2d
            + 0.213616 * s2mp - 0.185596 * sin(Eph.DEG_TO_RAD * Mv) - 0.114336 * s2f
        let aSmpCf = smp * cf
        let sCmpSf = cmp * sf
        var B = 5.128189 * sf + 0.280606 * (aSmpCf + sCmpSf)
            + 0.277693 * (aSmpCf - sCmpSf)
            + 0.173238 * (s2d * cf - c2d * sf)
        B *= Eph.DEG_TO_RAD
        var p = 0.950724 + 0.051818 * cmp
            + 0.009531 * (c2d * cmp + s2d * smp)
            + 0.007843 * c2d + 0.002824 * c2mp
        p *= Eph.DEG_TO_RAD
        let dist = 4.263523e-5 / sin(p)
        L = Eph.degnorm(L) * Eph.DEG_TO_RAD
        let xyz = Eph.polcart([L, B, dist])
        var xyzEq = Eph.coortrf2([xyz[0], xyz[1], xyz[2], 0, 0, 0], -epsDate)
        Eph.precess(&xyzEq, tjd, 1)
        for i in 0...2 {
            xemb[i] -= xyzEq[i] / (EARTH_MOON_MRAT + 1.0)
        }
    }

    /// 행성 + 지구의 일심 직교좌표(J2000 적도) 계산
    static func moshplan(_ tjd: Double, _ ipli: Int) -> (xp: [Double], xe: [Double]) {
        var calc = PlanetCalculator()
        let allPlanets = EphTables.shared.planets.ordered
        let iplm = pnoint2msh[ipli]
        let eps2000 = Eph.calcObliquity(J2000)

        let embPolar = calc.moshplan2(tjd, allPlanets[pnoint2msh[0]])
        var xe = Eph.polcart(embPolar)
        xe = Eph.coortrf2([xe[0], xe[1], xe[2], 0, 0, 0], -eps2000)
        let epsDate = Eph.calcObliquity(tjd + DeltaT.deltaT(tjd))
        embofsMosh(tjd, &xe, epsDate)

        let embPolar2 = calc.moshplan2(tjd - PLAN_SPEED_INTV, allPlanets[pnoint2msh[0]])
        var x2 = Eph.polcart(embPolar2)
        x2 = Eph.coortrf2([x2[0], x2[1], x2[2], 0, 0, 0], -eps2000)
        embofsMosh(tjd - PLAN_SPEED_INTV, &x2, epsDate)

        xe[3] = (xe[0] - x2[0]) / PLAN_SPEED_INTV
        xe[4] = (xe[1] - x2[1]) / PLAN_SPEED_INTV
        xe[5] = (xe[2] - x2[2]) / PLAN_SPEED_INTV

        if ipli == 0 { return (xp: xe, xe: xe) }

        let plPolar = calc.moshplan2(tjd, allPlanets[iplm])
        var xp = Eph.polcart(plPolar)
        xp = Eph.coortrf2([xp[0], xp[1], xp[2], 0, 0, 0], -eps2000)

        let plPolar2 = calc.moshplan2(tjd - PLAN_SPEED_INTV, allPlanets[iplm])
        var xp2 = Eph.polcart(plPolar2)
        xp2 = Eph.coortrf2([xp2[0], xp2[1], xp2[2], 0, 0, 0], -eps2000)

        xp[3] = (xp[0] - xp2[0]) / PLAN_SPEED_INTV
        xp[4] = (xp[1] - xp2[1]) / PLAN_SPEED_INTV
        xp[5] = (xp[2] - xp2[2]) / PLAN_SPEED_INTV

        return (xp: xp, xe: xe)
    }
}
