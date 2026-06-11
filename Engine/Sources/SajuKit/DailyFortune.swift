// 일일운세 + 내러티브 요약 — saju-engine.ts 일일운세 영역 포팅
// 같은 사람 + 같은 날짜 = 같은 결과 (seeded PRNG, JS Number 의미론 비트 단위 재현)

import Foundation
import LunarKit

// MARK: - 타입

public struct DailyFortuneCard: Codable, Equatable, Sendable {
    public let category: String
    public let icon: String
    public let score: Int
    public let grade: String          // 상/중상/중/중하/하
    public let description: String
}

public struct RelationItem: Codable, Equatable, Sendable {
    public let type: String
    public let description: String
}

public struct TransitRelation: Codable, Equatable, Sendable {
    public let transitStem: String
    public let transitBranch: String
    public let natalPillar: String
    public let stemRelations: [RelationItem]
    public let branchRelations: [RelationItem]
}

public struct DailyFortuneResult: Codable, Equatable, Sendable {
    public let date: String
    public let dayStemHanja: String
    public let dayStemKorean: String
    public let dayBranchHanja: String
    public let dayBranchKorean: String
    public let dayBranchAnimal: String
    public let overallScore: Int
    public let overallGrade: String
    public let tenGodOfDay: String
    public let twelveStageOfDay: String
    public let cards: [DailyFortuneCard]
    public let transitRelations: [TransitRelation]
    public let fortuneSummary: String
}

public struct MonthlyCalendarDay: Codable, Equatable, Sendable {
    public let date: String
    public let day: Int
    public let stemKorean: String
    public let branchKorean: String
    public let overallScore: Int
    public let grade: String
    public let tenGod: String
}

// MARK: - 엔진

public enum DailyFortuneEngine {

    // JS `(s * 1103515245 + 12345) & 0x7fffffff` 재현.
    // 곱이 2^53을 넘어 JS는 double 반올림 후 ToInt32 — Swift도 동일하게 Double 곱셈 사용.
    final class SeededRandom {
        private var s: Int
        init(seed: Int) { self.s = seed }
        func next() -> Double {
            let prod = Double(s) * 1103515245.0 + 12345.0
            let i64 = Int64(prod)
            let i32 = Int32(truncatingIfNeeded: i64)
            s = Int(i32) & 0x7fffffff
            return Double(s) / Double(0x7fffffff)
        }
    }

    static let twelveStageBonus: [String: Int] = [
        "장생": 12, "목욕": 0, "관대": 10, "건록": 15, "제왕": 18,
        "쇠": -5, "병": -10, "사": -15, "묘": -12, "절": -8, "태": 3, "양": 5,
    ]

    /// 십성 × 카테고리 보정 — 키 순서 무관 (조회 전용)
    static let tenGodAffinity: [String: [String: Int]] = [
        "비견": ["재물": -5, "건강": 10, "연애": 0, "직장": 5, "학업": 5, "대인": 10, "여행": 5, "창작": 0, "가정": 5, "투자": -5],
        "겁재": ["재물": -8, "건강": 8, "연애": 5, "직장": 0, "학업": 0, "대인": 5, "여행": 10, "창작": 5, "가정": 0, "투자": -10],
        "식신": ["재물": 8, "건강": 10, "연애": 5, "직장": 5, "학업": 8, "대인": 10, "여행": 8, "창작": 15, "가정": 10, "투자": 5],
        "상관": ["재물": 5, "건강": -5, "연애": 10, "직장": -5, "학업": 10, "대인": -5, "여행": 5, "창작": 15, "가정": -5, "투자": 0],
        "편재": ["재물": 15, "건강": 0, "연애": 8, "직장": 5, "학업": 0, "대인": 10, "여행": 10, "창작": 0, "가정": 5, "투자": 12],
        "정재": ["재물": 12, "건강": 5, "연애": 5, "직장": 10, "학업": 5, "대인": 5, "여행": 5, "창작": 0, "가정": 10, "투자": 8],
        "편관": ["재물": 0, "건강": -5, "연애": -5, "직장": 10, "학업": 5, "대인": -5, "여행": 0, "창작": 0, "가정": 0, "투자": -5],
        "정관": ["재물": 5, "건강": 5, "연애": 5, "직장": 15, "학업": 10, "대인": 5, "여행": 0, "창작": 0, "가정": 10, "투자": 5],
        "편인": ["재물": 0, "건강": 5, "연애": -5, "직장": 5, "학업": 15, "대인": 0, "여행": 5, "창작": 10, "가정": 0, "투자": 0],
        "정인": ["재물": 5, "건강": 10, "연애": 0, "직장": 8, "학업": 15, "대인": 5, "여행": 0, "창작": 5, "가정": 8, "투자": 0],
    ]

