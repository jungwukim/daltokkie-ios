// 오늘의 달빛 편지 — 시적 글귀 (시안 무드)
// 행운지수 점수대 + 날짜로 결정 (같은 날 = 같은 글귀, 결정적)

import Foundation

struct MoonLetter {
    let title: String        // 큰 글귀 (2~3줄)
    let body: String         // 작은 위로 문구
}

enum MoonLetters {
    // 점수 높음(70+)
    private static let high: [MoonLetter] = [
        MoonLetter(title: "오늘은\n서두르지 않는 사람이\n가장 멀리 갑니다.",
                   body: "작은 발걸음도 괜찮아요.\n당신의 속도가 당신을 지켜줄 거예요."),
        MoonLetter(title: "빛나는 하루의\n문이 당신 앞에\n열려 있어요.",
                   body: "망설이던 그 일,\n오늘이라면 시작해도 좋아요."),
        MoonLetter(title: "오늘의 당신은\n어디로 가든\n환영받을 거예요.",
                   body: "마음이 이끄는 대로,\n조금 더 대담해져도 괜찮아요."),
    ]
    // 점수 중간(40~69)
    private static let mid: [MoonLetter] = [
        MoonLetter(title: "잔잔한 하루가\n당신을 부드럽게\n감싸줍니다.",
                   body: "특별하지 않아도 괜찮아요.\n평온함이 가장 큰 선물이에요."),
        MoonLetter(title: "오늘은\n천천히 흘러가도\n충분한 날이에요.",
                   body: "조급함은 잠시 내려두고,\n지금 이 순간에 머물러 보세요."),
        MoonLetter(title: "고요한 물결처럼\n오늘이 당신을\n지나갑니다.",
                   body: "큰 파도 없이 잔잔하게,\n그 안에서 쉬어가도 좋아요."),
    ]
    // 점수 낮음(~39)
    private static let low: [MoonLetter] = [
        MoonLetter(title: "오늘은\n쉬어가는 것도\n용기예요.",
                   body: "무리하지 않아도 괜찮아요.\n내일은 분명 더 가벼울 거예요."),
        MoonLetter(title: "달빛 아래\n잠시 숨을 고르는\n하루입니다.",
                   body: "지친 마음을 토닥이며,\n좋아하는 것들로 채워보세요."),
        MoonLetter(title: "충전이 필요한 날,\n당신을 먼저\n아껴주세요.",
                   body: "오늘의 휴식이\n내일의 빛이 되어줄 거예요."),
    ]

    /// 점수 + 날짜로 결정적 선택 (seededRandom 불필요 — 날짜 숫자 기반)
    static func of(score: Int, dateSeed: Int) -> MoonLetter {
        let pool = score >= 70 ? high : (score >= 40 ? mid : low)
        let idx = ((dateSeed % pool.count) + pool.count) % pool.count
        return pool[idx]
    }
}
