// SajuKit — 사주팔자 엔진 (hoshin @hoshin/saju-mcp-server + saju-api lib/saju 포팅)
// 기본 데이터: 천간 10 / 지지 12 / 한자·영문 변환 테이블

import Foundation

// MARK: - 천간/지지 데이터

public struct StemData: Sendable {
    public let korean: String
    public let hanja: String
    public let element: String   // 목/화/토/금/수
    public let yinYang: String   // 양/음
    public let index: Int
}

public struct BranchData: Sendable {
    public let korean: String
    public let hanja: String
    public let element: String
    public let yinYang: String   // hoshin 테이블 값 (子=양 등)
    public let animalKo: String
    public let index: Int
}

public enum SajuTables {
    public static let stems: [StemData] = [
        StemData(korean: "갑", hanja: "甲", element: "목", yinYang: "양", index: 0),
        StemData(korean: "을", hanja: "乙", element: "목", yinYang: "음", index: 1),
        StemData(korean: "병", hanja: "丙", element: "화", yinYang: "양", index: 2),
        StemData(korean: "정", hanja: "丁", element: "화", yinYang: "음", index: 3),
        StemData(korean: "무", hanja: "戊", element: "토", yinYang: "양", index: 4),
        StemData(korean: "기", hanja: "己", element: "토", yinYang: "음", index: 5),
        StemData(korean: "경", hanja: "庚", element: "금", yinYang: "양", index: 6),
        StemData(korean: "신", hanja: "辛", element: "금", yinYang: "음", index: 7),
        StemData(korean: "임", hanja: "壬", element: "수", yinYang: "양", index: 8),
        StemData(korean: "계", hanja: "癸", element: "수", yinYang: "음", index: 9),
    ]

    public static let branches: [BranchData] = [
        BranchData(korean: "자", hanja: "子", element: "수", yinYang: "양", animalKo: "쥐", index: 0),
        BranchData(korean: "축", hanja: "丑", element: "토", yinYang: "음", animalKo: "소", index: 1),
        BranchData(korean: "인", hanja: "寅", element: "목", yinYang: "양", animalKo: "호랑이", index: 2),
        BranchData(korean: "묘", hanja: "卯", element: "목", yinYang: "음", animalKo: "토끼", index: 3),
        BranchData(korean: "진", hanja: "辰", element: "토", yinYang: "양", animalKo: "용", index: 4),
        BranchData(korean: "사", hanja: "巳", element: "화", yinYang: "음", animalKo: "뱀", index: 5),
        BranchData(korean: "오", hanja: "午", element: "화", yinYang: "양", animalKo: "말", index: 6),
        BranchData(korean: "미", hanja: "未", element: "토", yinYang: "음", animalKo: "양", index: 7),
        BranchData(korean: "신", hanja: "申", element: "금", yinYang: "양", animalKo: "원숭이", index: 8),
        BranchData(korean: "유", hanja: "酉", element: "금", yinYang: "음", animalKo: "닭", index: 9),
        BranchData(korean: "술", hanja: "戌", element: "토", yinYang: "양", animalKo: "개", index: 10),
        BranchData(korean: "해", hanja: "亥", element: "수", yinYang: "음", animalKo: "돼지", index: 11),
    ]

    public static func stem(at index: Int) -> StemData {
        stems[((index % 10) + 10) % 10]
    }

    public static func branch(at index: Int) -> BranchData {
        branches[((index % 12) + 12) % 12]
    }

    public static func stemIndex(korean: String) -> Int {
        stems.firstIndex { $0.korean == korean } ?? -1
    }

    // 변환 테이블 (fortuneteller.ts)
    public static let elementKrToEn: [String: String] = [
        "목": "Wood", "화": "Fire", "토": "Earth", "금": "Metal", "수": "Water",
    ]
    public static let yinYangKrToEn: [String: String] = ["양": "Yang", "음": "Yin"]
    public static let branchAnimalEn: [String: String] = [
        "자": "Rat", "축": "Ox", "인": "Tiger", "묘": "Rabbit", "진": "Dragon", "사": "Snake",
        "오": "Horse", "미": "Goat", "신": "Monkey", "유": "Rooster", "술": "Dog", "해": "Pig",
    ]
    /// 지지 고유 음양 (UI 표기용 — hoshin Pillar.yinYang은 천간 기준)
    public static let branchYinYang: [String: String] = [
        "자": "양", "축": "음", "인": "양", "묘": "음", "진": "양", "사": "음",
        "오": "양", "미": "음", "신": "양", "유": "음", "술": "양", "해": "음",
    ]