    /// 카테고리 — 배열 순서 = 카드 순서
    static let fortuneCategories: [(key: String, label: String, icon: String)] = [
        ("재물", "재물운", "💰"), ("건강", "건강운", "💪"), ("연애", "연애운", "💕"),
        ("직장", "직장운", "💼"), ("학업", "학업운", "📚"), ("대인", "대인운", "🤝"),
        ("여행", "여행운", "✈️"), ("창작", "창작운", "🎨"), ("가정", "가정운", "🏠"),
        ("투자", "투자운", "📈"),
    ]

    static let fortuneDescriptions: [String: [String: String]] = [
        "재물": ["상": "금전적 기회가 열리는 날입니다. 뜻밖의 수입이 있을 수 있습니다.", "중상": "재물운이 좋은 편입니다. 소소한 이익이 기대됩니다.", "중": "평범한 재물운입니다. 과소비를 주의하세요.", "중하": "지출이 다소 많을 수 있습니다. 절약을 권합니다.", "하": "금전적으로 조심해야 할 날입니다. 큰 투자는 피하세요."],
        "건강": ["상": "활력이 넘치는 날입니다. 운동이나 야외활동에 좋습니다.", "중상": "전반적으로 건강한 하루입니다.", "중": "무리하지 않으면 좋은 하루를 보낼 수 있습니다.", "중하": "피로가 쌓일 수 있습니다. 충분한 휴식을 취하세요.", "하": "건강관리에 각별히 신경 써야 하는 날입니다."],
        "연애": ["상": "로맨틱한 인연이 찾아올 수 있는 날입니다.", "중상": "상대와의 관계가 깊어지는 시간입니다.", "중": "평온한 관계를 유지하는 날입니다.", "중하": "사소한 오해가 생길 수 있습니다. 대화로 풀어보세요.", "하": "감정적 충돌에 주의하세요. 한 발 물러서는 지혜가 필요합니다."],
        "직장": ["상": "업무에서 뛰어난 성과를 낼 수 있는 날입니다.", "중상": "일이 순조롭게 진행됩니다.", "중": "꾸준히 하면 성과가 있을 것입니다.", "중하": "업무 스트레스가 있을 수 있습니다. 우선순위를 정하세요.", "하": "동료와의 마찰에 주의하세요. 신중하게 행동하세요."],
        "학업": ["상": "집중력이 높아지는 날입니다. 새로운 것을 배우기 좋습니다.", "중상": "학습 효율이 좋은 하루입니다.", "중": "보통의 학습 컨디션입니다.", "중하": "집중력이 흐트러질 수 있습니다. 환경을 바꿔보세요.", "하": "머리가 복잡한 날입니다. 가벼운 복습 정도가 적당합니다."],
        "대인": ["상": "새로운 인연을 맺기 좋은 날입니다. 적극적으로 소통하세요.", "중상": "주변 사람들과 원만한 관계를 유지할 수 있습니다.", "중": "무난한 대인관계의 하루입니다.", "중하": "말조심이 필요합니다. 오해를 살 수 있는 표현은 피하세요.", "하": "갈등이 생길 수 있는 날입니다. 가급적 충돌을 피하세요."],
        "여행": ["상": "여행이나 이동에 좋은 기운이 함께합니다.", "중상": "가벼운 외출이나 여행이 기분을 전환해 줄 것입니다.", "중": "일상적인 이동은 무난합니다.", "중하": "이동 중 소소한 불편이 있을 수 있습니다.", "하": "가급적 먼 이동은 자제하는 것이 좋겠습니다."],
        "창작": ["상": "영감이 풍부한 날입니다. 창작 활동에 몰두해 보세요.", "중상": "아이디어가 잘 떠오르는 하루입니다.", "중": "꾸준한 작업이 결실을 맺는 날입니다.", "중하": "창작 의욕이 다소 떨어질 수 있습니다.", "하": "억지로 창작하기보다 감상에 집중해 보세요."],
        "가정": ["상": "가족과 함께 즐거운 시간을 보낼 수 있는 날입니다.", "중상": "가정에 온화한 기운이 감돕니다.", "중": "평화로운 가정생활이 이어집니다.", "중하": "가족 간 소소한 마찰이 있을 수 있습니다.", "하": "가족에게 인내심을 가지고 대해야 하는 날입니다."],
        "투자": ["상": "투자 판단력이 좋은 날입니다. 좋은 기회를 놓치지 마세요.", "중상": "신중하게 접근하면 좋은 결과가 있을 수 있습니다.", "중": "현 상태를 유지하는 것이 무난합니다.", "중하": "투자에 보수적으로 접근하세요.", "하": "오늘은 투자를 자제하는 것이 현명합니다."],
    ]

