// 행운 아이템 설명 — 용신 오행 × 카테고리 기반 (오행 이론 근거 자체 작성, 엔진 텍스트 아님)
// 표시: "{카테고리} · {값} — {설명}". 설명은 오행(용신)별로 왜 이 카테고리가 기운을 보강하는지.

import Foundation

enum LuckyItemReason {
    enum Category { case color, drink, place, scent, item }

    // [오행: [color, drink, place, scent, item]]  — element 값은 엔진 needElement(Wood/Fire/Earth/Metal/Water)
    private static let table: [String: [String]] = [
        "Wood": [
            "초록빛 계열이 木의 생기를 더해줘요",
            "싱그러운 음료가 木 기운을 채워줘요",
            "나무와 풀이 있는 곳이 木을 북돋아요",
            "풀·나무 향이 木 기운을 깨워줘요",
            "자연을 닮은 물건이 木을 도와요",
        ],
        "Fire": [
            "따뜻한 붉은 계열이 火의 활기를 더해줘요",
            "온기 있는 음료가 火 기운을 채워줘요",
            "볕과 빛이 드는 곳이 火를 북돋아요",
            "따뜻한 향이 火 기운을 깨워줘요",
            "빛과 온기를 담은 물건이 火를 도와요",
        ],
        "Earth": [
            "흙빛 계열이 土의 안정을 더해줘요",
            "구수하고 따뜻한 음료가 土를 북돋아요",
            "포근하고 흙내음 있는 곳이 길해요",
            "부드럽고 달큰한 향이 土 기운을 채워줘요",
            "묵직하고 든든한 물건이 土를 도와요",
        ],
        "Metal": [
            "희고 맑은 계열이 金의 명료함을 더해줘요",
            "깔끔한 음료가 金 기운을 채워줘요",
            "정돈되고 트인 곳이 金을 북돋아요",
            "맑고 청량한 향이 金 기운을 깨워줘요",
            "단정한 금속빛 물건이 金을 도와요",
        ],
        "Water": [
            "짙고 깊은 계열이 水의 차분함을 더해줘요",
            "시원한 음료가 水 기운을 채워줘요",
            "물가·고요한 곳이 水를 북돋아요",
            "은은하고 시원한 향이 水 기운을 깨워줘요",
            "맑고 투명한 물건이 水를 도와요",
        ],
    ]

    static func text(element: String, _ c: Category) -> String {
        let arr = table[element] ?? table["Earth"]!
        switch c {
        case .color: return arr[0]
        case .drink: return arr[1]
        case .place: return arr[2]
        case .scent: return arr[3]
        case .item:  return arr[4]
        }
    }
}
