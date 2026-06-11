// 출생차트 엔진 — natal-engine.ts 포팅
// 타임존 해석은 Foundation TimeZone(ICU/IANA) 사용 — TS의 Intl 기반 resolveToUtc와 동일 의미:
// DST gap이면 에러, fall-back(중복 시간)이면 이른 시각(표준시) 채택.

import Foundation

public enum NatalError: Error, CustomStringConvertible {
    case dstGap(String)
    case unknownTimezone(String)
    case unsupportedBody(Int)
    case chironOutOfRange(String)

    public var description: String {
        switch self {
        case .dstGap(let msg): return msg
        case .unknownTimezone(let tz): return "알 수 없는 타임존: \(tz)"
        case .unsupportedBody(let body): return "지원하지 않는 천체: \(body)"
        case .chironOutOfRange(let msg): return "Chiron 범위 밖: \(msg)"
        }
    }
}

public struct PlanetPosition: Codable, Equatable, Sendable {
    public let id: String
    public let longitude: Double
    public let latitude: Double
    public let speed: Double
    public let sign: String
    public let degreeInSign: Double
    public let isRetrograde: Bool
    public let house: Int?
}

public struct NatalHouse: Codable, Equatable, Sendable {
    public let number: Int
    public let cuspLongitude: Double
    public let sign: String
    public let degreeInSign: Double
}

public struct AnglePoint: Codable, Equatable, Sendable {
    public let longitude: Double
    public let sign: String
    public let degreeInSign: Double
}

public struct NatalAngles: Codable, Equatable, Sendable {
    public let asc: AnglePoint
    public let mc: AnglePoint
    public let desc: AnglePoint
    public let ic: AnglePoint
}

public struct NatalAspect: Codable, Equatable, Sendable {
    public let planet1: String
    public let planet2: String
    public let type: String
    public let angle: Double
    public let orb: Double
}

public struct NatalChart: Codable, Equatable, Sendable {
    public let planets: [PlanetPosition]
    public let houses: [NatalHouse]
    public let angles: NatalAngles?
    public let aspects: [NatalAspect]
}

public struct NatalInput: Sendable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let hour: Int
    public let minute: Int
    public var latitude: Double?
    public var longitude: Double?
    public var unknownTime: Bool = false
    public var timezone: String = "Asia/Seoul"

    public init(
        year: Int, month: Int, day: Int, hour: Int, minute: Int,
        latitude: Double? = nil, longitude: Double? = nil,
        unknownTime: Bool = false, timezone: String = "Asia/Seoul"
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.latitude = latitude
        self.longitude = longitude
        self.unknownTime = unknownTime
        self.timezone = timezone
    }
}

public enum NatalEngine {
    static let DEFAULT_LAT = 37.5194
    static let DEFAULT_LON = 127.0992

    static let ZODIAC_SIGNS = [
        "Aries", "Taurus", "Gemini", "Cancer",
        "Leo", "Virgo", "Libra", "Scorpio",
        "Sagittarius", "Capricorn", "Aquarius", "Pisces",
    ]

    static let PLANET_BODIES: [(id: String, body: Int)] = [
        ("Sun", 0), ("Moon", 1), ("Mercury", 2), ("Venus", 3),
        ("Mars", 4), ("Jupiter", 5), ("Saturn", 6), ("Uranus", 7),
        ("Neptune", 8), ("Pluto", 9), ("Chiron", 15), ("NorthNode", 10),
    ]

    static let ASPECT_DEFS: [(type: String, angle: Double, maxOrb: Double)] = [
        ("conjunction", 0, 8),
        ("sextile", 60, 6),
        ("square", 90, 8),
        ("trine", 120, 8),
        ("opposition", 180, 8),
    ]