    static let narrativePhrases: [String: (good: [String], mid: [String], low: [String])] = [
        "재물": (
            good: ["지갑이 두둑해지는 기운이 느껴지고", "금전적으로 좋은 소식이 있을 수 있고"],
            mid: ["돈 관련해서는 크게 걱정할 건 없고", "재정적으로 평온한 흐름이고"],
            low: ["큰 지출이나 투자 결정은 며칠 뒤로 미루는 게 나을 것 같고", "지갑은 오늘 좀 꽁꽁 묶어두는 게 좋겠고"]
        ),
        "건강": (
            good: ["몸에 활력이 넘쳐요", "컨디션이 좋아서 뭘 해도 거뜬할 거예요"],
            mid: ["몸 상태는 무난하니 평소대로 지내면 돼요", "건강은 크게 신경 쓸 건 없어요"],
            low: ["몸이 좀 무거울 수 있으니 일찍 쉬어주세요", "무리하지 말고 몸은 좀 아껴주세요"]
        ),
        "연애": (
            good: ["설레는 만남이 찾아올 수 있어요", "사랑하는 사람과 더 가까워지는 시간이에요"],
            mid: ["사랑하는 사람과는 편안한 시간을 보낼 수 있어요", "연애 쪽은 잔잔하게 흘러가요"],
            low: ["감정적인 대화는 오늘보다 내일이 좋겠어요", "연애에서는 한 템포 쉬어가 보세요"]
        ),
        "직장": (
            good: ["일에서 능력을 발휘할 수 있는 타이밍이에요", "맡은 일이 술술 풀릴 거예요"],
            mid: ["업무는 차분하게 하나씩 처리하면 괜찮아요", "일은 조용히 굴러가는 흐름이에요"],
            low: ["직장에서는 꼭 해야 할 것만 하고 힘은 아끼세요", "업무 중 사소한 마찰이 있을 수 있으니 유연하게 넘기세요"]
        ),
        "학업": (
            good: ["머리가 잘 돌아가니 새로운 걸 배우기 딱 좋아요", "공부에 집중하면 확실한 성과가 있을 거예요"],
            mid: ["공부는 욕심 부리지 말고 꾸준히 하면 충분해요", "배움의 흐름은 보통이지만 꾸준함이 힘이 돼요"],
            low: ["공부가 잘 안 되면 잠깐 환기하고 돌아오세요", "머리가 좀 복잡할 수 있으니 가벼운 복습 정도가 좋겠어요"]
        ),
        "대인": (
            good: ["사람들과의 만남에서 좋은 에너지를 받을 수 있어요", "누군가와의 대화에서 뜻밖의 힌트를 얻게 될지도 몰라요"],
            mid: ["주변 사람들과는 편하게 지내면 돼요", "사람 사이 일은 무난하게 흘러가요"],
            low: ["말은 아끼고 듣는 데 집중하면 좋겠어요", "사람 관계에서는 오늘 좀 조용히 지내는 게 나아요"]
        ),
        "여행": (
            good: ["나들이나 여행을 떠나면 기분 좋은 일이 생길 거예요", "어딘가로 발걸음을 옮기면 좋은 일이 따라와요"],
            mid: ["가벼운 외출은 기분 전환에 좋겠어요", "이동이나 외출은 무난해요"],
            low: ["먼 곳보다는 가까운 곳에서 보내는 게 좋겠어요", "이동은 가급적 줄이고 편히 지내세요"]
        ),
        "창작": (
            good: ["번뜩이는 아이디어가 떠오를 수 있으니 메모해 두세요", "창의적인 영감이 풍부한 하루예요"],
            mid: ["창작은 자연스럽게 흘러가게 두면 돼요", "아이디어는 천천히 정리하면 좋겠어요"],
            low: ["만들기보다 좋은 작품을 감상하며 충전하세요", "창작은 쉬어가며 여유를 두세요"]
        ),
        "가정": (
            good: ["가족과 함께하는 시간이 따뜻할 거예요", "집에서 보내는 시간에 작은 행복이 있어요"],
            mid: ["가정은 평화롭게 흘러가니 걱정 없어요", "집안일은 무리 없이 잘 돌아갈 거예요"],
            low: ["가족에게는 평소보다 부드럽게 말해 주세요", "집안에서는 한 발 물러서는 여유를 가져보세요"]
        ),
        "투자": (
            good: ["투자 감각이 살아 있으니 관심 있던 걸 다시 살펴보세요", "재테크에 좋은 흐름이 보여요"],
            mid: ["투자는 지금 가진 걸 지키는 데 집중하면 돼요", "투자 쪽은 관망하는 게 무난해요"],
            low: ["투자 결정은 며칠 뒤에 다시 생각해 보세요", "투자에서는 오늘 한 발 물러서는 게 현명해요"]
        ),
    ]

