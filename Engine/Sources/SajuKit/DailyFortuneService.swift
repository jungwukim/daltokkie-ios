// 일일운세 서비스 — daily-fortune API 라우트 로직 포팅
// (여러 날 운세 + 오늘 선택 + 행운 시간 + 용신 기반 개운 아이템)

import Foundation
import LunarKit

public struct LuckyHours: Codable, Equatable, Sendable {
    public let lucky: String
    public let unlucky: String
}

public struct LuckyItems: Codable, Equatable, Sendable {
    public let color: String
    public let drink: String
    public let place: String
    public let scent: String
    public let item: String
    public let element: String      // Wood~Water (용신 오행)
    public let elementKo: String    // 목(木) 등
    public let reason: String       // 용신 설명
}

public struct YongsinSummary: Codable, Equatable, Sendable {
    public let element: String
    public let elementKo: String
    public let description: String
    public let strengthLabel: String
}

public struct DailyFortuneBundle: Sendable {
    public let saju: FortuneTellerResult
    public let today: DailyFortuneResult
    public let fortunes: [DailyFortuneResult]
    public let luckyHours: LuckyHours
    public let yongsin: YongsinSummary
    public let luckyItems: LuckyItems
}

public enum DailyFortuneService {
    static let elementKo: [String: String] = [
        "Wood": "목(木)", "Fire": "화(火)", "Earth": "토(土)", "Metal": "금(金)", "Water": "수(水)",
    ]

    /// route.ts POST 핸들러 등가 — targetDate(y/m/d)부터 days일간
    public static func build(
        saju: FortuneTellerResult,
        birthYear: Int,
        targetYear: Int, targetMonth: Int, targetDay: Int,
        days: Int = 5,
        todayYear: Int, todayMonth: Int, todayDay: Int
    ) -> DailyFortuneBundle {
        let dm = saju.dayMaster
        let pillars = SajuPillars(year: saju.pillars.year, month: saju.pillars.month, day: saju.pillars.day, hour: saju.pillars.hour)

        var fortunes: [DailyFortuneResult] = []
        let baseJDN = JulianDay.jdn(targetYear, targetMonth, targetDay)
        for i in 0..<days {
            let (y, m, d) = JulianDay.toDate(baseJDN + i)
            fortunes.append(DailyFortuneEngine.calculateDailyFortune(
                targetYear: y, targetMonth: m, targetDay: d,
                dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang, dayMasterHanja: dm.hanja,
                birthYear: birthYear, natalPillars: pillars
            ))
        }

        let todayStr = String(format: "%04d-%02d-%02d", todayYear, todayMonth, todayDay)
        let today = fortunes.first { $0.date == todayStr } ?? fortunes[fortunes.count / 2]

        let luckyHours = deriveLuckyHours(overallScore: today.overallScore, birthYear: birthYear, dateStr: today.date)

        let strength = EngineAnalysis.buildStrengthFromLibrary(raw: saju.raw, pillars: pillars)
        let yongsinAnalysis = EngineAnalysis.buildYongsinFromLibrary(
            raw: saju.raw, dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang,
            isStrong: strength.isStrong, strengthLevel: saju.raw.dayMasterStrength?.level
        )
        let needElement = yongsinAnalysis.yongsin.element

        let lucky = deriveLuckyItems(needElement: needElement, score: today.overallScore, dateStr: today.date)

        return DailyFortuneBundle(
            saju: saju,
            today: today,
            fortunes: fortunes,
            luckyHours: luckyHours,
            yongsin: YongsinSummary(
                element: needElement,
                elementKo: yongsinAnalysis.yongsin.elementKo,
                description: yongsinAnalysis.yongsin.description,
                strengthLabel: strength.label
            ),
            luckyItems: LuckyItems(
                color: lucky.color, drink: lucky.drink, place: lucky.place,
                scent: lucky.scent, item: lucky.item,
                element: needElement,
                elementKo: elementKo[needElement] ?? needElement,
                reason: yongsinAnalysis.yongsin.description
            )
        )
    }