    /// 지역 경도 (saju-api lib/saju/constants.ts REGION_LONGITUDES — 정확히 동일해야 함.
    /// 미등록 지역(예: 울릉도)은 서울 폴백 — TS `?? SEOUL_LNG` 동작 재현)
    public static let regionLongitudes: [String: Double] = [
        "서울": 126.98, "부산": 129.03, "대구": 128.6, "인천": 126.71,
        "광주": 126.85, "대전": 127.39, "울산": 129.31, "세종": 127.0,
        "수원": 127.01, "제주": 126.53, "춘천": 127.73, "청주": 127.49,
        "전주": 127.15, "포항": 129.37, "창원": 128.68, "강릉": 128.9,
        "목포": 126.39, "여수": 127.66, "안동": 128.73, "속초": 128.59,
    ]
}

// MARK: - 기둥/사주 데이터

/// hoshin Pillar 등가 (한국어 네이티브)
public struct FtPillar: Equatable, Sendable {
    public let stem: String          // 갑~계
    public let branch: String        // 자~해
    public let stemElement: String   // 목~수
    public let branchElement: String
    public let yinYang: String       // 천간 음양
}

/// hoshin SajuData 등가 — 분석 필드는 분석 모듈이 채움
public struct SajuRawData: Sendable {
    public let year: FtPillar
    public let month: FtPillar
    public let day: FtPillar
    public let hour: FtPillar
    public let wuxingCount: [String: Int]          // 목/화/토/금/수
    public let gender: String                      // male/female
    public let birthDate: String                   // 양력 YYYY-MM-DD (보정 전 입력)
    public let adjustedInstant: Date               // 경도 보정 적용된 시각 (대운 기산용)
    public let monthIndex: Int                     // 절기 기반 월 인덱스 (지장간용)

    // 분석 결과 (SajuAnalysis가 채움)
    public var tenGods: [String] = []
    public var tenGodsDistribution: [String: Double] = [:]
    public var sinSals: [String] = []
    public var jiJangGan: [String: JiJangGanStrength] = [:]   // year/month/day/hour
    public var wolRyeong: WolRyeong? = nil
    public var dayMasterStrength: DayMasterStrength? = nil
    public var gyeokGuk: GyeokGukInfo? = nil
    public var yongSin: YongSinInfo? = nil
    public var branchRelations: BranchRelationsInfo? = nil
}

public struct JiJangGanStrength: Equatable, Sendable {
    public let primary: (stem: String, strength: Int)
    public let secondary: (stem: String, strength: Int)?
    public let residual: (stem: String, strength: Int)?

    public init(primary: (String, Int), secondary: (String, Int)?, residual: (String, Int)?) {
        self.primary = primary
        self.secondary = secondary
        self.residual = residual
    }

    public static func == (lhs: JiJangGanStrength, rhs: JiJangGanStrength) -> Bool {
        lhs.primary == rhs.primary
            && lhs.secondary?.stem == rhs.secondary?.stem && lhs.secondary?.strength == rhs.secondary?.strength
            && lhs.residual?.stem == rhs.residual?.stem && lhs.residual?.strength == rhs.residual?.strength
    }
}

public struct WolRyeong: Equatable, Sendable {
    public let isDeukRyeong: Bool
    public let reason: String
    public let strength: String   // strong/medium/weak
}

public struct DayMasterStrength: Equatable, Sendable {
    public let level: String      // very_strong/strong/medium/weak/very_weak
    public let score: Int
    public let analysis: String
}

public struct GyeokGukInfo: Equatable, Sendable {
    public let gyeokGuk: String
    public let name: String
    public let hanja: String
    public let description: String
}

public struct YongSinInfo: Equatable, Sendable {
    public let primaryYongSin: String     // 목~수
    public let secondaryYongSin: String?
    public let reasoning: String
}

public struct BranchRelationsInfo: Equatable, Sendable {
    public let samHapType: String?
    public let samHapElement: String?
    public let samHyeong: [String]
    public let yukHae: [[String]]
}

// MARK: - UI 결과 타입 (FortuneTellerResult 등가)

