// 타로 카드 데이터 — 웹 lib/tarot/cards.ts 그대로 포팅 (78장 키워드/스프레드/결정적 드로우)

import Foundation

struct TarotCardData: Identifiable {
    let id: Int
    let name: String        // 영문
    let nameKo: String
    let arcana: String      // major / minor
    let suit: String?       // wands/cups/swords/pentacles
    let rank: String?       // Ace..King
    let keywords: [String]
    let keywordsReversed: [String]

    /// iOS 에셋명 (tarot-major-NN / tarot-<suit>-<ace|02..10|page|knight|queen|king>)
    var asset: String {
        if arcana == "major" { return String(format: "tarot-major-%02d", id) }
        guard let suit, let rank else { return "tarot-back" }
        let suffix: String
        switch rank {
        case "Ace": suffix = "ace"
        case "Page": suffix = "page"
        case "Knight": suffix = "knight"
        case "Queen": suffix = "queen"
        case "King": suffix = "king"
        default:
            let nums = ["Two": 2, "Three": 3, "Four": 4, "Five": 5, "Six": 6, "Seven": 7, "Eight": 8, "Nine": 9, "Ten": 10]
            suffix = String(format: "%02d", nums[rank] ?? 0)
        }
        return "tarot-\(suit)-\(suffix)"
    }
}

struct TarotDrawn: Identifiable {
    let id = UUID()
    let card: TarotCardData
    let isReversed: Bool
    let position: String
}

enum TarotSpread: String, CaseIterable {
    case one, three, celtic
    var label: String { ["one": "원카드", "three": "쓰리카드", "celtic": "켈틱크로스"][rawValue]! }
    var count: Int { positions.count }
    var positions: [String] {
        switch self {
        case .one: return ["현재 메시지"]
        case .three: return ["과거", "현재", "미래"]
        case .celtic: return ["현재 상황", "도전/장애", "의식", "무의식", "과거", "미래", "자기 자신", "주변 환경", "희망/두려움", "최종 결과"]
        }
    }
    var desc: String {
        switch self {
        case .one: return "오늘의 한 장"
        case .three: return "과거·현재·미래"
        case .celtic: return "10장 심층 리딩"
        }
    }
}

enum TarotData {
    static let topics: [(value: String, label: String, emoji: String)] = [
        ("general", "전체운", "🌟"), ("love", "연애", "💕"), ("career", "직장", "💼"),
        ("money", "재물", "💰"), ("study", "학업", "📚"), ("health", "건강", "💪"),
    ]

    static let major: [TarotCardData] = [
        m(0, "The Fool", "바보", ["새로운 시작", "자유", "모험"], ["무모함", "방향 상실", "경솔함"]),
        m(1, "The Magician", "마법사", ["창조력", "의지력", "능력"], ["속임수", "미숙함", "재능 낭비"]),
        m(2, "The High Priestess", "여사제", ["직관", "신비", "내면의 지혜"], ["비밀", "감춰진 진실", "불안"]),
        m(3, "The Empress", "여황제", ["풍요", "모성", "자연"], ["의존", "과잉보호", "창조력 결핍"]),
        m(4, "The Emperor", "황제", ["권위", "안정", "리더십"], ["독재", "경직", "권력 남용"]),
        m(5, "The Hierophant", "교황", ["전통", "가르침", "신앙"], ["고정관념", "반항", "형식주의"]),
        m(6, "The Lovers", "연인", ["사랑", "조화", "선택"], ["불균형", "갈등", "잘못된 선택"]),
        m(7, "The Chariot", "전차", ["승리", "의지", "전진"], ["좌절", "통제 불능", "공격성"]),
        m(8, "Strength", "힘", ["용기", "인내", "내면의 힘"], ["자기 의심", "나약함", "포기"]),
        m(9, "The Hermit", "은둔자", ["성찰", "지혜", "고독"], ["고립", "외로움", "현실 도피"]),
        m(10, "The Wheel of Fortune", "운명의 수레바퀴", ["전환점", "행운", "순환"], ["악순환", "불운", "저항"]),
        m(11, "Justice", "정의", ["공정", "진실", "균형"], ["불공정", "편견", "책임 회피"]),
        m(12, "The Hanged Man", "매달린 사람", ["희생", "새 관점", "기다림"], ["지연", "헛된 희생", "이기심"]),
        m(13, "Death", "죽음", ["변화", "끝과 시작", "전환"], ["변화 거부", "정체", "집착"]),
        m(14, "Temperance", "절제", ["균형", "조화", "인내"], ["과도함", "불균형", "조급함"]),
        m(15, "The Devil", "악마", ["유혹", "속박", "욕망"], ["해방", "집착 끊기", "자각"]),
        m(16, "The Tower", "탑", ["급변", "붕괴", "깨달음"], ["파괴 회피", "저항", "두려움"]),
        m(17, "The Star", "별", ["희망", "영감", "치유"], ["절망", "신뢰 상실", "불안"]),
        m(18, "The Moon", "달", ["환상", "불안", "잠재의식"], ["착각", "혼란 해소", "진실 직면"]),
        m(19, "The Sun", "태양", ["기쁨", "성공", "활력"], ["낙관 과잉", "기대 좌절", "자만"]),
        m(20, "Judgement", "심판", ["부활", "각성", "결단"], ["후회", "자기 비판", "결단 지연"]),
        m(21, "The World", "세계", ["완성", "달성", "통합"], ["미완성", "지연", "아쉬움"]),
    ]