    static func deriveLuckyHours(overallScore: Int, birthYear: Int, dateStr: String) -> LuckyHours {
        let dateNum = Int(dateStr.replacingOccurrences(of: "-", with: "")) ?? 0
        let rand = DailyFortuneEngine.SeededRandom(seed: birthYear * 100 + dateNum)
        _ = rand.next()

        let hours = [
            "01:00~03:00", "03:00~05:00", "05:00~07:00", "07:00~09:00",
            "09:00~11:00", "11:00~13:00", "13:00~15:00", "15:00~17:00",
            "17:00~19:00", "19:00~21:00", "21:00~23:00",
        ]
        let luckyIdx = Int(floor(rand.next() * Double(hours.count)))
        var unluckyIdx = Int(floor(rand.next() * Double(hours.count)))
        if unluckyIdx == luckyIdx { unluckyIdx = (unluckyIdx + 3) % hours.count }
        return LuckyHours(lucky: hours[luckyIdx], unlucky: hours[unluckyIdx])
    }

    struct ElementItemSet {
        let colors: [String], drinks: [String], places: [String], scents: [String], items: [String]
    }

    /// 오행별 개운 아이템 — 오방정색/오미귀경/오방/귀경향/오행 재질 (route.ts 그대로)
    static let elementItems: [String: ElementItemSet] = [
        "Wood": ElementItemSet(
            colors: ["초록", "연두", "청록", "에메랄드", "올리브"],
            drinks: ["레몬에이드", "그린티 라떼", "녹차", "자몽주스", "매실차"],
            places: ["공원 산책로", "나무 많은 길", "꽃집", "숲속 산책", "나무 그늘 아래"],
            scents: ["편백나무향", "그린티향", "페퍼민트", "풀잎향", "허브향"],
            items: ["연필", "에코백", "메모지", "책", "녹색 계열 옷"]
        ),
        "Fire": ElementItemSet(
            colors: ["빨강", "주황", "자주", "핑크", "와인레드"],
            drinks: ["핫 카카오", "생강차", "대추차", "루이보스티", "얼그레이"],
            places: ["햇볕 쬐기", "창가 자리", "미술관", "테라스 좌석", "공연장"],
            scents: ["시나몬", "우디향", "앰버향", "로즈마리", "정향향"],
            items: ["캔들", "무드등", "핑크 립밤", "선글라스", "빨간 머리끈"]
        ),
        "Earth": ElementItemSet(
            colors: ["황토색", "베이지", "갈색", "크림", "테라코타"],
            drinks: ["꿀아메리카노", "고구마 라떼", "곡물라떼", "바닐라라떼", "보리차"],
            places: ["베이커리 카페", "공원 잔디밭", "전통 시장", "따뜻한 카페", "정원 카페"],
            scents: ["바닐라향", "흙향", "샌달우드", "카라멜향", "꿀향"],
            items: ["갈색 종이백", "베이지 톤 옷", "갈색 노트", "따뜻한 차 한잔", "갈색 머리끈"]
        ),
        "Metal": ElementItemSet(
            colors: ["흰색", "은색", "골드", "아이보리", "라이트그레이"],
            drinks: ["진저에일", "유자에이드", "밀크티", "유자차", "배 주스"],
            places: ["깔끔한 카페", "전망 좋은 곳", "감성 서점", "갤러리", "전망대"],
            scents: ["유칼립투스", "화이트머스크", "클린코튼향", "비누향", "티트리"],
            items: ["은색 악세서리", "흰 옷 입기", "흰색 양말", "스테인리스 텀블러", "은색 동전"]
        ),
        "Water": ElementItemSet(
            colors: ["검정", "남색", "다크블루", "차콜", "인디고"],
            drinks: ["콜드브루", "코코넛 워터", "아이스티", "포도 주스", "아메리카노"],
            places: ["물가 산책", "수영장", "분수대 근처", "어두운 조명 카페", "밤 산책"],
            scents: ["오션향", "라벤더", "머스크", "아쿠아향", "자스민"],
            items: ["다크 초콜릿", "투명 텀블러", "검정 톤 옷", "검정 볼펜", "네이비 양말"]
        ),
    ]

    static func deriveLuckyItems(needElement: String, score: Int, dateStr: String) -> (color: String, drink: String, place: String, scent: String, item: String) {
        let items = elementItems[needElement] ?? elementItems["Water"]!
        let dateNum = Int(dateStr.replacingOccurrences(of: "-", with: "")) ?? 0
        let rand = DailyFortuneEngine.SeededRandom(seed: dateNum + score)
        _ = rand.next()

        func pick(_ arr: [String]) -> String {
            arr[Int(floor(rand.next() * Double(arr.count)))]
        }
        return (pick(items.colors), pick(items.drinks), pick(items.places), pick(items.scents), pick(items.items))
    }
}