    static func normalizeDeg(_ deg: Double) -> Double {
        ((deg.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
    }

    static func lonToSign(_ lon: Double) -> String {
        ZODIAC_SIGNS[Int(trunc(normalizeDeg(lon) / 30))]
    }

    static func degreeInSign(_ lon: Double) -> Double {
        normalizeDeg(lon).truncatingRemainder(dividingBy: 30)
    }

    static func angularDifference(_ lon1: Double, _ lon2: Double) -> Double {
        var diff = abs(normalizeDeg(lon1) - normalizeDeg(lon2))
        if diff > 180 { diff = 360 - diff }
        return diff
    }

    static func findHouse(_ planetLon: Double, _ cusps: [Double]) -> Int {
        let lon = normalizeDeg(planetLon)
        for i in 1...12 {
            let start = normalizeDeg(cusps[i])
            let end = normalizeDeg(cusps[i == 12 ? 1 : i + 1])
            if start < end {
                if lon >= start && lon < end { return i }
            } else {
                if lon >= start || lon < end { return i }
            }
        }
        return 1
    }

    static func calculateAspects(_ planets: [PlanetPosition]) -> [NatalAspect] {
        var aspects: [NatalAspect] = []
        for i in 0..<planets.count {
            for j in (i + 1)..<planets.count {
                let p1 = planets[i]
                let p2 = planets[j]
                let diff = angularDifference(p1.longitude, p2.longitude)
                for def in ASPECT_DEFS {
                    let orb = abs(diff - def.angle)
                    if orb <= def.maxOrb {
                        aspects.append(NatalAspect(
                            planet1: p1.id, planet2: p2.id,
                            type: def.type, angle: def.angle,
                            orb: (orb * 10).rounded() / 10
                        ))
                    }
                }
            }
        }
        // JS Array.sort는 안정 정렬 — 동률 orb의 원래 순서 보존
        return aspects.enumerated()
            .sorted { ($0.element.orb, $0.offset) < ($1.element.orb, $1.offset) }
            .map(\.element)
    }

    /// 로컬 벽시계 → UTC. DST gap이면 throw, fall-back이면 이른 시각 채택.
    static func resolveToUtc(
        year: Int, month: Int, day: Int, hour: Int, minute: Int, timezone: String
    ) throws -> (year: Int, month: Int, day: Int, hour: Int, minute: Int) {
        guard let tz = TimeZone(identifier: timezone) else {
            throw NatalError.unknownTimezone(timezone)
        }
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!

        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute
        guard let naive = utcCal.date(from: comps) else {
            throw NatalError.dstGap("유효하지 않은 날짜: \(year)-\(month)-\(day)")
        }

        // TS 원본은 Intl shortOffset을 분 단위 정규식으로 파싱 — 초 단위 오프셋
        // (예: 1908년 이전 서울 LMT +8:27:52)은 파싱 실패로 0 처리되어 DST gap 에러가 된다.
        // 웹과 동일 동작을 위해 이 분 단위 제약을 그대로 재현한다.
        func tsCompatOffset(_ seconds: Int) -> Int {
            seconds % 60 == 0 ? seconds : 0
        }

        let oneDay: TimeInterval = 86400
        let offsetBefore = tsCompatOffset(tz.secondsFromGMT(for: naive.addingTimeInterval(-oneDay)))
        let offsetAfter = tsCompatOffset(tz.secondsFromGMT(for: naive.addingTimeInterval(oneDay)))

        var localCal = Calendar(identifier: .gregorian)
        localCal.timeZone = tz

        var valid: [Date] = []
        for offset in [offsetBefore, offsetAfter] {
            let candidate = naive.addingTimeInterval(-Double(offset))
            let c = localCal.dateComponents([.year, .month, .day, .hour, .minute], from: candidate)
            if c.year == year && c.month == month && c.day == day && c.hour == hour && c.minute == minute {
                valid.append(candidate)
            }
        }

        guard let utc = valid.min(by: { $0.timeIntervalSince1970 < $1.timeIntervalSince1970 }) else {
            let mm = String(format: "%02d", month)
            let dd = String(format: "%02d", day)
            let hh = String(format: "%02d", hour)
            let mi = String(format: "%02d", minute)
            throw NatalError.dstGap(
                "DST gap: \(year)-\(mm)-\(dd) \(hh):\(mi)은(는) \(timezone)에서 서머타임 전환으로 존재하지 않는 시간입니다."
            )
        }

        let u = utcCal.dateComponents([.year, .month, .day, .hour, .minute], from: utc)
        return (u.year!, u.month!, u.day!, u.hour!, u.minute!)
    }

    // MARK: - 메인

    public static func calculateNatal(_ input: NatalInput, houseSystem: String = "P") throws -> NatalChart {
        let lat = input.latitude ?? DEFAULT_LAT
        let lon = input.longitude ?? DEFAULT_LON
        let unknownTime = input.unknownTime

        let hour = unknownTime ? 12 : input.hour
        let minute = unknownTime ? 0 : input.minute

        let utc = try resolveToUtc(
            year: input.year, month: input.month, day: input.day,
            hour: hour, minute: minute, timezone: input.timezone
        )
        let jd = Ephemeris.julday(utc.year, utc.month, utc.day, Double(utc.hour) + Double(utc.minute) / 60)

        var cusps: [Double]? = nil
        var ascmc: [Double]? = nil
        if !unknownTime {
            let houseResult = Houses.calcHouses(jd, lat, lon, houseSystem)
            cusps = houseResult.cusps
            ascmc = houseResult.ascmc
        }

        var planets: [PlanetPosition] = []
        for (id, bodyNum) in PLANET_BODIES {
            let pos = try Ephemeris.calcPlanet(jd, bodyNum)
            planets.append(PlanetPosition(
                id: id,
                longitude: pos.longitude,
                latitude: pos.latitude,
                speed: pos.longitudeSpeed,
                sign: lonToSign(pos.longitude),
                degreeInSign: degreeInSign(pos.longitude),
                isRetrograde: pos.longitudeSpeed < 0,
                house: cusps.map { findHouse(pos.longitude, $0) }
            ))
        }

        let northNode = planets.first { $0.id == "NorthNode" }!
        let southLon = normalizeDeg(northNode.longitude + 180)
        planets.append(PlanetPosition(
            id: "SouthNode",
            longitude: southLon,
            latitude: -northNode.latitude,
            speed: northNode.speed,
            sign: lonToSign(southLon),
            degreeInSign: degreeInSign(southLon),
            isRetrograde: false,
            house: cusps.map { findHouse(southLon, $0) }
        ))

        if let ascmcValues = ascmc, let cuspsValues = cusps {
            let ascLon = ascmcValues[0]
            let sun = planets.first { $0.id == "Sun" }!
            let moon = planets.first { $0.id == "Moon" }!
            let isDayChart = sun.house! >= 7
            let fortunaLon = isDayChart
                ? normalizeDeg(ascLon + moon.longitude - sun.longitude)
                : normalizeDeg(ascLon + sun.longitude - moon.longitude)
            planets.append(PlanetPosition(
                id: "Fortuna",
                longitude: fortunaLon,
                latitude: 0,
                speed: 0,
                sign: lonToSign(fortunaLon),
                degreeInSign: degreeInSign(fortunaLon),
                isRetrograde: false,
                house: findHouse(fortunaLon, cuspsValues)
            ))
        }

        var houses: [NatalHouse] = []
        if let cuspsValues = cusps {
            for i in 1...12 {
                let cuspLon = cuspsValues[i]
                houses.append(NatalHouse(
                    number: i,
                    cuspLongitude: cuspLon,
                    sign: lonToSign(cuspLon),
                    degreeInSign: degreeInSign(cuspLon)
                ))
            }
        }

        var angles: NatalAngles? = nil
        if let ascmcValues = ascmc {
            let ascLon = ascmcValues[0]
            let mcLon = ascmcValues[1]
            let descLon = normalizeDeg(ascLon + 180)
            let icLon = normalizeDeg(mcLon + 180)
            angles = NatalAngles(
                asc: AnglePoint(longitude: ascLon, sign: lonToSign(ascLon), degreeInSign: degreeInSign(ascLon)),
                mc: AnglePoint(longitude: mcLon, sign: lonToSign(mcLon), degreeInSign: degreeInSign(mcLon)),
                desc: AnglePoint(longitude: descLon, sign: lonToSign(descLon), degreeInSign: degreeInSign(descLon)),
                ic: AnglePoint(longitude: icLon, sign: lonToSign(icLon), degreeInSign: degreeInSign(icLon))
            )
        }

        let aspectPlanets = planets.filter { $0.id != "SouthNode" && $0.id != "Fortuna" }
        let aspects = calculateAspects(aspectPlanets)

        return NatalChart(planets: planets, houses: houses, angles: angles, aspects: aspects)
    }
}
