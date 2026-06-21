// 오늘의 달빛 편지 — 그날 명리(일주·십성·12운성·합충형파해) 기반 코멘트
// 명리 근거를 누구나 알아듣는 현대어 + 경향/조언 톤으로 풀어냄 (단정 표현 지양)

import Foundation
import SajuKit

struct MoonLetter {
    let title: String        // 큰 글귀 (3줄)
    let body: String         // 경향 + 조언 (2줄)
}

enum MoonLetters {

    // MARK: - 십성 → 오늘의 테마 (현대어, 전문용어 없이)
    private static let tenGodTitle: [String: String] = [
        "비견": "나를 믿고\n내 페이스대로\n가기 좋은 날",
        "겁재": "경쟁보다\n내 길에 집중하면\n좋은 날",
        "식신": "여유롭게 즐기는\n마음이 복이 되는\n날",
        "상관": "표현하고 싶은\n마음이 빛나는\n날",
        "편재": "기회가 여기저기\n열려 활동적인\n날",
        "정재": "착실함이\n그대로 쌓이는\n날",
        "편관": "긴장 속에서도\n나를 단단히\n세우는 날",
        "정관": "원칙과 책임이\n빛을 발하는\n날",
        "편인": "생각이 깊어지고\n배움이 당기는\n날",
        "정인": "마음이 차분히\n채워지는\n날",
    ]

    // MARK: - 12운성 → 기운 경향 (1줄, 카드 폭에 맞춰 짧게)
    private static func energyLine(_ stage: String) -> String {
        let strong = ["장생", "관대", "건록", "제왕", "양"]
        let weak = ["쇠", "병", "사", "묘", "절"]
        if strong.contains(stage) { return "기운이 차오르는 흐름이에요." }
        if weak.contains(stage) { return "기운을 아껴 쓰면 좋아요." }
        return "무난하게 흐르는 하루예요."
    }

    // MARK: - 십성 → 오늘 해볼 만한 구체 행동 (그날 십성이 활성화하는 영역 기준)
    private static let tenGodAction: [String: String] = [
        "비견": "비교는 접고 내 일에 집중해보세요.",
        "겁재": "여러 개보다 하나에 힘을 모아보세요.",
        "식신": "좋아하는 걸 먹거나 취미로 충전해요.",
        "상관": "하고 싶은 말·아이디어를 꺼내보세요.",
        "편재": "미뤄둔 기회나 제안을 살펴보기 좋아요.",
        "정재": "할 일과 지출을 차근차근 정리해보세요.",
        "편관": "큰일은 핵심부터 끊어서 처리해요.",
        "정관": "약속·마감 같은 책임을 먼저 챙겨보세요.",
        "편인": "혼자 깊이 생각하거나 새 분야를 살펴봐요.",
        "정인": "책·휴식으로 나를 채우는 시간을 가져요.",
    ]

    // MARK: - 충·형이 어느 기둥과 걸리는지 → 영역별 주의 (일주=가까운 사람, 월주=일/집안, 년주=윗사람, 시주=아랫사람·저녁)
    private static func clashCaution(_ relations: [TransitRelation]) -> String? {
        func hasClash(_ tr: TransitRelation) -> Bool {
            (tr.stemRelations + tr.branchRelations).contains { ["육충", "천간충", "형"].contains($0.type) }
        }
        let caution: [String: String] = [
            "일주": "가까운 사람과는 말에 여유를 두세요.",
            "월주": "일·집안 일은 천천히 조율해보세요.",
            "년주": "윗사람과 엮인 일을 살펴보세요.",
            "시주": "아랫사람·저녁 일정을 챙겨보세요.",
        ]
        for pillar in ["일주", "월주", "년주", "시주"] {
            if relations.contains(where: { $0.natalPillar == pillar && hasClash($0) }) {
                return caution[pillar]
            }
        }
        return relations.contains(where: hasClash) ? "변화가 있을 수 있으니 핵심부터 챙겨요." : nil
    }

    // MARK: - 전치 신살 → 그날의 특별한 기운 (제목 헤드라인)
    private static let sinSalTitle: [String: String] = [
        "천을귀인": "귀인의 손길이\n함께하는\n날",
        "역마": "어디론가\n떠나고 싶은\n날",
        "도화": "사람을 끌어당기는\n매력이 도는\n날",
        "화개": "혼자만의 깊이가\n빛나는\n날",
        "공망": "잠시 비우고\n정리하기 좋은\n날",
    ]
    private static let sinSalAction: [String: String] = [
        "천을귀인": "도움을 청하거나 사람을 만나기 좋아요.",
        "역마": "이동·새 시도·바깥 활동에 좋아요.",
        "도화": "만남·표현·꾸밈에 기운이 좋아요.",
        "화개": "몰입·공부·창작에 좋은 시간이에요.",
        "공망": "큰 결정은 미루고 마무리·정리에 좋아요.",
    ]

    /// 그날 명리로 편지 생성
    /// 제목 = 신살(있으면) > 십성 테마 / 본문 = 기운(12운성) + (충·형 경고 > 신살 행동 > 십성 행동)
    static func generate(from day: DailyFortuneResult, natalDayStem: String, natalDayBranch: String) -> MoonLetter {
        let topSinsal = HoshinSinSal.transitSinSals(
            transitBranch: day.dayBranchKorean,
            natalDayStem: natalDayStem, natalDayBranch: natalDayBranch
        ).first
        let title = topSinsal.flatMap { sinSalTitle[$0] }
            ?? tenGodTitle[day.tenGodOfDay]
            ?? "달빛이\n조용히 당신을\n비추는 날"
        let line2 = clashCaution(day.transitRelations)
            ?? topSinsal.flatMap { sinSalAction[$0] }
            ?? tenGodAction[day.tenGodOfDay]
            ?? "오늘은 내 리듬대로 보내보세요."
        let body = "\(energyLine(day.twelveStageOfDay))\n\(line2)"
        return MoonLetter(title: title, body: body)
    }
}
