// ZiweiKit — 자미두수 명반 엔진 (saju-api lib/ziwei 포팅)
// 타입은 TS ZiweiChart JSON과 1:1 — Codable로 골든 픽스처와 직접 비교한다.

import Foundation

public struct WuXingJu: Codable, Equatable, Sendable {
    public let name: String     // 예: "水二局"
    public let number: Int      // 2~6
}

public struct ZiweiStar: Codable, Equatable, Sendable {
    public let name: String
    public let brightness: String   // 廟/旺/得/利/平/陷 또는 ""
    public let siHua: String        // 化祿/化權/化科/化忌 또는 ""
}

public struct ZiweiPalace: Codable, Equatable, Sendable {
    public let name: String
    public let zhi: String
    public let gan: String
    public let ganZhi: String
    public let stars: [ZiweiStar]   // 배치 순서 보존 (TS Object.entries 순서)
    public let isShenGong: Bool
}

public struct ZiweiChart: Codable, Equatable, Sendable {
    public let solarYear: Int
    public let solarMonth: Int
    public let solarDay: Int
    public let hour: Int
    public let minute: Int
    public let isMale: Bool
    public let lunarYear: Int
    public let lunarMonth: Int
    public let lunarDay: Int
    public let isLeapMonth: Bool
    public let yearGan: String
    public let yearZhi: String
    public let mingGongZhi: String
    public let shenGongZhi: String
    public let wuXingJu: WuXingJu
    public let palaces: [String: ZiweiPalace]
    public let daXianStartAge: Int
}

public struct LiuYueInfo: Codable, Equatable, Sendable {
    public let month: Int
    public let mingGongZhi: String
    public let natalPalaceName: String
}

public struct LiuNianInfo: Codable, Equatable, Sendable {
    public let year: Int
    public let gan: String
    public let zhi: String
    public let mingGongZhi: String
    public let natalPalaceAtMing: String
    public let siHua: [String: String]         // 星 → 化
    public let siHuaPalaces: [String: String]  // 化 → 궁 이름
    public let palaces: [String: String]       // 궁 이름 → 지지
    public let liuyue: [LiuYueInfo]
    public let daxianPalaceName: String
    public let daxianAgeStart: Int
    public let daxianAgeEnd: Int
}

public struct DaxianInfo: Codable, Equatable, Sendable {
    public let ageStart: Int
    public let ageEnd: Int
    public let palaceName: String
    public let ganZhi: String
    public let mainStars: [String]
}
