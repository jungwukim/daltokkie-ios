// 오늘의 달빛 편지 — 그날 운세를 한 줄로 요약 (점수·영역별 결과 기반)
// 제목 = 전반 톤 + 최고 영역 / 본문 = 최고 영역 강조 + 주의·응원 (단정 표현 지양)

import Foundation
import SajuKit

struct MoonLetter {
    let title: String        // 큰 글귀 (3줄)
    let body: String         // 한 줄 요약 (2줄)
}

enum MoonLetters {

    /// 최고 영역 강조 한 줄 (카테고리 = "재물운"…"투자운", 모두 받침 'ㄴ' → 조사 '이')
    private static let areaBest: [String: String] = [
        "재물운": "돈 흐름이 가장 든든해요.",
        "건강운": "컨디션이 가장 좋아요.",
        "연애운": "마음이 가장 잘 통해요.",
        "직장운": "일이 가장 잘 풀려요.",
        "학업운": "집중이 가장 잘 돼요.",
        "대인운": "사람 인연이 가장 좋아요.",
        "여행운": "이동·바깥 활동이 좋아요.",
        "창작운": "아이디어가 가장 잘 떠올라요.",
        "가정운": "집안이 가장 편안해요.",
        "투자운": "투자 감각이 살아 있어요.",
    ]
    /// 최저 영역 주의 한 줄 (점수 50 미만일 때만)
    private static let areaCaution: [String: String] = [
        "재물운": "지출은 조금 아껴보세요.",
        "건강운": "무리는 피하고 쉬어가요.",
        "연애운": "감정은 한 박자 천천히 표현해요.",
        "직장운": "큰 결정은 천천히 내려요.",
        "학업운": "집중 환경을 챙겨보세요.",
        "대인운": "말은 한 번 더 골라보세요.",
        "여행운": "일정은 여유 있게 잡아요.",
        "창작운": "완벽주의는 잠시 내려놔요.",
        "가정운": "집안일은 천천히 조율해요.",
        "투자운": "투자 판단은 미뤄보세요.",
    ]

    /// 날짜로부터 안정적 시드 ("YYYY-MM-DD" → 정수). 같은 날=같은 문구, 날마다 다름
    private static func seed(_ date: String) -> Int {
        abs(date.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) })
    }

    /// 점수/영역별 결과로 '한 줄 요약' 편지 생성. 제목=전반 톤+최고 영역, 본문=최고 영역 + 주의/응원
    /// 같은 점수 구간이 며칠 이어져도 날짜 시드로 문구가 매일 바뀜
    static func summary(from day: DailyFortuneResult) -> MoonLetter {
        let sorted = day.cards.sorted { $0.score > $1.score }
        let top = sorted.first
        let low = sorted.last
        let topName = top?.category ?? "오늘의 기운"
        let s = seed(day.date)
        func pick(_ arr: [String], _ offset: Int = 0) -> String { arr[(s + offset) % arr.count] }

        let title: String
        switch day.overallScore {
        case 65...:
            title = pick([
                "\(topName)이 가장 빛나는 하루",
                "\(topName)부터 기분 좋게 풀리는 하루",
                "오늘은 \(topName)이 활짝 열린 하루",
            ])
        case 45..<65:
            title = pick([
                "\(topName)을 가볍게 챙기기 좋은 하루",
                "\(topName)이 잔잔히 흐르는 하루",
                "무난하게 흘러가는 하루",
            ])
        default:
            title = pick([
                "숨 고르며 충전하기 좋은 하루",
                "\(topName)부터 천천히 챙기는 하루",
                "무리 없이 나를 돌보는 하루",
            ])
        }

        var lines: [String] = []
        if day.overallScore >= 45, let t = top, let best = areaBest[t.category] {
            lines.append(best)
        } else {
            lines.append(pick(["오늘은 무리 없이 편안하게 보내요.",
                               "서두르지 말고 천천히 보내요."], 1))
        }
        if let l = low, l.score < 50, l.category != top?.category, let c = areaCaution[l.category] {
            lines.append(c)
        } else if day.overallScore >= 65 {
            lines.append(pick(["하고 싶은 일이 있다면 지금 움직여요.",
                               "마음먹은 일은 오늘 시작해보세요."], 2))
        } else {
            lines.append(pick(["작은 것부터 차근차근 해보세요.",
                               "가벼운 일부터 하나씩 해봐요."], 2))
        }
        return MoonLetter(title: title, body: lines.joined(separator: "\n"))
    }
}
