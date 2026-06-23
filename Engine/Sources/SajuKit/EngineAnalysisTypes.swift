// EngineAnalysisTypes — saju-api lib/saju/saju-engine.ts 분석 함수 출력 타입 포팅
// ⚠️ 프로퍼티명 = TS 객체 키 이름 (Codable 기본 키 사용, 골든 픽스처가 JSON 키를 검증)

import Foundation

// MARK: - 입력: 사주 4기둥 (TS pillars 객체 등가)

public struct SajuPillars: Equatable, Sendable {
    public let year: UIPillar
    public let month: UIPillar
    public let day: UIPillar
    public let hour: UIPillar?

    public init(year: UIPillar, month: UIPillar, day: UIPillar, hour: UIPillar?) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }
}

// MARK: - 십성(十神)

public struct TenGodPillar: Codable, Equatable, Sendable {
    public let stem: String
    public let branch: String

    public init(stem: String, branch: String) {
        self.stem = stem
        self.branch = branch
    }
}

public struct TenGodChart: Codable, Equatable, Sendable {
    public let year: TenGodPillar
    public let month: TenGodPillar
    public let day: TenGodPillar
    public let hour: TenGodPillar?

    public init(year: TenGodPillar, month: TenGodPillar, day: TenGodPillar, hour: TenGodPillar?) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }

    // TS는 hour: null을 명시적으로 출력 → nil도 JSON null로 인코딩
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(year, forKey: .year)
        try c.encode(month, forKey: .month)
        try c.encode(day, forKey: .day)
        try c.encode(hour, forKey: .hour)
    }
}

// MARK: - 12운성(十二運星)

public struct TwelveStagePillar: Codable, Equatable, Sendable {
    public let stage: String
    public let period: String

    public init(stage: String, period: String) {
        self.stage = stage
        self.period = period
    }
}

public struct TwelveStageChart: Codable, Equatable, Sendable {
    public let year: TwelveStagePillar
    public let month: TwelveStagePillar
    public let day: TwelveStagePillar
    public let hour: TwelveStagePillar?

    public init(year: TwelveStagePillar, month: TwelveStagePillar, day: TwelveStagePillar, hour: TwelveStagePillar?) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }

    // TS는 hour: null을 명시적으로 출력 → nil도 JSON null로 인코딩
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(year, forKey: .year)
        try c.encode(month, forKey: .month)
        try c.encode(day, forKey: .day)
        try c.encode(hour, forKey: .hour)
    }
}

public struct TwelveStageDescription: Codable, Equatable, Sendable {
    public let emoji: String
    public let meaning: String
    public let strength: String   // 강/중/약

    public init(emoji: String, meaning: String, strength: String) {
        self.emoji = emoji
        self.meaning = meaning
        self.strength = strength
    }
}

// MARK: - 지장간(地藏干)

public struct HiddenStem: Codable, Equatable, Sendable {
    public let stem: String
    public let element: String
    public let type: String       // 여기/중기/본기
    public let ratio: Int
    public let tenGod: String?    // dayMaster 정보가 있을 때만 존재 (TS optional 필드)

    public init(stem: String, element: String, type: String, ratio: Int, tenGod: String? = nil) {
        self.stem = stem
        self.element = element
        self.type = type
        self.ratio = ratio
        self.tenGod = tenGod
    }
}

public struct HiddenStemsChart: Codable, Equatable, Sendable {
    public let year: [HiddenStem]
    public let month: [HiddenStem]
    public let day: [HiddenStem]
    public let hour: [HiddenStem]?

    public init(year: [HiddenStem], month: [HiddenStem], day: [HiddenStem], hour: [HiddenStem]?) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
    }

    // TS는 hour: null을 명시적으로 출력 → nil도 JSON null로 인코딩
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(year, forKey: .year)
        try c.encode(month, forKey: .month)
        try c.encode(day, forKey: .day)
        try c.encode(hour, forKey: .hour)
    }
}

// MARK: - 합충형파해(合沖刑破害)

public struct BranchRelation: Codable, Equatable, Sendable {
    public let type: String        // 합/충/형/파/해/원진/귀문관살
    public let typeName: String
    public let branches: [String]
    public let branchesKorean: [String]
    public let pillars: [String]
    public let description: String

