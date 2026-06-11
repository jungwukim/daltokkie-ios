// HoshinBranches — fortuneteller src/data/earthly_branches.ts 포팅
// 지지 관계(삼합/삼형/육해), 지장간 세력, 월령 득실 판단

import Foundation

public enum HoshinBranches {
    // MARK: - 삼합(三合) (ts: SAM_HAP)
    // Object.entries 순회 순서 의존 → 삽입 순서 배열로 보존

    static let samHapTable: [(type: String, branches: [String], element: String)] = [
        (type: "수국", branches: ["신", "자", "진"], element: "수"),
        (type: "목국", branches: ["해", "묘", "미"], element: "목"),
        (type: "화국", branches: ["인", "오", "술"], element: "화"),
        (type: "금국", branches: ["사", "유", "축"], element: "금"),
    ]

    /// 삼합 체크 함수 (ts: checkSamHap)
    static func checkSamHap(_ branches: [String]) -> (type: String?, element: String?) {
        let branchSet = Set(branches)

        for entry in samHapTable {
            let hasAll = entry.branches.allSatisfy { branchSet.contains($0) }
            if hasAll {
                return (type: entry.type, element: entry.element)
            }

            // 부분 삼합 (2개만 있어도 약한 영향)
            let count = entry.branches.filter { branchSet.contains($0) }.count
            if count >= 2 {
                return (type: "반\(entry.type)", element: entry.element)
            }
        }

        return (type: nil, element: nil)
    }

    // MARK: - 삼형(三刑) (ts: checkSamHyeong)

    /// 삼형 체크 함수
    static func checkSamHyeong(_ branches: [String]) -> [String] {
        let branchSet = Set(branches)
        var hyeongList: [String] = []

        // 무은지형 체크
        if branchSet.contains("인") && branchSet.contains("사") && branchSet.contains("신") {
            hyeongList.append("무은지형(인사신)")
        }

        // 지세지형 체크
        if branchSet.contains("축") && branchSet.contains("술") && branchSet.contains("미") {
            hyeongList.append("지세지형(축술미)")
        }

        // 무례지형 체크
        if branchSet.contains("자") && branchSet.contains("묘") {
            hyeongList.append("무례지형(자묘)")
        }

        // 자형 체크 (같은 지지가 2개 이상)
        var branchCounts: [String: Int] = [:]
        for b in branches {
            branchCounts[b] = (branchCounts[b] ?? 0) + 1
        }

        for b in ["진", "오", "유", "해"] {
            if let count = branchCounts[b], count >= 2 {
                hyeongList.append("자형(\(b)\(b))")
            }
        }

        return hyeongList
    }

    // MARK: - 육해(六害) (ts: YUK_HAE / checkYukHae)

    static let yukHaeTable: [(String, String)] = [
        ("자", "미"), // 子未害
        ("축", "오"), // 丑午害
        ("인", "사"), // 寅巳害
        ("묘", "진"), // 卯辰害
        ("신", "해"), // 申亥害
        ("유", "술"), // 酉戌害
    ]

    /// 육해 체크 함수
    static func checkYukHae(_ branches: [String]) -> [[String]] {
        let branchSet = Set(branches)
        var haeList: [[String]] = []

        for (b1, b2) in yukHaeTable {
            if branchSet.contains(b1) && branchSet.contains(b2) {
                haeList.append([b1, b2])
            }
        }

        return haeList
    }

    // MARK: - analyzeBranchRelations (ts: analyzeBranchRelations)

    /// 지지 관계 종합 분석
    public static func analyzeBranchRelations(_ branches: [String]) -> BranchRelationsInfo {
        let samHap = checkSamHap(branches)
        let samHyeong = checkSamHyeong(branches)
        let yukHae = checkYukHae(branches)

        return BranchRelationsInfo(
            samHapType: samHap.type,
            samHapElement: samHap.element,
            samHyeong: samHyeong,
            yukHae: yukHae
        )
    }

    // MARK: - 지장간(支藏干) (ts: JI_JANG_GAN)

    static let jiJangGanTable: [String: (primary: String, secondary: String?, residual: String?)] = [
        "자": (primary: "계", secondary: nil, residual: nil),       // 子: 계수만
        "축": (primary: "기", secondary: "신", residual: "계"),     // 丑: 기토, 신금, 계수
        "인": (primary: "갑", secondary: "병", residual: "무"),     // 寅: 갑목, 병화, 무토
        "묘": (primary: "을", secondary: nil, residual: nil),       // 卯: 을목만
        "진": (primary: "무", secondary: "을", residual: "계"),     // 辰: 무토, 을목, 계수
        "사": (primary: "병", secondary: "무", residual: "경"),     // 巳: 병화, 무토, 경금
        "오": (primary: "정", secondary: "기", residual: nil),      // 午: 정화, 기토
        "미": (primary: "기", secondary: "정", residual: "을"),     // 未: 기토, 정화, 을목
        "신": (primary: "경", secondary: "임", residual: "무"),     // 申: 경금, 임수, 무토
        "유": (primary: "신", secondary: nil, residual: nil),       // 酉: 신금만
        "술": (primary: "무", secondary: "신", residual: "정"),     // 戌: 무토, 신금, 정화
        "해": (primary: "임", secondary: "갑", residual: nil),      // 亥: 임수, 갑목
    ]