    static func scoreToGrade(_ score: Int) -> String {
        if score >= 85 { return "상" }
        if score >= 70 { return "중상" }
        if score >= 50 { return "중" }
        if score >= 35 { return "중하" }
        return "하"
    }

    static func toTier(_ grade: String) -> String {
        if grade == "상" || grade == "중상" { return "good" }
        if grade == "중" { return "mid" }
        return "low"
    }

    // MARK: - 운세 합충 (findTransitRelations)

    static func findTransitRelations(
        transitStemHanja: String, transitBranchHanja: String, pillars: SajuPillars
    ) -> [TransitRelation] {
        var entries: [(name: String, stem: String, branch: String)] = [
            ("년주", pillars.year.stem.hanja, pillars.year.branch.hanja),
            ("월주", pillars.month.stem.hanja, pillars.month.branch.hanja),
            ("일주", pillars.day.stem.hanja, pillars.day.branch.hanja),
        ]
        if let hour = pillars.hour {
            entries.append(("시주", hour.stem.hanja, hour.branch.hanja))
        }

        func sk(_ h: String) -> String { EngineAnalysis.STEM_KR[h] ?? h }
        func bk(_ h: String) -> String { EngineAnalysis.BRANCH_KOREAN[h] ?? h }

        var results: [TransitRelation] = []
        for pe in entries {
            var stemRels: [RelationItem] = []
            var branchRels: [RelationItem] = []

            for entry in EngineAnalysis.CHEONGAN_HAP_TABLE {
                let pair = entry.pair
                if (transitStemHanja == pair[0] && pe.stem == pair[1]) || (transitStemHanja == pair[1] && pe.stem == pair[0]) {
                    stemRels.append(RelationItem(type: "천간합", description: entry.name))
                }
            }
            for (a, b) in EngineAnalysis.CHEONGAN_CHUNG_TABLE {
                if (transitStemHanja == a && pe.stem == b) || (transitStemHanja == b && pe.stem == a) {
                    stemRels.append(RelationItem(type: "천간충", description: "\(sk(transitStemHanja))-\(sk(pe.stem)) 충"))
                }
            }
            for (a, b, desc) in EngineAnalysis.SIX_HARMONIES {
                if (transitBranchHanja == a && pe.branch == b) || (transitBranchHanja == b && pe.branch == a) {
                    branchRels.append(RelationItem(type: "육합", description: desc))
                }
            }
            for (a, b) in EngineAnalysis.SIX_CLASHES {
                if (transitBranchHanja == a && pe.branch == b) || (transitBranchHanja == b && pe.branch == a) {
                    branchRels.append(RelationItem(type: "육충", description: "\(bk(transitBranchHanja))-\(bk(pe.branch)) 충"))
                }
            }
            for (a, b, desc) in EngineAnalysis.THREE_PUNISHMENTS {
                if (transitBranchHanja == a && pe.branch == b) || (transitBranchHanja == b && pe.branch == a) {
                    branchRels.append(RelationItem(type: "형", description: desc))
                }
            }
            for (a, b, _) in EngineAnalysis.HARMS {
                if (transitBranchHanja == a && pe.branch == b) || (transitBranchHanja == b && pe.branch == a) {
                    branchRels.append(RelationItem(type: "해", description: "\(bk(transitBranchHanja))-\(bk(pe.branch)) 해"))
                }
            }
            for (a, b) in EngineAnalysis.DESTRUCTIONS {
                if (transitBranchHanja == a && pe.branch == b) || (transitBranchHanja == b && pe.branch == a) {
                    branchRels.append(RelationItem(type: "파", description: "\(bk(transitBranchHanja))-\(bk(pe.branch)) 파"))
                }
            }

            if !stemRels.isEmpty || !branchRels.isEmpty {
                results.append(TransitRelation(
                    transitStem: transitStemHanja, transitBranch: transitBranchHanja,
                    natalPillar: pe.name, stemRelations: stemRels, branchRelations: branchRels
                ))
            }
        }
        return results
    }