    static let all: [TarotCardData] = major + minors()

    // MARK: - 마이너 아르카나 생성 (웹 generateMinorArcana)
    private static let suitKo = ["wands": "완드", "cups": "컵", "swords": "소드", "pentacles": "펜타클"]
    private static let ranks: [(String, String)] = [
        ("Ace", "에이스"), ("Two", "2"), ("Three", "3"), ("Four", "4"), ("Five", "5"), ("Six", "6"), ("Seven", "7"),
        ("Eight", "8"), ("Nine", "9"), ("Ten", "10"), ("Page", "시종"), ("Knight", "기사"), ("Queen", "여왕"), ("King", "왕"),
    ]

    private static func minors() -> [TarotCardData] {
        var cards: [TarotCardData] = []
        var id = 22
        for suit in ["wands", "cups", "swords", "pentacles"] {
            for (rank, ko) in ranks {
                let kw = suitKeywords[suit]!
                cards.append(TarotCardData(
                    id: id, name: "\(rank) of \(suit.prefix(1).uppercased() + suit.dropFirst())",
                    nameKo: "\(suitKo[suit]!) \(ko)", arcana: "minor", suit: suit, rank: rank,
                    keywords: kw.up[rank]!, keywordsReversed: kw.rev[rank]!))
                id += 1
            }
        }
        return cards
    }

    private static func m(_ id: Int, _ n: String, _ ko: String, _ k: [String], _ kr: [String]) -> TarotCardData {
        TarotCardData(id: id, name: n, nameKo: ko, arcana: "major", suit: nil, rank: nil, keywords: k, keywordsReversed: kr)
    }

