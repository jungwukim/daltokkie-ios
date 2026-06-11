// 천체 위치 통합 — 외관 황도좌표(of date) 계산 파이프라인
// VSOP87B(J2000) → 지심 → 황도 세차(J2000→date) → 장동 → 외관 황경
// (기하학적 위치 기준 — 광행차 미적용. 표시 정밀도 0.1° 대비 충분)

import Foundation

struct PlanetResult {
    let longitude: Double        // 외관 황경 (deg, of date)
    let latitude: Double         // 황위 (deg)
    let distance: Double         // AU (참고용)
    let longitudeSpeed: Double   // deg/day
    let latitudeSpeed: Double
    let distanceSpeed: Double
}

enum Ephemeris {
    static let SE_SUN = 0
    static let SE_MOON = 1
    static let SE_MEAN_NODE = 10
    static let SE_CHIRON = 15

    private static let vsopNames: [Int: String] = [
        2: "mercury", 3: "venus", 4: "mars", 5: "jupiter",
        6: "saturn", 7: "uranus", 8: "neptune",
    ]

    static func julday(_ y: Int, _ m: Int, _ d: Int, _ h: Double) -> Double {
        Eph.julday(y, m, d, h)
    }

    /// 일심 구면(J2000) → 직교
    private static func rect(_ s: (L: Double, B: Double, R: Double)) -> (x: Double, y: Double, z: Double) {
        let cb = cos(s.B)
        return (s.R * cb * cos(s.L), s.R * cb * sin(s.L), s.R * sin(s.B))
    }

    /// 본체의 지심 외관 황경/황위/거리 (deg, deg, AU) — 단일 시점
    private static func apparentEcliptic(body: Int, jde: Double) throws -> (lon: Double, lat: Double, dist: Double) {
        let earth = rect(CleanBodies.vsop87("earth", jde: jde))

        let geo: (x: Double, y: Double, z: Double)
        switch body {
        case SE_SUN:
            geo = (-earth.x, -earth.y, -earth.z)
        case 9:   // 명왕성
            let p = rect(CleanBodies.plutoHeliocentric(jde: jde))
            geo = (p.x - earth.x, p.y - earth.y, p.z - earth.z)
        default:
            guard let name = vsopNames[body] else {
                throw NatalError.unsupportedBody(body)
            }
            let p = rect(CleanBodies.vsop87(name, jde: jde))
            geo = (p.x - earth.x, p.y - earth.y, p.z - earth.z)
        }

        let lonJ2000 = Eph.radnorm(atan2(geo.y, geo.x))
        let distXY = (geo.x * geo.x + geo.y * geo.y).squareRoot()
        let latJ2000 = atan2(geo.z, distXY)
        let dist = (distXY * distXY + geo.z * geo.z).squareRoot()

        // J2000 → of date 세차 + 장동(황경)
        let epochTo = 2000.0 + (jde - Eph.J2000) / 365.25
        let precessor = EclipticPrecessor(fromJ2000ToEpoch: epochTo)
        let ofDate = precessor.precess(lon: lonJ2000, lat: latJ2000)
        let (dpsi, _) = Eph.nutation(jde)

        return (
            Eph.degnorm((ofDate.lon + dpsi) * Eph.RAD_TO_DEG),
            ofDate.lat * Eph.RAD_TO_DEG,
            dist
        )
    }

    /// 달 외관 황경 (Meeus는 of-date 평균 분점 — 장동만 추가)
    private static func moonApparent(jde: Double) -> (lon: Double, lat: Double, dist: Double) {
        let pos = CleanBodies.moonPosition(jde: jde)
        let (dpsi, _) = Eph.nutation(jde)
        let lon = Eph.degnorm((pos.lon + dpsi) * Eph.RAD_TO_DEG)
        return (lon, pos.lat * Eph.RAD_TO_DEG, pos.rangeKm / 149597870.7)
    }

    private static func wrappedDelta(_ a: Double, _ b: Double) -> Double {
        var d = a - b
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }

    static func calcPlanet(_ jd: Double, _ body: Int) throws -> PlanetResult {
        let tjde = jd + Eph.deltaT(jd)

        if body == SE_MEAN_NODE {
            let lon = CleanBodies.meanNodeLongitude(jde: tjde)
            let lonPrev = CleanBodies.meanNodeLongitude(jde: tjde - 0.1)
            let speed = wrappedDelta(lon, lonPrev) / 0.1
            return PlanetResult(longitude: lon, latitude: 0, distance: 0.002569,
                                longitudeSpeed: speed, latitudeSpeed: 0, distanceSpeed: 0)
        }

        if body == SE_CHIRON {
            let c = try CleanBodies.chiron(jd: jd)
            return PlanetResult(longitude: c.longitude, latitude: 0, distance: 0,
                                longitudeSpeed: c.speed, latitudeSpeed: 0, distanceSpeed: 0)
        }

        if body == SE_MOON {
            let dt = 0.01
            let now = moonApparent(jde: tjde)
            let next = moonApparent(jde: tjde + dt)
            let prev = moonApparent(jde: tjde - dt)
            return PlanetResult(
                longitude: now.lon, latitude: now.lat, distance: now.dist,
                longitudeSpeed: wrappedDelta(next.lon, prev.lon) / (2 * dt),
                latitudeSpeed: (next.lat - prev.lat) / (2 * dt),
                distanceSpeed: (next.dist - prev.dist) / (2 * dt)
            )
        }

        let dt = 0.05
        let now = try apparentEcliptic(body: body, jde: tjde)
        let next = try apparentEcliptic(body: body, jde: tjde + dt)
        let prev = try apparentEcliptic(body: body, jde: tjde - dt)
        return PlanetResult(
            longitude: now.lon, latitude: now.lat, distance: now.dist,
            longitudeSpeed: wrappedDelta(next.lon, prev.lon) / (2 * dt),
            latitudeSpeed: (next.lat - prev.lat) / (2 * dt),
            distanceSpeed: (next.dist - prev.dist) / (2 * dt)
        )
    }
}