    public init(type: String, typeName: String, branches: [String], branchesKorean: [String], pillars: [String], description: String) {
        self.type = type
        self.typeName = typeName
        self.branches = branches
        self.branchesKorean = branchesKorean
        self.pillars = pillars
        self.description = description
    }
}

public struct MultiRelation: Codable, Equatable, Sendable {
    public let type: String        // 삼합/반합/방합
    public let typeName: String
    public let branches: [String]
    public let branchesKorean: [String]
    public let pillars: [String]
    public let description: String
    public let resultElement: String

    public init(type: String, typeName: String, branches: [String], branchesKorean: [String], pillars: [String], description: String, resultElement: String) {
        self.type = type
        self.typeName = typeName
        self.branches = branches
        self.branchesKorean = branchesKorean
        self.pillars = pillars
        self.description = description
        self.resultElement = resultElement
    }
}

public struct StemRelation: Codable, Equatable, Sendable {
    public let type: String        // 천간합/천간충
    public let typeName: String
    public let stems: [String]
    public let stemsKorean: [String]
    public let pillars: [String]
    public let description: String
    public let resultElement: String?

    public init(type: String, typeName: String, stems: [String], stemsKorean: [String], pillars: [String], description: String, resultElement: String? = nil) {
        self.type = type
        self.typeName = typeName
        self.stems = stems
        self.stemsKorean = stemsKorean
        self.pillars = pillars
        self.description = description
        self.resultElement = resultElement
    }
}

// MARK: - 공망(空亡)

public struct GongMangResult: Codable, Equatable, Sendable {
    public let group: String
    public let voidBranches: [String]
    public let voidBranchesKorean: [String]
    public let affectedPillars: [String]
    public let description: String

    public init(group: String, voidBranches: [String], voidBranchesKorean: [String], affectedPillars: [String], description: String) {
        self.group = group
        self.voidBranches = voidBranches
        self.voidBranchesKorean = voidBranchesKorean
        self.affectedPillars = affectedPillars
        self.description = description
    }
}

// MARK: - 12신살(十二神殺)

public struct TwelveSpiritEntry: Codable, Equatable, Sendable {
    public let pillar: String
    public let branchHanja: String
    public let branchKorean: String
    public let spiritHanja: String
    public let spiritHangul: String
    public let spiritType: String   // 길신/흉살/중성
    public let description: String

    public init(pillar: String, branchHanja: String, branchKorean: String, spiritHanja: String, spiritHangul: String, spiritType: String, description: String) {
        self.pillar = pillar
        self.branchHanja = branchHanja
        self.branchKorean = branchKorean
        self.spiritHanja = spiritHanja
        self.spiritHangul = spiritHangul
        self.spiritType = spiritType
        self.description = description
    }
}

// MARK: - 확장 신살(神殺)

public struct SpecialSalEntry: Codable, Equatable, Sendable {
    public let name: String
    public let hanja: String
    public let type: String         // 길신/흉살/중성
    public let pillarIndices: [Int]
    public let description: String

    public init(name: String, hanja: String, type: String, pillarIndices: [Int], description: String) {
        self.name = name
        self.hanja = hanja
        self.type = type
        self.pillarIndices = pillarIndices
        self.description = description
    }
}

// MARK: - 좌법(坐法)

public struct JwaEntry: Codable, Equatable, Sendable {
    public let stem: String
    public let stemKorean: String
    public let sipsin: String
    public let unseong: String

    public init(stem: String, stemKorean: String, sipsin: String, unseong: String) {
        self.stem = stem
        self.stemKorean = stemKorean
        self.sipsin = sipsin
        self.unseong = unseong
    }
}

public typealias JwabeopChart = [[JwaEntry]]

// MARK: - 일주 성향 분석 (누락 십성 양간 시딩)

public struct InjongEntry: Codable, Equatable, Sendable {
    public let category: String
    public let categoryHanja: String
    public let yangStem: String
    public let yangStemKorean: String
    public let unseong: String

