// HoshinStrength — 일간(日干) 강약 판단 시스템
// 원본: packages/fortuneteller/src/lib/day_master_strength.ts (analyzeDayMasterStrength)
//
// 판단 요소:
// 1. 월령 득실 (40%) - 가장 중요
// 2. 비겁(比劫) 개수 (25%) - 같은 오행이 일간을 돕는 정도
// 3. 인성(印星) 개수 (20%) - 일간을 생하는 오행
// 4. 재관식상 개수 (15%) - 일간을 설기하는 오행

import Foundation

public enum HoshinStrength {
    /// 일간 강약 종합 분석 (TS analyzeDayMasterStrength 1:1 포팅)
    public static func analyzeDayMasterStrength(_ raw: SajuRawData) -> DayMasterStrength {
        var score = 50 // 기본 점수
        var reasons: [String] = []

        // 1. 월령 득실 (40점 만점)
        if let wolRyeong = raw.wolRyeong {
            if wolRyeong.strength == "strong" {
                score += 40
                reasons.append("월령을 득하여 매우 강함")
            } else if wolRyeong.strength == "medium" {
                score += 20
                reasons.append("월령이 중립적")
            } else {
                score -= 20
                reasons.append("월령을 실하여 약함")
            }
        }

        // TS: if (sajuData.tenGodsDistribution) — undefined면 스킵.
        // Swift에서는 빈 딕셔너리가 "미설정"에 대응 (파이프라인상 항상 채워져 있음)
        let dist = raw.tenGodsDistribution
        if !dist.isEmpty {
            // 2. 비겁(比劫) 개수 (25점 만점)
            let bijeopCount = (dist["비견"] ?? 0) + (dist["겁재"] ?? 0)
            if bijeopCount >= 4 {
                score += 25
                reasons.append("비겁이 많아 강함")
            } else if bijeopCount >= 2 {
                score += 15
                reasons.append("비겁이 적절함")
            } else if bijeopCount == 1 {
                score += 5
                reasons.append("비겁이 약간 부족")
            } else {
                score -= 10
                reasons.append("비겁이 없어 외로움")
            }

            // 3. 인성(印星) 개수 (20점 만점)
            let inseongCount = (dist["정인"] ?? 0) + (dist["편인"] ?? 0)
            if inseongCount >= 3 {
                score += 20
                reasons.append("인성이 많아 생을 받음")
            } else if inseongCount >= 2 {
                score += 15
                reasons.append("인성이 적절히 있음")
            } else if inseongCount == 1 {
                score += 5
                reasons.append("인성이 약간 있음")
            }

            // 4. 재관식상 개수 (설기 요소)
            var seolgiCount: Double = 0
            for key in ["정재", "편재", "정관", "편관", "식신", "상관"] {
                seolgiCount += dist[key] ?? 0
            }

            if seolgiCount >= 6 {
                score -= 15
                reasons.append("재관식상이 과다하여 설기됨")
            } else if seolgiCount >= 4 {
                score -= 5
                reasons.append("재관식상이 많음")
            }
        }

        // 점수를 0-100 범위로 제한
        score = max(0, min(100, score))

        // 레벨 결정
        let level: String
        if score >= 80 {
            level = "very_strong"
        } else if score >= 65 {
            level = "strong"
        } else if score >= 40 {
            level = "medium"
        } else if score >= 25 {
            level = "weak"
        } else {
            level = "very_weak"
        }

        let analysis = reasons.joined(separator: ". ") + "."

        return DayMasterStrength(level: level, score: score, analysis: analysis)
    }
}