    /// 지장간 추출 - 지지에서 숨은 천간들을 모두 반환 (ts: extractJiJangGan)
    static func extractJiJangGan(_ branch: String) -> [String] {
        guard let jiJang = jiJangGanTable[branch] else { return [] }
        var stems = [jiJang.primary]
        if let secondary = jiJang.secondary { stems.append(secondary) }
        if let residual = jiJang.residual { stems.append(residual) }
        return stems
    }

    // MARK: - calculateJiJangGanStrength (ts: calculateJiJangGanStrength)

    /// 지장간 세력 계산 (절기 기준)
    /// 절기에 따라 정기/중기/여기의 강도가 달라짐
    /// - Parameter monthIndex: 0-11 (0=입춘~, 1=경칩~, ...)
    public static func calculateJiJangGanStrength(branch: String, monthIndex: Int) -> JiJangGanStrength {
        guard let jiJang = jiJangGanTable[branch] else {
            // TS에서는 잘못된 지지 입력 시 예외 — 유효한 지지만 들어온다고 가정
            return JiJangGanStrength(primary: ("", 0), secondary: nil, residual: nil)
        }

        // 지지와 월령의 관계로 세력 결정
        let branchIndex = SajuTables.branches.firstIndex { $0.korean == branch } ?? -1
        let monthDiff = (monthIndex - branchIndex + 12) % 12

        var primaryStrength = 70   // 기본 정기 세력
        var secondaryStrength = 20 // 기본 중기 세력
        var residualStrength = 10  // 기본 여기 세력

        // 월령과 완전 일치 (당령): 정기가 가장 강함
        if monthDiff == 0 {
            primaryStrength = 90
            secondaryStrength = 7
            residualStrength = 3
        }
        // 전월 (퇴기): 여기가 상대적으로 강함
        else if monthDiff == 11 {
            primaryStrength = 50
            secondaryStrength = 30
            residualStrength = 20
        }
        // 다음월 (진기): 중기가 상대적으로 강함
        else if monthDiff == 1 {
            primaryStrength = 60
            secondaryStrength = 30
            residualStrength = 10
        }
        // 먼 시기: 정기만 약하게
        else {
            primaryStrength = 40
            secondaryStrength = 10
            residualStrength = 5
        }

        var secondary: (String, Int)? = nil
        if let secondaryStem = jiJang.secondary {
            secondary = (secondaryStem, secondaryStrength)
        }

        var residual: (String, Int)? = nil
        if let residualStem = jiJang.residual {
            residual = (residualStem, residualStrength)
        }

        return JiJangGanStrength(
            primary: (jiJang.primary, primaryStrength),
            secondary: secondary,
            residual: residual
        )
    }

    // MARK: - checkWolRyeong (ts: checkWolRyeong)

    /// 월령 득실 판단
    /// 일간이 월지의 지장간으로부터 생을 받거나 같으면 득령(得令)
    /// 극을 받으면 실령(失令)
    public static func checkWolRyeong(dayStem: String, monthBranch: String) -> WolRyeong {
        let jiJangStems = extractJiJangGan(monthBranch)
        guard let dayStemData = SajuTables.stems.first(where: { $0.korean == dayStem }) else {
            return WolRyeong(isDeukRyeong: false, reason: "일간 정보 없음", strength: "medium")
        }

        let dayStemElement = dayStemData.element

        // 정기(primary) 천간의 오행 확인
        guard let firstStem = jiJangStems.first,
              let primaryStemData = SajuTables.stems.first(where: { $0.korean == firstStem }) else {
            return WolRyeong(isDeukRyeong: false, reason: "지장간 정보 없음", strength: "medium")
        }

        let primaryElement = primaryStemData.element

        // 일간과 월지 지장간 정기의 관계
        if dayStemElement == primaryElement {
            return WolRyeong(
                isDeukRyeong: true,
                reason: "월지 지장간과 일간이 같은 \(dayStemElement) 오행이므로 득령입니다",
                strength: "strong"
            )
        }

        // 상생 관계 체크 (월지가 일간을 생)
        let generationMap: [String: String] = [
            "목": "화", "화": "토", "토": "금", "금": "수", "수": "목",
        ]

        if generationMap[primaryElement] == dayStemElement {
            return WolRyeong(
                isDeukRyeong: true,
                reason: "월지 \(primaryElement)이(가) 일간 \(dayStemElement)을(를) 생하므로 득령입니다",
                strength: "medium"
            )
        }

        // 상극 관계 체크 (월지가 일간을 극)
        let destructionMap: [String: String] = [
            "목": "토", "화": "금", "토": "수", "금": "목", "수": "화",
        ]

        if destructionMap[primaryElement] == dayStemElement {
            return WolRyeong(
                isDeukRyeong: false,
                reason: "월지 \(primaryElement)이(가) 일간 \(dayStemElement)을(를) 극하므로 실령입니다",
                strength: "weak"
            )
        }

        return WolRyeong(
            isDeukRyeong: false,
            reason: "월지와 일간의 관계가 중립적입니다",
            strength: "medium"
        )
    }
}