    public init(category: String, categoryHanja: String, yangStem: String, yangStemKorean: String, unseong: String) {
        self.category = category
        self.categoryHanja = categoryHanja
        self.yangStem = yangStem
        self.yangStemKorean = yangStemKorean
        self.unseong = unseong
    }
}

// MARK: - 신강/신약

public struct StrengthDetail: Codable, Equatable, Sendable {
    public let score: Double
    public let description: String

    public init(score: Double, description: String) {
        self.score = score
        self.description = description
    }
}

public struct StrengthDetails: Codable, Equatable, Sendable {
    public let deukryeong: StrengthDetail
    public let deukji: StrengthDetail
    public let deukse: StrengthDetail

    public init(deukryeong: StrengthDetail, deukji: StrengthDetail, deukse: StrengthDetail) {
        self.deukryeong = deukryeong
        self.deukji = deukji
        self.deukse = deukse
    }
}

public struct StrengthAnalysis: Codable, Equatable, Sendable {
    public let score: Int
    public let isStrong: Bool
    public let label: String
    public let details: StrengthDetails

    public init(score: Int, isStrong: Bool, label: String, details: StrengthDetails) {
        self.score = score
        self.isStrong = isStrong
        self.label = label
        self.details = details
    }
}

// MARK: - 용신(用神)

public struct YongsinElement: Codable, Equatable, Sendable {
    public let element: String
    public let elementKo: String
    public let tenGod: String
    public let description: String

    public init(element: String, elementKo: String, tenGod: String, description: String) {
        self.element = element
        self.elementKo = elementKo
        self.tenGod = tenGod
        self.description = description
    }
}

public struct YongsinAnalysis: Codable, Equatable, Sendable {
    public let yongsin: YongsinElement
    public let heesin: YongsinElement
    public let gisin: YongsinElement
    public let gisinSecondary: YongsinElement?

    public init(yongsin: YongsinElement, heesin: YongsinElement, gisin: YongsinElement, gisinSecondary: YongsinElement? = nil) {
        self.yongsin = yongsin
        self.heesin = heesin
        self.gisin = gisin
        self.gisinSecondary = gisinSecondary
    }
}

// MARK: - 월운(月運) — 한 해 12개월 월주

public struct MonthlyPillar: Codable, Equatable, Sendable {
    public let month: Int
    public let stemHanja: String
    public let stemKorean: String
    public let stemElement: String
    public let branchHanja: String
    public let branchKorean: String
    public let branchElement: String
    public let tenGodStem: String
    public let tenGodBranch: String
    public let twelveStage: String

    public init(month: Int, stemHanja: String, stemKorean: String, stemElement: String, branchHanja: String, branchKorean: String, branchElement: String, tenGodStem: String, tenGodBranch: String, twelveStage: String) {
        self.month = month
        self.stemHanja = stemHanja
        self.stemKorean = stemKorean
        self.stemElement = stemElement
        self.branchHanja = branchHanja
        self.branchKorean = branchKorean
        self.branchElement = branchElement
        self.tenGodStem = tenGodStem
        self.tenGodBranch = tenGodBranch
        self.twelveStage = twelveStage
    }
}

// MARK: - 세운(歲運)

public struct YearFortune: Codable, Equatable, Sendable {
    public let year: Int
    public let stemHanja: String
    public let stemKorean: String
    public let stemElement: String
    public let branchHanja: String
    public let branchKorean: String
    public let branchElement: String
    public let branchAnimal: String
    public let tenGodStem: String
    public let tenGodBranch: String
    public let twelveStage: String

    public init(year: Int, stemHanja: String, stemKorean: String, stemElement: String, branchHanja: String, branchKorean: String, branchElement: String, branchAnimal: String, tenGodStem: String, tenGodBranch: String, twelveStage: String) {
        self.year = year
        self.stemHanja = stemHanja
        self.stemKorean = stemKorean
        self.stemElement = stemElement
        self.branchHanja = branchHanja
        self.branchKorean = branchKorean
        self.branchElement = branchElement
        self.branchAnimal = branchAnimal
        self.tenGodStem = tenGodStem
        self.tenGodBranch = tenGodBranch
        self.twelveStage = twelveStage
    }
}
