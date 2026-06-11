// HoshinTenGods — fortuneteller src/lib/ten_gods.ts 포팅
// 십성(十星) 계산: 일간(日干)을 기준으로 다른 천간·지지와의 관계를 10가지로 분류

import Foundation

public enum HoshinTenGods {
    // MARK: - 오행 상생/상극 (data/wuxing.ts WUXING_GENERATION / WUXING_DESTRUCTION)

    static let wuxingGeneration: [String: String] = [
        "목": "화", "화": "토", "토": "금", "금": "수", "수": "목",
    ]

    static let wuxingDestruction: [String: String] = [
        "목": "토", "화": "금", "토": "수", "금": "목", "수": "화",
    ]

    static func stemData(korean: String) -> StemData? {
        SajuTables.stems.first { $0.korean == korean }
    }

    // MARK: - calculateTenGod (ts: calculateTenGod)

    /// 일간과 대상 천간을 비교하여 십성 판단
    static func calculateTenGod(dayStem: String, targetStem: String) -> String {
        guard let dayData = stemData(korean: dayStem),
              let targetData = stemData(korean: targetStem) else {
            fatalError("천간 데이터를 찾을 수 없습니다: \(dayStem), \(targetStem)")
        }

        let dayElement = dayData.element
        let dayYinYang = dayData.yinYang
        let targetElement = targetData.element
        let targetYinYang = targetData.yinYang

        // 1. 같은 오행
        if dayElement == targetElement {
            return dayYinYang == targetYinYang ? "비견" : "겁재"
        }

        // 2. 일간이 생(生)하는 오행 - 식신/상관
        if wuxingGeneration[dayElement] == targetElement {
            return dayYinYang == targetYinYang ? "식신" : "상관"
        }

        // 3. 일간이 극(克)하는 오행 - 편재/정재
        if wuxingDestruction[dayElement] == targetElement {
            return dayYinYang == targetYinYang ? "편재" : "정재"
        }

        // 4. 일간을 극(克)하는 오행 - 편관/정관
        if wuxingDestruction[targetElement] == dayElement {
            return dayYinYang == targetYinYang ? "편관" : "정관"
        }

        // 5. 일간을 생(生)하는 오행 - 편인/정인
        if wuxingGeneration[targetElement] == dayElement {
            return dayYinYang == targetYinYang ? "편인" : "정인"
        }

        // 이론적으로 여기 도달하면 안됨
        fatalError("십성 계산 오류: \(dayStem)(\(dayElement)) - \(targetStem)(\(targetElement))")
    }

    // MARK: - generateTenGodsList (ts: generateTenGodsList)

    /// 십성 목록 생성 (사주 8자 각각의 십성)
    public static func generateTenGodsList(_ raw: SajuRawData) -> [String] {
        let dayStem = raw.day.stem
        var tenGods: [String] = []

        // 연주 천간
        if raw.year.stem != dayStem {
            tenGods.append(calculateTenGod(dayStem: dayStem, targetStem: raw.year.stem))
        } else {
            tenGods.append("비견") // 일간과 같으면 비견
        }

        // 월주 천간
        if raw.month.stem != dayStem {
            tenGods.append(calculateTenGod(dayStem: dayStem, targetStem: raw.month.stem))
        } else {
            tenGods.append("비견")
        }

        // 일주 천간 (자기 자신이므로 비견)
        tenGods.append("비견")

        // 시주 천간
        if raw.hour.stem != dayStem {
            tenGods.append(calculateTenGod(dayStem: dayStem, targetStem: raw.hour.stem))
        } else {
            tenGods.append("비견")
        }

        // 지지는 생략 또는 간단히 추가 가능
        return tenGods
    }

    // MARK: - calculateTenGodsDistribution (ts: calculateTenGodsDistribution)

    /// 지지를 대표 천간으로 매핑 (간단 버전) — ts: mapBranchToStem
    static func mapBranchToStem(_ branch: String) -> String? {
        let mapping: [String: String] = [
            "자": "계", "축": "기", "인": "갑", "묘": "을",
            "진": "무", "사": "병", "오": "정", "미": "기",
            "신": "경", "유": "신", "술": "무", "해": "임",
        ]
        return mapping[branch]
    }

    /// 사주 전체의 십성 분포 계산 (지장간 세력 반영)
    public static func calculateTenGodsDistribution(_ raw: SajuRawData) -> [String: Double] {
        var distribution: [String: Double] = [
            "비견": 0, "겁재": 0, "식신": 0, "상관": 0, "편재": 0,
            "정재": 0, "편관": 0, "정관": 0, "편인": 0, "정인": 0,
        ]

        let dayStem = raw.day.stem

        // 연주, 월주, 시주의 천간 (일주 제외)
        let stems = [raw.year.stem, raw.month.stem, raw.hour.stem]

        for stem in stems {
            if stem != dayStem {
                // 일간과 다른 천간만 계산
                let tenGod = calculateTenGod(dayStem: dayStem, targetStem: stem)
                distribution[tenGod, default: 0] += 1
            }
        }

        // 지장간 세력을 직접 반영
        if !raw.jiJangGan.isEmpty {
            let pillars = ["year", "month", "day", "hour"]

            for pillar in pillars {
                guard let jiJangGan = raw.jiJangGan[pillar] else { continue }

                // 정기(正氣) - 주 지장간
                if jiJangGan.primary.stem != dayStem {
                    let tenGod = calculateTenGod(dayStem: dayStem, targetStem: jiJangGan.primary.stem)
                    // 세력을 백분율로 변환하여 가중치로 사용 (0-1 범위)
                    distribution[tenGod, default: 0] += Double(jiJangGan.primary.strength) / 100
                }

                // 중기(中氣) - 보조 지장간
                if let secondary = jiJangGan.secondary, secondary.stem != dayStem {
                    let tenGod = calculateTenGod(dayStem: dayStem, targetStem: secondary.stem)
                    distribution[tenGod, default: 0] += Double(secondary.strength) / 100
                }

                // 여기(餘氣) - 잔여 지장간
                if let residual = jiJangGan.residual, residual.stem != dayStem {
                    let tenGod = calculateTenGod(dayStem: dayStem, targetStem: residual.stem)
                    distribution[tenGod, default: 0] += Double(residual.strength) / 100
                }
            }
        } else {
            // 지장간 정보가 없을 경우 기존 방식 (0.5 가중치)
            let branches = [raw.year.branch, raw.month.branch, raw.day.branch, raw.hour.branch]

            for branch in branches {
                if let branchStem = mapBranchToStem(branch), branchStem != dayStem {
                    let tenGod = calculateTenGod(dayStem: dayStem, targetStem: branchStem)
                    distribution[tenGod, default: 0] += 0.5
                }
            }
        }

        return distribution
    }
}
