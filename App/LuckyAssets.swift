// 엔진 행운 아이템/컨디션 값 → Dal Tokkie 일러스트 에셋 매핑
// 에셋: color-<색>, place-<장소>, item-<번호>, dir-<방향> (prepare-assets.sh)

import SwiftUI

enum LuckyAssets {

    // MARK: - 색깔 (엔진 색상값 → color-<ASCII 색상명>)
    // 에셋: color-green/lightgreen/teal/emerald/khaki/red/orange/purple/magenta/coral/yellow/
    //       beige/brown/ivory/camel/white/silver/gold/gray/cream/blue/deepblue/black/navy/indigo
    private static let colorMap: [String: String] = [
        // 木
        "초록": "green", "연두": "lightgreen", "청록": "teal", "에메랄드": "emerald", "올리브": "khaki",
        // 火
        "빨강": "red", "주황": "orange", "자주": "magenta", "핑크": "coral", "와인레드": "magenta",
        // 土
        "황토색": "brown", "베이지": "beige", "갈색": "brown", "크림": "cream", "테라코타": "camel",
        // 金
        "흰색": "white", "은색": "silver", "골드": "gold", "아이보리": "ivory", "라이트그레이": "gray",
        // 水
        "검정": "black", "남색": "deepblue", "다크블루": "navy", "차콜": "gray", "인디고": "indigo",
    ]

    static func colorAsset(_ value: String) -> String? {
        if let mapped = colorMap[value] { return "color-\(mapped)" }
        return nil
    }

    // MARK: - 장소 (엔진 장소값 → place-<ASCII 장소명>)
    // 에셋: place-moongarden/forestpath/teahouse/archive/greenhouse/restaurant/cinema/theater/
    //       observatory/mountain/temple/library/artmuseum/hanok/department/gallery/bank/hotel/
    //       lounge/rooftop/sea/aquarium/spa/fountain
    private static let placeMap: [String: String] = [
        // 木
        "공원 산책로": "moongarden", "나무 많은 길": "forestpath", "꽃집": "greenhouse",
        "숲속 산책": "forestpath", "나무 그늘 아래": "moongarden",
        // 火
        "햇볕 쬐기": "rooftop", "창가 자리": "teahouse", "미술관": "artmuseum",
        "테라스 좌석": "lounge", "공연장": "theater",
        // 土
        "베이커리 카페": "restaurant", "공원 잔디밭": "moongarden", "전통 시장": "hanok",
        "따뜻한 카페": "teahouse", "정원 카페": "greenhouse",
        // 金
        "깔끔한 카페": "lounge", "전망 좋은 곳": "observatory", "감성 서점": "archive",
        "갤러리": "gallery", "전망대": "observatory",
        // 水
        "물가 산책": "sea", "수영장": "spa", "분수대 근처": "fountain",
        "어두운 조명 카페": "lounge", "밤 산책": "moongarden",
    ]

    static func placeAsset(_ value: String) -> String? {
        if let mapped = placeMap[value] { return "place-\(mapped)" }
        return nil
    }

    // MARK: - 운세 컨디션 (5종 고정 일러스트)
    // item-01 화병, 02 모란, 03 나비, 04 진주조개, 05 푸른꽃,
    // 06 만년필, 07 책더미, 08 여행가방, 09 잉크병, 10 골드키
    static let conditionAsset: [String: String] = [
        "재물": "item-01", "연애": "item-02", "인간관계": "item-03",
        "감정": "item-04", "건강": "item-05",
    ]

    // MARK: - 행운 아이템(item) / 음료(drink) / 향기(scent) — 전용 에셋 없음 → 대표 일러스트
    static func itemAsset(category: ItemCategory) -> String {
        switch category {
        case .drink: return "item-01"   // 화병(대표) — 음료 전용 에셋 준비되면 교체
        case .scent: return "item-02"   // 모란(대표)
        case .item: return "item-10"    // 골드키(대표)
        }
    }

    enum ItemCategory { case drink, scent, item }
}

/// 일러스트 우선, 없으면 SF Symbol 폴백하는 아이콘 뷰
struct LuckyIconView: View {
    let assetName: String?
    let fallbackSymbol: String
    var size: CGFloat = 52

    var body: some View {
        Group {
            if let assetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSymbol)
                    .font(.system(size: size * 0.55))
                    .foregroundStyle(DT.accent)
            }
        }
        .frame(width: size, height: size)
    }
}
