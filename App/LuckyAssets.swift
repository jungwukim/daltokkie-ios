// 엔진 행운 아이템/컨디션 값 → Dal Tokkie 일러스트 에셋 매핑
// 에셋: color-<색>, place-<장소>, item-<번호>, dir-<방향> (prepare-assets.sh)

import SwiftUI

enum LuckyAssets {

    // MARK: - 색깔 (엔진 색상값 → color-<폴더 색상명>)
    // 폴더: 초록/연두/청록/에메랄드/카키/빨강/주황/보라/자주/코랄/노랑/베이지/
    //       브라운/아이보리/카멜/흰색/실버/금색/회색/크림/파랑/남색/검정/네이비/인디고
    private static let colorMap: [String: String] = [
        // 木
        "초록": "초록", "연두": "연두", "청록": "청록", "에메랄드": "에메랄드", "올리브": "카키",
        // 火
        "빨강": "빨강", "주황": "주황", "자주": "자주", "핑크": "코랄", "와인레드": "자주",
        // 土
        "황토색": "브라운", "베이지": "베이지", "갈색": "브라운", "크림": "크림", "테라코타": "카멜",
        // 金
        "흰색": "흰색", "은색": "실버", "골드": "금색", "아이보리": "아이보리", "라이트그레이": "회색",
        // 水
        "검정": "검정", "남색": "남색", "다크블루": "네이비", "차콜": "회색", "인디고": "인디고",
    ]

    static func colorAsset(_ value: String) -> String? {
        if let mapped = colorMap[value] { return "color-\(mapped)" }
        return nil
    }

    // MARK: - 장소 (엔진 장소값 → place-<폴더 장소명>)
    // 폴더: 달빛정원/숲길/달빛다실/서고/온실/레스토랑/영화관/공연장/전망대/산/사찰/
    //       도서관/미술관/한옥마을/백화점/갤러리/은행/호텔/라운지/옥상/바다/수족관/스파/분수대광장
    private static let placeMap: [String: String] = [
        // 木
        "공원 산책로": "달빛정원", "나무 많은 길": "숲길", "꽃집": "온실",
        "숲속 산책": "숲길", "나무 그늘 아래": "달빛정원",
        // 火
        "햇볕 쬐기": "옥상", "창가 자리": "달빛다실", "미술관": "미술관",
        "테라스 좌석": "라운지", "공연장": "공연장",
        // 土
        "베이커리 카페": "레스토랑", "공원 잔디밭": "달빛정원", "전통 시장": "한옥마을",
        "따뜻한 카페": "달빛다실", "정원 카페": "온실",
        // 金
        "깔끔한 카페": "라운지", "전망 좋은 곳": "전망대", "감성 서점": "서고",
        "갤러리": "갤러리", "전망대": "전망대",
        // 水
        "물가 산책": "바다", "수영장": "스파", "분수대 근처": "분수대광장",
        "어두운 조명 카페": "라운지", "밤 산책": "달빛정원",
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