    // MARK: - 일일운세 (calculateDailyFortune)

    public static func calculateDailyFortune(
        targetYear: Int, targetMonth: Int, targetDay: Int,
        dayMasterElement: String, dayMasterYinYang: String, dayMasterHanja: String,
        birthYear: Int,
        natalPillars: SajuPillars? = nil
    ) -> DailyFortuneResult {
        // diffDays = UTC일수(target) - UTC일수(1900-01-01) — JDN 차와 동일
        let diffDays = JulianDay.jdn(targetYear, targetMonth, targetDay) - JulianDay.jdn(1900, 1, 1)
        let offset = 10
        let stemIdx = ((diffDays + offset) % 10 + 10) % 10
        let branchIdx = ((diffDays + offset) % 12 + 12) % 12
        let dayStem = SajuTables.stems[stemIdx]
        let dayBranch = SajuTables.branches[branchIdx]
        let dayStemHanja = dayStem.hanja
        let dayBranchHanja = dayBranch.hanja
        let stemElementEn = SajuTables.elementKrToEn[dayStem.element]!
        let stemYinYangEn = SajuTables.yinYangKrToEn[dayStem.yinYang]!

        let tenGod = EngineAnalysis.getTenGod(
            dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang,
            targetElement: stemElementEn, targetYinYang: stemYinYangEn
        )
        let twelveStage = EngineAnalysis.getTwelveStage(dayMasterHanja: dayMasterHanja, branchHanja: dayBranchHanja)
        let stageBonus = twelveStageBonus[twelveStage] ?? 0
        let affinity = tenGodAffinity[tenGod] ?? [:]

        let dateSeed = targetYear * 10000 + targetMonth * 100 + targetDay
        let stemIndexOfDm = SajuTables.stems.firstIndex { $0.hanja == dayMasterHanja } ?? -1
        let personSeed = birthYear * 100 + stemIndexOfDm
        let rand = SeededRandom(seed: dateSeed + personSeed)

        var cards: [DailyFortuneCard] = []
        for cat in fortuneCategories {
            let base = 50 + stageBonus + (affinity[cat.key] ?? 0)
            let variance = Int(floor(rand.next() * 20)) - 10
            let score = max(10, min(100, base + variance))
            let grade = scoreToGrade(score)
            let description = fortuneDescriptions[cat.key]?[grade] ?? ""
            cards.append(DailyFortuneCard(category: cat.label, icon: cat.icon, score: score, grade: grade, description: description))
        }

        let overallScore = Int(floor(Double(cards.reduce(0) { $0 + $1.score }) / Double(cards.count) + 0.5))
        let gradeLabels = ["하", "중하", "중", "중상", "상"]
        let overallGrade = gradeLabels[min(4, overallScore / 20)]

        let dateStr = String(format: "%04d-%02d-%02d", targetYear, targetMonth, targetDay)

        let transitRelations = natalPillars.map {
            findTransitRelations(transitStemHanja: dayStemHanja, transitBranchHanja: dayBranchHanja, pillars: $0)
        } ?? []

        let fortuneSummary = buildFortuneSummary(cards: cards, overallScore: overallScore, rand: rand)

        return DailyFortuneResult(
            date: dateStr,
            dayStemHanja: dayStemHanja, dayStemKorean: dayStem.korean,
            dayBranchHanja: dayBranchHanja, dayBranchKorean: dayBranch.korean,
            dayBranchAnimal: dayBranch.animalKo,
            overallScore: overallScore, overallGrade: overallGrade,
            tenGodOfDay: tenGod, twelveStageOfDay: twelveStage,
            cards: cards, transitRelations: transitRelations,
            fortuneSummary: fortuneSummary
        )
    }

