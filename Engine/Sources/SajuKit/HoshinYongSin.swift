// HoshinYongSin — 용신(用神) 선정 시스템
// 원본: packages/fortuneteller/src/lib/yong_sin.ts (selectYongSin)
// Swift YongSinInfo는 primaryYongSin/secondaryYongSin/reasoning만 사용하므로
// 윤달 분석(leap_month_analysis)·recommendations 생성부는 결과에 영향이 없어 포팅하지 않는다.

import Foundation

public enum HoshinYongSin {
    /// 용신 선정 메인 함수 (TS selectYongSin — YongSinInfo 필드만 산출)
    public static func selectYongSin(_ raw: SajuRawData) -> YongSinInfo {
        // 1. 일간 강약 판단
        let strengthLevel = raw.dayMasterStrength?.level ?? "medium"
        let dayStemElement = raw.day.stemElement

        let primaryYongSin: String
        var secondaryYongSin: String? = nil
        let reasoning: String

        // 2. 용신 선정 로직
        if strengthLevel == "very_strong" || strengthLevel == "strong" {
            // 일간이 강함 → 설(洩), 극(克)하는 오행이 용신
            let shengElement = getShengElement(dayStemElement) // 일간이 생하는 오행
            let keElement = getKeElement(dayStemElement)       // 일간이 극하는 오행

            primaryYongSin = shengElement   // 식상으로 설기
            secondaryYongSin = keElement    // 재성으로 일간의 힘을 빼냄

            reasoning = "일간(\(dayStemElement))이 \(strengthLevel == "very_strong" ? "매우 " : "")강하므로, 일간의 힘을 설(洩)하거나 소모시키는 \(shengElement)(식상)과 \(keElement)(재성)을 용신으로 삼습니다."
        } else if strengthLevel == "weak" || strengthLevel == "very_weak" {
            // 일간이 약함 → 생(生)하거나 동일 오행이 용신
            let shengMeElement = getShengMeElement(dayStemElement) // 일간을 생하는 오행

            primaryYongSin = shengMeElement      // 인성으로 생기
            secondaryYongSin = dayStemElement    // 비겁으로 돕기

            reasoning = "일간(\(dayStemElement))이 \(strengthLevel == "very_weak" ? "매우 " : "")약하므로, 일간을 생(生)하는 \(shengMeElement)(인성)과 일간과 같은 \(dayStemElement)(비겁)을 용신으로 삼습니다."
        } else {
            // medium - 중화: 가장 약한 오행을 용신으로
            let weakestElement = findWeakestElement(raw)
            primaryYongSin = weakestElement

            reasoning = "사주가 중화되어 있으므로, 가장 약한 오행인 \(weakestElement)를 보강하여 균형을 맞춥니다."
        }

        return YongSinInfo(
            primaryYongSin: primaryYongSin,
            secondaryYongSin: secondaryYongSin,
            reasoning: reasoning
        )
    }

    // MARK: - 오행 상생상극 테이블 (yong_sin.ts private 함수)

    /// 오행 상생 관계: A가 B를 생(生)함 — 목생화, 화생토, 토생금, 금생수, 수생목
    private static func getShengElement(_ element: String) -> String {
        let shengMap: [String: String] = [
            "목": "화",
            "화": "토",
            "토": "금",
            "금": "수",
            "수": "목",
        ]
        return shengMap[element] ?? element
    }

    /// 나를 생(生)하는 오행
    private static func getShengMeElement(_ element: String) -> String {
        let shengMeMap: [String: String] = [
            "목": "수", // 수생목
            "화": "목", // 목생화
            "토": "화", // 화생토
            "금": "토", // 토생금
            "수": "금", // 금생수
        ]
        return shengMeMap[element] ?? element
    }

    /// 오행 상극 관계: A가 B를 극(克)함 — 목극토, 토극수, 수극화, 화극금, 금극목
    private static func getKeElement(_ element: String) -> String {
        let keMap: [String: String] = [
            "목": "토",
            "화": "금",
            "토": "수",
            "금": "목",
            "수": "화",
        ]
        return keMap[element] ?? element
    }

    /// 가장 약한 오행 찾기 (TS findWeakestElement)
    /// Object.entries(wuxingCount) 삽입 순서 = 목→화→토→금→수 재현, 동률 시 앞선 오행 유지(strict <)
    private static func findWeakestElement(_ raw: SajuRawData) -> String {
        let wuxingCount = raw.wuxingCount
        let order = ["목", "화", "토", "금", "수"]

        var weakestElement = "목"
        var minCount = wuxingCount["목"] ?? 0

        for element in order {
            let count = wuxingCount[element] ?? 0
            if count < minCount {
                minCount = count
                weakestElement = element
            }
        }

        return weakestElement
    }
}