    // MARK: - 수트별 키워드 (웹 SUIT_KEYWORDS)
    private static let suitKeywords: [String: (up: [String: [String]], rev: [String: [String]])] = [
        "wands": (
            up: ["Ace": ["영감", "새 기회", "잠재력"], "Two": ["계획", "결정", "미래 비전"], "Three": ["확장", "성장", "리더십"],
                 "Four": ["축하", "안정", "조화"], "Five": ["경쟁", "갈등", "도전"], "Six": ["승리", "인정", "자신감"],
                 "Seven": ["방어", "끈기", "신념"], "Eight": ["속도", "진전", "행동력"], "Nine": ["인내", "회복력", "결단"],
                 "Ten": ["부담", "책임감", "한계"], "Page": ["열정", "탐험", "호기심"], "Knight": ["모험", "에너지", "추진력"],
                 "Queen": ["자신감", "독립", "따뜻함"], "King": ["비전", "기업가", "명예"]],
            rev: ["Ace": ["지연", "방향 상실", "에너지 부족"], "Two": ["우유부단", "두려움", "계획 부재"], "Three": ["지연", "좌절", "방해"],
                  "Four": ["불안정", "전환기", "갈등"], "Five": ["회피", "타협", "내적 갈등"], "Six": ["자만", "추락", "자신감 부족"],
                  "Seven": ["포기", "압도됨", "방어 불능"], "Eight": ["지연", "혼란", "저항"], "Nine": ["의심", "편집", "방어적"],
                  "Ten": ["과부하", "번아웃", "위임 필요"], "Page": ["미숙함", "좌절", "에너지 낭비"], "Knight": ["성급함", "분노", "산만"],
                  "Queen": ["질투", "이기심", "자기 의심"], "King": ["독선", "성급한 결정", "횡포"]]),
        "cups": (
            up: ["Ace": ["새 감정", "직관", "사랑의 시작"], "Two": ["파트너십", "조화", "상호 존중"], "Three": ["우정", "축하", "공동체"],
                 "Four": ["권태", "명상", "재평가"], "Five": ["상실", "슬픔", "후회"], "Six": ["향수", "추억", "순수"],
                 "Seven": ["환상", "선택", "상상력"], "Eight": ["떠남", "변화", "실망"], "Nine": ["만족", "행복", "감사"],
                 "Ten": ["행복", "가정", "완전한 사랑"], "Page": ["감수성", "꿈", "상상력"], "Knight": ["로맨스", "매력", "이상주의"],
                 "Queen": ["공감", "돌봄", "직관력"], "King": ["감정 지혜", "외교", "관대함"]],
            rev: ["Ace": ["감정 억압", "공허", "사랑 차단"], "Two": ["불균형", "신뢰 부족", "갈등"], "Three": ["과잉", "고립", "삼자 관계"],
                  "Four": ["새 가능성", "불만", "동기 부여"], "Five": ["수용", "회복", "용서"], "Six": ["과거 집착", "비현실", "향수병"],
                  "Seven": ["현실 직면", "명확한 선택", "환상 파괴"], "Eight": ["두려움", "집착", "정체"], "Nine": ["불만족", "탐욕", "오만"],
                  "Ten": ["불화", "가정 문제", "기대 좌절"], "Page": ["감정 미숙", "백일몽", "나약함"], "Knight": ["변덕", "비현실", "감정 과잉"],
                  "Queen": ["감정 불안", "공의존", "자기 무시"], "King": ["감정 조작", "냉정", "감정 억압"]]),
        "swords": (
            up: ["Ace": ["명확함", "진실", "새 아이디어"], "Two": ["결정 보류", "균형", "직관"], "Three": ["슬픔", "고통", "이별"],
                 "Four": ["휴식", "회복", "명상"], "Five": ["갈등", "패배", "자존심"], "Six": ["전환", "여행", "회복"],
                 "Seven": ["전략", "계략", "독립적 행동"], "Eight": ["속박", "자기 제한", "무력감"], "Nine": ["걱정", "불안", "악몽"],
                 "Ten": ["종말", "배신", "위기의 끝"], "Page": ["호기심", "탐구", "새 관점"], "Knight": ["야망", "결단력", "직진"],
                 "Queen": ["명석함", "독립", "솔직함"], "King": ["권위", "지성", "판단력"]],
            rev: ["Ace": ["혼란", "잘못된 정보", "차단"], "Two": ["정보 과잉", "결정 불능", "거짓말"], "Three": ["회복", "용서", "낙관"],
                  "Four": ["불안", "번아웃", "고립"], "Five": ["화해", "패배 인정", "변화"], "Six": ["정체", "미해결", "과거 반복"],
                  "Seven": ["양심", "고백", "전략 실패"], "Eight": ["해방", "새 시각", "자유"], "Nine": ["희망", "회복", "걱정 해소"],
                  "Ten": ["재기", "최악 통과", "회복"], "Page": ["냉소", "잔꾀", "소통 부재"], "Knight": ["무모함", "공격성", "서두름"],
                  "Queen": ["잔인함", "편견", "감정 억압"], "King": ["폭군", "권력 남용", "비합리"]]),
        "pentacles": (
            up: ["Ace": ["새 기회", "번영", "잠재력"], "Two": ["균형", "유연함", "우선순위"], "Three": ["팀워크", "성장", "숙련"],
                 "Four": ["안정", "저축", "보수적"], "Five": ["빈곤", "고립", "불안"], "Six": ["관대함", "나눔", "균형"],
                 "Seven": ["인내", "투자", "장기 비전"], "Eight": ["장인정신", "성실", "기술"], "Nine": ["풍요", "자립", "성취"],
                 "Ten": ["유산", "가족", "장기 성공"], "Page": ["배움", "새 기술", "기회"], "Knight": ["책임감", "꾸준함", "인내"],
                 "Queen": ["풍요", "안정", "실용적"], "King": ["부", "사업", "안정"]],
            rev: ["Ace": ["기회 놓침", "불안정", "계획 부재"], "Two": ["과부하", "우선순위 혼란", "산만"], "Three": ["미숙", "동기 부족", "질 저하"],
                  "Four": ["탐욕", "집착", "인색"], "Five": ["회복", "도움 수용", "개선"], "Six": ["이기심", "빚", "불공정"],
                  "Seven": ["성급함", "보상 부족", "좌절"], "Eight": ["단조로움", "완벽주의", "동기 상실"], "Nine": ["과시", "재정 손실", "자만"],
                  "Ten": ["가족 갈등", "재정 문제", "불안정"], "Page": ["방향 상실", "비현실", "게으름"], "Knight": ["정체", "권태", "비효율"],
                  "Queen": ["자기 무시", "의존", "불안정"], "King": ["재정 실패", "탐욕", "고집"]]),
    ]

    // MARK: - 결정적 드로우 (웹 makeSeed/drawCards)
    static func makeSeed(year: Int, month: Int, day: Int, spread: TarotSpread) -> Int {
        let base = year * 10000 + month * 100 + day
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let todaySeed = (c.year ?? 0) * 10000 + (c.month ?? 0) * 100 + (c.day ?? 0)
        let off = spread == .one ? 1 : (spread == .three ? 2 : 3)
        return (base ^ todaySeed) + off
    }

    static func drawCards(spread: TarotSpread, seed: Int) -> [TarotDrawn] {
        let positions = spread.positions
        var s = seed
        func next() -> Double { s = (s * 9301 + 49297) % 233280; if s < 0 { s += 233280 }; return Double(s) / 233280.0 }
        var picked: [Int] = []
        var seen = Set<Int>()
        while seen.count < spread.count {
            let idx = Int(floor(next() * Double(all.count)))
            if !seen.contains(idx) { seen.insert(idx); picked.append(idx) }
        }
        return picked.enumerated().map { i, cardIdx in
            TarotDrawn(card: all[cardIdx], isReversed: next() < 0.35, position: positions[i])
        }
    }
}