public struct UIStem: Codable, Equatable, Sendable {
    public let hanja: String
    public let korean: String
    public let element: String    // Wood~Water
    public let yin_yang: String   // Yang/Yin
}

public struct UIBranch: Codable, Equatable, Sendable {
    public let hanja: String
    public let korean: String
    public let animal: String
    public let element: String
    public let yin_yang: String
}

public struct UIPillar: Codable, Equatable, Sendable {
    public let stem: UIStem
    public let branch: UIBranch
}

public struct SajuElements: Codable, Equatable, Sendable {
    public let counts: [String: Int]
    public let dominant: String
    public let weakest: String
    public let total: Int
}

public struct DayMasterProfile: Codable, Equatable, Sendable {
    public let name: String
    public let image: String
    public let traits: String
}

public struct FortuneTellerResult: Sendable {
    public let pillars: (year: UIPillar, month: UIPillar, day: UIPillar, hour: UIPillar?)
    public let elements: SajuElements
    public let energyFlow: String        // 순행(順行)/역행(逆行)
    public let gender: String
    public let dayMaster: UIStem
    public let dayMasterProfile: DayMasterProfile?
    public let animal: String
    public let displayHanja: String
    public let displayKorean: String
    public var raw: SajuRawData
}

public enum SajuError: Error, CustomStringConvertible {
    case invalidInput(String)
    case outOfRange(String)

    public var description: String {
        switch self {
        case .invalidInput(let msg): return "유효하지 않은 입력: \(msg)"
        case .outOfRange(let msg): return "지원 범위 밖: \(msg)"
        }
    }
}

/// 일간 프로필 (fortuneteller.ts DAY_MASTER_PROFILES)
public enum DayMasterProfiles {
    public static let table: [String: DayMasterProfile] = [
        "甲": DayMasterProfile(name: "갑목(甲木) 양", image: "큰 나무", traits: "리더십, 야망, 직진성, 개척 정신. 큰 나무처럼 곧게 뻗어 올라가며, 원칙적이고 때로는 고집이 있습니다."),
        "乙": DayMasterProfile(name: "을목(乙木) 음", image: "풀과 덩굴", traits: "유연성, 외교력, 예술적 감각, 적응력. 덩굴처럼 장애물을 감싸 안으며, 부드럽지만 끈질깁니다."),
        "丙": DayMasterProfile(name: "병화(丙火) 양", image: "태양", traits: "카리스마, 낙관, 따뜻함, 주목받는 존재. 태양처럼 관대하고 밝으며, 자연스럽게 시선을 끕니다."),
        "丁": DayMasterProfile(name: "정화(丁火) 음", image: "촛불", traits: "온기, 섬세함, 우아함, 내면의 열정. 촛불처럼 은밀하고 통찰력 있으며, 미세하게 밝힙니다."),
        "戊": DayMasterProfile(name: "무토(戊土) 양", image: "산", traits: "안정감, 신뢰, 인내, 묵직한 존재감. 산처럼 흔들리지 않고 믿음직하며, 보호하는 힘이 있습니다."),
        "己": DayMasterProfile(name: "기토(己土) 음", image: "비옥한 농지", traits: "양육, 실용성, 자원 활용, 꾸준한 성장. 기름진 토양처럼 타인을 키우며, 겸손하지만 생산적입니다."),
        "庚": DayMasterProfile(name: "경금(庚金) 양", image: "칼/쇠", traits: "결단력, 절제, 정의감, 날카로움. 칼날처럼 원칙적이고, 모호함을 잘라내며, 완벽주의적입니다."),
        "辛": DayMasterProfile(name: "신금(辛金) 음", image: "보석", traits: "세련됨, 감수성, 미적 감각, 높은 기준. 보석처럼 압력 속에서 빛나며, 안목이 뛰어납니다."),
        "壬": DayMasterProfile(name: "임수(壬水) 양", image: "바다/큰 강", traits: "지혜, 포용력, 야망, 적응력. 바다처럼 깊고 강력하며, 모든 것을 아우릅니다."),
        "癸": DayMasterProfile(name: "계수(癸水) 음", image: "비/이슬", traits: "직관, 공감, 창의성, 고요한 깊이. 빗물처럼 조용히 스며들며, 숨겨진 곳까지 도달합니다."),
    ]
}
