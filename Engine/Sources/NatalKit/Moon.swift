// 달 위치 계산 — moon.ts(Moshier DE404 fit) 포팅
// TS의 모듈 레벨 가변 상태를 구조체 인스턴스 필드로 캡슐화.

import Foundation

struct MoonCalculator {
    private static let J2000 = 2451545.0
    private static let AUNIT = 1.49597870700e+11
    private static let STR = 4.8481368110953599359e-6
    private static let MOON_SPEED_INTV = 0.00005
    private static let MOON_MEAN_DIST_KM = 385000.52899

    private let tbl = EphTables.shared.moon

    private var ss = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 5)
    private var cc = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 5)

    private var SWELP = 0.0
    private var M = 0.0
    private var MP = 0.0
    private var D = 0.0
    private var NF = 0.0

    private var T = 0.0
    private var T2 = 0.0

    private var Ve = 0.0
    private var Ea = 0.0
    private var Ma = 0.0
    private var Ju = 0.0
    private var Sa = 0.0

    private var f = 0.0
    private var g = 0.0
    private var cg = 0.0
    private var sg = 0.0

    private var l = 0.0
    private var l1 = 0.0
    private var l2 = 0.0
    private var l3 = 0.0
    private var l4 = 0.0
    private var B = 0.0

    private var moonpol = [0.0, 0.0, 0.0]

    private static func mods3600(_ x: Double) -> Double {
        x - 1296000.0 * floor(x / 1296000.0)
    }

    private mutating func sscc(_ k: Int, _ arg: Double, _ n: Int) {
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

    /// 섭동 급수 평가 — chewm 포팅
    /// typflg: 1=대형 경도+거리, 2=경도+거리, 3=대형 위도, 4=위도
    private mutating func chewm(_ pt: [Double], _ nlines: Int, _ nangles: Int, _ typflg: Int) {
        var p = 0
        for _ in 0..<nlines {
            var k1 = 0
            var sv = 0.0
            var cv = 0.0
            for m in 0..<nangles {
                let j = Int(pt[p]); p += 1
                if j != 0 {
                    var k = j
                    if j < 0 { k = -k }
                    var su = ss[m][k - 1]
                    let cu = cc[m][k - 1]
                    if j < 0 { su = -su }
                    if k1 == 0 {
                        sv = su
                        cv = cu
                        k1 = 1
                    } else {
                        let ff = su * cv + cu * sv
                        cv = cu * cv - su * sv
                        sv = ff
                    }
                }
            }
            switch typflg {
            case 1:
                let j1 = pt[p]; p += 1
                let k1v = pt[p]; p += 1
                moonpol[0] += (10000.0 * j1 + k1v) * sv
                let j2 = pt[p]; p += 1
                let k2 = pt[p]; p += 1
                if k2 != 0 { moonpol[2] += (10000.0 * j2 + k2) * cv }
            case 2:
                let jv = pt[p]; p += 1
                let kv = pt[p]; p += 1
                moonpol[0] += jv * sv
                moonpol[2] += kv * cv
            case 3:
                let jv = pt[p]; p += 1
                let kv = pt[p]; p += 1
                moonpol[1] += (10000.0 * jv + kv) * sv
            case 4:
                let jv = pt[p]; p += 1
                moonpol[1] += jv * sv
            default:
                break
            }
        }
    }

    /// 평균 궤도 요소 (DE404)
    private mutating func meanElements() {
        let Z = tbl.Z
        let fracT = T - trunc(T)

        M = Self.mods3600(129600000.0 * fracT - 3418.961646 * T + 1287104.76154)
        var mPoly = 1.62e-20 * T - 1.0390e-17
        mPoly = mPoly * T - 3.83508e-15
        mPoly = mPoly * T + 4.237343e-13
        mPoly = mPoly * T + 8.8555011e-11
        mPoly = mPoly * T - 4.77258489e-8
        mPoly = mPoly * T - 1.1297037031e-5
        mPoly = mPoly * T + 1.4732069041e-4
        mPoly = mPoly * T - 0.552891801772
        M += mPoly * T2

        NF = Self.mods3600(1739232000.0 * fracT + 295263.0983 * T - 2.079419901760e-01 * T + 335779.55755)
        MP = Self.mods3600(1717200000.0 * fracT + 715923.4728 * T - 2.035946368532e-01 * T + 485868.28096)
        D = Self.mods3600(1601856000.0 * fracT + 1105601.4603 * T + 3.962893294503e-01 * T + 1072260.73512)
        SWELP = Self.mods3600(1731456000.0 * fracT + 1108372.83264 * T - 6.784914260953e-01 * T + 785939.95571)

        NF += ((Z[2] * T + Z[1]) * T + Z[0]) * T2
        MP += ((Z[5] * T + Z[4]) * T + Z[3]) * T2
        D += ((Z[8] * T + Z[7]) * T + Z[6]) * T2
        SWELP += ((Z[11] * T + Z[10]) * T + Z[9]) * T2
    }

    /// 행성 평균 황경 (Laskar/Bretagnon)
    private mutating func meanElementsPl() {
        Ve = Self.mods3600(210664136.4335482 * T + 655127.283046)
        var vePoly = -9.36e-23 * T - 1.95e-20
        vePoly = vePoly * T + 6.097e-18
        vePoly = vePoly * T + 4.43201e-15
        vePoly = vePoly * T + 2.509418e-13
        vePoly = vePoly * T - 3.0622898e-10
        vePoly = vePoly * T - 2.26602516e-9
        vePoly = vePoly * T - 1.4244812531e-5
        vePoly = vePoly * T + 0.005871373088
        Ve += vePoly * T2

        Ea = Self.mods3600(129597742.26669231 * T + 361679.214649)
        var eaPoly = -1.16e-22 * T + 2.976e-19
        eaPoly = eaPoly * T + 2.8460e-17
        eaPoly = eaPoly * T - 1.08402e-14
        eaPoly = eaPoly * T - 1.226182e-12
        eaPoly = eaPoly * T + 1.7228268e-10
        eaPoly = eaPoly * T + 1.515912254e-7
        eaPoly = eaPoly * T + 8.863982531e-6
        eaPoly = eaPoly * T - 2.0199859001e-2
        Ea += eaPoly * T2

        Ma = Self.mods3600(68905077.59284 * T + 1279559.78866)
        Ma += (-1.043e-5 * T + 9.38012e-3) * T2

        Ju = Self.mods3600(10925660.428608 * T + 123665.342120)
        Ju += (1.543273e-5 * T - 3.06037836351e-1) * T2

        Sa = Self.mods3600(4399609.65932 * T + 180278.89694)
        Sa += ((4.475946e-8 * T - 6.874806e-5) * T + 7.56161437443e-1) * T2
    }

    // T^2, T^1 섭동항 (DE404)
    private mutating func moon1() {
        let Z = tbl.Z
        var a: Double

        for i in 0..<5 {
            for j in 0..<8 {
                ss[i][j] = 0
                cc[i][j] = 0
            }
        }

        sscc(0, Self.STR * D, 6)
        sscc(1, Self.STR * M, 4)
        sscc(2, Self.STR * MP, 4)
        sscc(3, Self.STR * NF, 4)

        moonpol[0] = 0.0
        moonpol[1] = 0.0
        moonpol[2] = 0.0

        chewm(tbl.LRT2, tbl.NLRT2, 4, 2)
        chewm(tbl.BT2, tbl.NBT2, 4, 4)

        f = 18 * Ve - 16 * Ea

        g = Self.STR * (f - MP)
        cg = cos(g)
        sg = sin(g)
        l = 6.367278 * cg + 12.747036 * sg
        l1 = 23123.70 * cg - 10570.02 * sg
        l2 = Z[12] * cg + Z[13] * sg
        moonpol[2] += 5.01 * cg + 2.72 * sg

        g = Self.STR * (10.0 * Ve - 3.0 * Ea - MP)
        cg = cos(g)
        sg = sin(g)
        l += -0.253102 * cg + 0.503359 * sg
        l1 += 1258.46 * cg + 707.29 * sg
        l2 += Z[14] * cg + Z[15] * sg

        g = Self.STR * (8.0 * Ve - 13.0 * Ea)
        cg = cos(g)
        sg = sin(g)
        l += -0.187231 * cg - 0.127481 * sg
        l1 += -319.87 * cg - 18.34 * sg
        l2 += Z[16] * cg + Z[17] * sg

        a = 4.0 * Ea - 8.0 * Ma + 3.0 * Ju
        g = Self.STR * a
        cg = cos(g)
        sg = sin(g)
        l += -0.866287 * cg + 0.248192 * sg
        l1 += 41.87 * cg + 1053.97 * sg
        l2 += Z[18] * cg + Z[19] * sg

        g = Self.STR * (a - MP)
        cg = cos(g)
        sg = sin(g)
        l += -0.165009 * cg + 0.044176 * sg
        l1 += 4.67 * cg + 201.55 * sg

        g = Self.STR * f
        cg = cos(g)
        sg = sin(g)
        l += 0.330401 * cg + 0.661362 * sg
        l1 += 1202.67 * cg - 555.59 * sg
        l2 += Z[20] * cg + Z[21] * sg

        g = Self.STR * (f - 2.0 * MP)
        cg = cos(g)
        sg = sin(g)
        l += 0.352185 * cg + 0.705041 * sg
        l1 += 1283.59 * cg - 586.43 * sg

        g = Self.STR * (2.0 * Ju - 5.0 * Sa)
        cg = cos(g)
        sg = sin(g)
        l += -0.034700 * cg + 0.160041 * sg
        l2 += Z[22] * cg + Z[23] * sg

        g = Self.STR * (SWELP - NF)
        cg = cos(g)
        sg = sin(g)
        l += 0.000116 * cg + 7.063040 * sg
        l1 += 298.8 * sg

        sg = sin(Self.STR * M)
        l3 = Z[24] * sg
        l4 = 0

        g = Self.STR * (2.0 * D - M)
        sg = sin(g)
        cg = cos(g)
        moonpol[2] += -0.2655 * cg * T

        g = Self.STR * (M - MP)
        moonpol[2] += -0.1568 * cos(g) * T

        g = Self.STR * (M + MP)
        moonpol[2] += 0.1309 * cos(g) * T

        g = Self.STR * (2.0 * (D + M) - MP)
        sg = sin(g)
        cg = cos(g)
        moonpol[2] += 0.5568 * cg * T

        l2 += moonpol[0]

        g = Self.STR * (2.0 * D - M - MP)
        moonpol[2] += -0.1910 * cos(g) * T

        moonpol[1] *= T
        moonpol[2] *= T

        moonpol[0] = 0.0
        chewm(tbl.BT, tbl.NBT, 4, 4)
        chewm(tbl.LRT, tbl.NLRT, 4, 1)

        g = Self.STR * (f - MP - NF - 2355767.6)
        moonpol[1] += -1127.0 * sin(g)

        g = Self.STR * (f - MP + NF - 235353.6)
        moonpol[1] += -1123.0 * sin(g)

        g = Self.STR * (Ea + D + 51987.6)
        moonpol[1] += 1303.0 * sin(g)

        g = Self.STR * SWELP
        moonpol[1] += 342.0 * sin(g)

        g = Self.STR * (2.0 * Ve - 3.0 * Ea)
        cg = cos(g)
        sg = sin(g)
        l += -0.343550 * cg - 0.000276 * sg
        l1 += 105.90 * cg + 336.53 * sg

        g = Self.STR * (f - 2.0 * D)
        cg = cos(g)
        sg = sin(g)
        l += 0.074668 * cg + 0.149501 * sg
        l1 += 271.77 * cg - 124.20 * sg

        g = Self.STR * (f - 2.0 * D - MP)
        cg = cos(g)
        sg = sin(g)
        l += 0.073444 * cg + 0.147094 * sg
        l1 += 265.24 * cg - 121.16 * sg

        g = Self.STR * (f + 2.0 * D - MP)
        cg = cos(g)
        sg = sin(g)
        l += 0.072844 * cg + 0.145829 * sg
        l1 += 265.18 * cg - 121.29 * sg

        g = Self.STR * (f + 2.0 * (D - MP))
        cg = cos(g)
        sg = sin(g)
        l += 0.070201 * cg + 0.140542 * sg
        l1 += 255.36 * cg - 116.79 * sg

        g = Self.STR * (Ea + D - NF)
        cg = cos(g)
        sg = sin(g)
        l += 0.288209 * cg - 0.025901 * sg
        l1 += -63.51 * cg - 240.14 * sg

        g = Self.STR * (2.0 * Ea - 3.0 * Ju + 2.0 * D - MP)
        cg = cos(g)
        sg = sin(g)
        l += 0.077865 * cg + 0.438460 * sg
        l1 += 210.57 * cg + 124.84 * sg

        g = Self.STR * (Ea - 2.0 * Ma)
        cg = cos(g)
        sg = sin(g)
        l += -0.216579 * cg + 0.241702 * sg
        l1 += 197.67 * cg + 125.23 * sg

        g = Self.STR * (a + MP)
        cg = cos(g)
        sg = sin(g)
        l += -0.165009 * cg + 0.044176 * sg
        l1 += 4.67 * cg + 201.55 * sg

        g = Self.STR * (a + 2.0 * D - MP)
        cg = cos(g)
        sg = sin(g)
        l += -0.133533 * cg + 0.041116 * sg
        l1 += 6.95 * cg + 187.07 * sg

        g = Self.STR * (a - 2.0 * D + MP)
        cg = cos(g)
        sg = sin(g)
        l += -0.133430 * cg + 0.041079 * sg
        l1 += 6.28 * cg + 169.08 * sg

        g = Self.STR * (3.0 * Ve - 4.0 * Ea)
        cg = cos(g)
        sg = sin(g)
        l += -0.175074 * cg + 0.003035 * sg
        l1 += 49.17 * cg + 150.57 * sg

        g = Self.STR * (2.0 * (Ea + D - MP) - 3.0 * Ju + 213534.0)
        l1 += 158.4 * sin(g)

        l1 += moonpol[0]

        a = 0.1 * T
        moonpol[1] *= a
        moonpol[2] *= a
    }

    // 소형 T^0 항
    private mutating func moon2() {
        g = Self.STR * (2 * (Ea - Ju + D) - MP + 648431.172)
        l += 1.14307 * sin(g)

        g = Self.STR * (Ve - Ea + 648035.568)
        l += 0.82155 * sin(g)

        g = Self.STR * (3 * (Ve - Ea) + 2 * D - MP + 647933.184)
        l += 0.64371 * sin(g)

        g = Self.STR * (Ea - Ju + 4424.04)
        l += 0.63880 * sin(g)

        g = Self.STR * (SWELP + MP - NF + 4.68)
        l += 0.49331 * sin(g)

        g = Self.STR * (SWELP - MP - NF + 4.68)
        l += 0.4914 * sin(g)

        g = Self.STR * (SWELP + NF + 2.52)
        l += 0.36061 * sin(g)

        g = Self.STR * (2.0 * Ve - 2.0 * Ea + 736.2)
        l += 0.30154 * sin(g)

        g = Self.STR * (2.0 * Ea - 3.0 * Ju + 2.0 * D - 2.0 * MP + 36138.2)
        l += 0.28282 * sin(g)

        g = Self.STR * (2.0 * Ea - 2.0 * Ju + 2.0 * D - 2.0 * MP + 311.0)
        l += 0.24516 * sin(g)

        g = Self.STR * (Ea - Ju - 2.0 * D + MP + 6275.88)
        l += 0.21117 * sin(g)

        g = Self.STR * (2.0 * (Ea - Ma) - 846.36)
        l += 0.19444 * sin(g)

        g = Self.STR * (2.0 * (Ea - Ju) + 1569.96)
        l -= 0.18457 * sin(g)

        g = Self.STR * (2.0 * (Ea - Ju) - MP - 55.8)
        l += 0.18256 * sin(g)

        g = Self.STR * (Ea - Ju - 2.0 * D + 6490.08)
        l += 0.16499 * sin(g)

        g = Self.STR * (Ea - 2.0 * Ju - 212378.4)
        l += 0.16427 * sin(g)

        g = Self.STR * (2.0 * (Ve - Ea - D) + MP + 1122.48)
        l += 0.16088 * sin(g)

        g = Self.STR * (Ve - Ea - MP + 32.04)
        l -= 0.15350 * sin(g)

        g = Self.STR * (Ea - Ju - MP + 4488.88)
        l += 0.14346 * sin(g)

        g = Self.STR * (2.0 * (Ve - Ea + D) - MP - 8.64)
        l += 0.13594 * sin(g)

        g = Self.STR * (2.0 * (Ve - Ea - D) + 1319.76)
        l += 0.13432 * sin(g)

        g = Self.STR * (Ve - Ea - 2.0 * D + MP - 56.16)
        l -= 0.13122 * sin(g)

        g = Self.STR * (Ve - Ea + MP + 54.36)
        l -= 0.12722 * sin(g)

        g = Self.STR * (3.0 * (Ve - Ea) - MP + 433.8)
        l += 0.12539 * sin(g)

        g = Self.STR * (Ea - Ju + MP + 4002.12)
        l += 0.10994 * sin(g)

        g = Self.STR * (20.0 * Ve - 21.0 * Ea - 2.0 * D + MP - 317511.72)
        l += 0.10652 * sin(g)

        g = Self.STR * (26.0 * Ve - 29.0 * Ea - MP + 270002.52)
        l += 0.10490 * sin(g)

        g = Self.STR * (3.0 * Ve - 4.0 * Ea + D - MP - 322765.56)
        l += 0.10386 * sin(g)

        g = Self.STR * (SWELP + 648002.556)
        B = 8.04508 * sin(g)

        g = Self.STR * (Ea + D + 996048.252)
        B += 1.51021 * sin(g)

        g = Self.STR * (f - MP + NF + 95554.332)
        B += 0.63037 * sin(g)

        g = Self.STR * (f - MP - NF + 95553.792)
        B += 0.63014 * sin(g)

        g = Self.STR * (SWELP - MP + 2.9)
        B += 0.45587 * sin(g)

        g = Self.STR * (SWELP + MP + 2.5)
        B += -0.41573 * sin(g)

        g = Self.STR * (SWELP - 2.0 * NF + 3.2)
        B += 0.32623 * sin(g)

        g = Self.STR * (SWELP - 2.0 * D + 2.5)
        B += 0.29855 * sin(g)
    }

    // 주요 T^0 항
    private mutating func moon3() {
        moonpol[0] = 0.0
        chewm(tbl.LR, tbl.NLR, 4, 1)
        chewm(tbl.MB, tbl.NMB, 4, 3)

        l += (((l4 * T + l3) * T + l2) * T + l1) * T * 1.0e-5

        moonpol[0] = SWELP + l + 1.0e-4 * moonpol[0]
        moonpol[1] = 1.0e-4 * moonpol[1] + B
        moonpol[2] = 1.0e-4 * moonpol[2] + Self.MOON_MEAN_DIST_KM
    }

    // 단위 변환
    private mutating func moon4() {
        moonpol[2] /= Self.AUNIT / 1000
        moonpol[0] = Self.STR * Self.mods3600(moonpol[0])
        moonpol[1] = Self.STR * moonpol[1]
        B = moonpol[1]
    }

    private mutating func moshmoon2(_ J: Double) -> [Double] {
        T = (J - Self.J2000) / 36525.0
        T2 = T * T

        meanElements()
        meanElementsPl()
        moon1()
        moon2()
        moon3()
        moon4()

        return [moonpol[0], moonpol[1], moonpol[2]]
    }

    /// 황도좌표(of date) → 적도 J2000 직교좌표
    private static func ecldatEqu2000(_ tjd: Double, _ xpm: inout [Double]) {
        let cart = Eph.polcart([xpm[0], xpm[1], xpm[2]])
        let tjde = tjd + DeltaT.deltaT(tjd)
        let eps = Eph.calcObliquity(tjde)
        var eq = Eph.coortrf2([cart[0], cart[1], cart[2], 0, 0, 0], -eps)
        Eph.precess(&eq, tjde, 1)
        xpm[0] = eq[0]
        xpm[1] = eq[1]
        xpm[2] = eq[2]
    }

    /// 달의 지구중심 적도 J2000 위치+속도 [x,y,z,vx,vy,vz] (AU, AU/day)
    static func calcMoon(_ tjd: Double) -> [Double] {
        var calc = MoonCalculator()

        var xpm = calc.moshmoon2(tjd)
        ecldatEqu2000(tjd, &xpm)

        let t1 = tjd + MOON_SPEED_INTV
        var x1 = calc.moshmoon2(t1)
        ecldatEqu2000(t1, &x1)

        let t2 = tjd - MOON_SPEED_INTV
        var x2 = calc.moshmoon2(t2)
        ecldatEqu2000(t2, &x2)

        var xp = [Double](repeating: 0, count: 6)
        for i in 0...2 {
            xp[i] = xpm[i]
            let b = (x1[i] - x2[i]) / 2
            let a = (x1[i] + x2[i]) / 2 - xpm[i]
            xp[i + 3] = (2 * a + b) / MOON_SPEED_INTV
        }
        return xp
    }
}