    // MARK: - 내러티브 요약 (buildFortuneSummary)

    static func buildFortuneSummary(cards: [DailyFortuneCard], overallScore: Int, rand: SeededRandom) -> String {
        func pick(_ arr: [String]) -> String {
            arr[Int(floor(rand.next() * Double(arr.count)))]
        }
        func catKey(_ c: DailyFortuneCard) -> String {
            c.category.replacingOccurrences(of: "운", with: "")
        }

        var good: [(key: String, phrase: String)] = []
        var mid: [(key: String, phrase: String)] = []
        var low: [(key: String, phrase: String)] = []

        for card in cards {
            let key = catKey(card)
            let tier = toTier(card.grade)
            guard let pools = narrativePhrases[key] else { continue }
            let pool = tier == "good" ? pools.good : (tier == "mid" ? pools.mid : pools.low)
            let phrase = pick(pool)
            if tier == "good" { good.append((key, phrase)) }
            else if tier == "mid" { mid.append((key, phrase)) }
            else { low.append((key, phrase)) }
        }

        if low.count == cards.count {
            return pick([
                "오늘은 하루 전체가 좀 고단할 수 있어요. 무리하기보다 좋아하는 음악을 틀어놓고 편히 쉬어보세요. 몸도 마음도 충전하면 내일은 한결 가볍게 시작할 수 있을 거예요!",
                "오늘은 억지로 밀어붙이기보다 잠시 멈춰도 괜찮은 날이에요. 따뜻한 차 한 잔과 함께 여유를 갖고, 좋은 날을 위해 에너지를 모아두세요!",
            ])
        }
        if good.count == cards.count {
            return pick([
                "오늘은 어디로 가든, 무엇을 하든 좋은 기운이 함께해요! 일도 사람도 돈도 모두 순조로우니, 하고 싶었던 일이 있다면 망설이지 말고 지금 시작해 보세요!",
                "오늘은 정말 멋진 하루가 될 거예요! 모든 영역에서 기운이 살아 있으니, 적극적으로 움직일수록 더 좋은 결과가 따라올 거예요!",
            ])
        }
        if mid.count == cards.count {
            return pick([
                "오늘은 특별히 튀는 건 없지만 그만큼 안정적인 하루예요. 꾸준히 할 일을 하나씩 해나가면 작지만 확실한 성과가 쌓일 거예요. 평소 루틴을 잘 지키는 것만으로 충분해요.",
                "오늘은 조용하지만 편안한 흐름의 하루예요. 큰 모험보다는 꾸준함이 빛나는 날이니, 마음 편히 평소대로 지내세요.",
            ])
        }

        var sentences: [String] = []

        if !good.isEmpty {
            var featured = good.prefix(3).map(\.phrase)
            if featured.count == 1 {
                sentences.append("오늘은 \(featured[0]).")
            } else {
                let last = featured.removeLast()
                sentences.append("오늘은 \(featured.joined(separator: ", ")), \(last).")
            }
            if good.count > 3 {
                sentences.append(pick([
                    "전반적으로 기운이 좋은 날이에요.",
                    "여러모로 순조로운 흐름이에요.",
                ]))
            }
        }

        if !mid.isEmpty {
            if good.isEmpty && low.isEmpty {
                sentences.append(pick([
                    "오늘은 특별히 튀는 건 없지만 그만큼 편안한 하루예요.",
                    "오늘은 조용하지만 안정적인 흐름의 하루예요.",
                ]))
            } else if !good.isEmpty && low.isEmpty {
                sentences.append(pick([
                    "나머지도 크게 걱정할 건 없이 평온하게 흘러가요.",
                    "그 외에는 무난하게 지나갈 거예요.",
                ]))
            } else if good.isEmpty {
                let sample = mid.prefix(2).map(\.phrase)
                sentences.append("오늘은 \(sample.joined(separator: ", ")).")
                if mid.count > 2 {
                    sentences.append(pick([
                        "전반적으로 조용한 흐름이에요.",
                        "큰 파도 없이 잔잔하게 흘러가는 날이에요.",
                    ]))
                }
            } else {
                sentences.append(pick([
                    "나머지는 평소대로 지내면 충분해요.",
                    "그 밖에는 조용히 잘 흘러가요.",
                ]))
            }
        }

        if !low.isEmpty {
            let featured = low.prefix(2).map(\.phrase)
            if featured.count == 1 {
                sentences.append("다만 \(featured[0]).")
            } else {
                sentences.append("다만 \(featured[0]), \(featured[1]).")
            }
            if low.count > 2 {
                sentences.append(pick([
                    "전체적으로 무리하지 않는 게 좋은 하루예요.",
                    "욕심내지 말고 편하게 보내세요.",
                ]))
            }
        }

        if overallScore >= 65 {
            sentences.append(pick([
                "자신감을 갖고 적극적으로 움직여 보세요!",
                "흐름이 좋은 하루, 망설이지 말고 행동으로 옮겨보세요!",
            ]))
        } else if overallScore >= 40 {
            sentences.append(pick([
                "차분하게 보내면 작은 좋은 일들이 찾아올 거예요.",
                "편안한 마음으로 하루를 보내세요.",
            ]))
        } else {
            sentences.append(pick([
                "오늘은 충전하는 날이라고 생각하세요. 내일은 분명 더 나아요!",
                "쉬어가는 것도 전략이에요. 좋은 날은 곧 찾아올 거예요.",
            ]))
        }

        return sentences.joined(separator: " ")
    }

    // MARK: - 월간 달력 (calculateMonthlyCalendar)

    public static func calculateMonthlyCalendar(
        year: Int, month: Int,
        dayMasterElement: String, dayMasterYinYang: String, dayMasterHanja: String,
        birthYear: Int
    ) -> [MonthlyCalendarDay] {
        let daysInMonth = JulianDay.jdn(month == 12 ? year + 1 : year, month == 12 ? 1 : month + 1, 1) - JulianDay.jdn(year, month, 1)
        var result: [MonthlyCalendarDay] = []
        for d in 1...daysInMonth {
            let fortune = calculateDailyFortune(
                targetYear: year, targetMonth: month, targetDay: d,
                dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang,
                dayMasterHanja: dayMasterHanja, birthYear: birthYear
            )
            result.append(MonthlyCalendarDay(
                date: fortune.date, day: d,
                stemKorean: fortune.dayStemKorean, branchKorean: fortune.dayBranchKorean,
                overallScore: fortune.overallScore, grade: fortune.overallGrade,
                tenGod: fortune.tenGodOfDay
            ))
        }
        return result
    }
}
