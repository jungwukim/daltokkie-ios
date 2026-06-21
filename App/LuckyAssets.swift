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

    // MARK: - 유리구슬 마블 (오행 25색 → 구슬_아이콘 마블, 위치 기준 orb-r{행}c{열})
    // 사용자 제작 마블 그리드를 실제 색 판독으로 오행색에 배정 (일부는 그리드에 정확한 색이 없어 근사)
    static let colorOrbMap: [String: String] = [
        // 木
        "초록": "orb-r1c3", "연두": "orb-r1c4", "청록": "orb-r1c2", "에메랄드": "orb-r1c5", "올리브": "orb-r1c1",
        // 火
        "빨강": "orb-r2c3", "주황": "orb-r2c2", "핑크": "orb-r2c1", "자주": "orb-r2c4", "와인레드": "orb-r2c5",
        // 土
        "갈색": "orb-r3c2", "테라코타": "orb-r3c3", "베이지": "orb-r3c1", "크림": "orb-r3c4", "황토색": "orb-r3c5",
        // 金
        "흰색": "orb-r4c1", "은색": "orb-r4c2", "라이트그레이": "orb-r4c3", "아이보리": "orb-r3c5", "골드": "orb-r3c1",
        // 水
        "검정": "orb-r4c5", "남색": "orb-r5c1", "다크블루": "orb-r5c3", "인디고": "orb-r5c5", "차콜": "orb-r4c3",
    ]

    /// 엔진 한글 색상값 → 유리구슬 마블 에셋 (없으면 nil)
    static func colorOrb(_ value: String) -> String? { colorOrbMap[value] }

    // MARK: - 음료 (엔진 음료값 → drink-NN, elementItems 오행순)
    private static let drinkMap: [String: String] = [
        "레몬에이드": "drink-01",
        "그린티 라떼": "drink-02",
        "녹차": "drink-03",
        "자몽주스": "drink-04",
        "매실차": "drink-05",
        "핫 카카오": "drink-06",
        "생강차": "drink-07",
        "대추차": "drink-08",
        "루이보스티": "drink-09",
        "얼그레이": "drink-10",
        "꿀아메리카노": "drink-11",
        "고구마 라떼": "drink-12",
        "곡물라떼": "drink-13",
        "바닐라라떼": "drink-14",
        "보리차": "drink-15",
        "진저에일": "drink-16",
        "유자에이드": "drink-17",
        "밀크티": "drink-18",
        "유자차": "drink-19",
        "배 주스": "drink-20",
        "콜드브루": "drink-21",
        "코코넛 워터": "drink-22",
        "아이스티": "drink-23",
        "포도 주스": "drink-24",
        "아메리카노": "drink-25",
    ]
    static func drinkAsset(_ value: String) -> String? { drinkMap[value] }

    // MARK: - 장소 (엔진 장소값 → place-NN, elementItems 오행순)
    private static let placeMap: [String: String] = [
        "공원 산책로": "place-01",
        "나무 많은 길": "place-02",
        "꽃집": "place-03",
        "숲속 산책": "place-04",
        "나무 그늘 아래": "place-05",
        "햇볕 쬐기": "place-06",
        "창가 자리": "place-07",
        "미술관": "place-08",
        "테라스 좌석": "place-09",
        "공연장": "place-10",
        "베이커리 카페": "place-11",
        "공원 잔디밭": "place-12",
        "전통 시장": "place-13",
        "따뜻한 카페": "place-14",
        "정원 카페": "place-15",
        "깔끔한 카페": "place-16",
        "전망 좋은 곳": "place-17",
        "감성 서점": "place-18",
        "갤러리": "place-19",
        "전망대": "place-20",
        "물가 산책": "place-21",
        "수영장": "place-22",
        "분수대 근처": "place-23",
        "어두운 조명 카페": "place-24",
        "밤 산책": "place-25",
    ]
    static func placeAsset(_ value: String) -> String? { placeMap[value] }

    // MARK: - 향기 (엔진 향기값 → scent-NN, elementItems 오행순)
    private static let scentMap: [String: String] = [
        "편백나무향": "scent-01",
        "그린티향": "scent-02",
        "페퍼민트": "scent-03",
        "풀잎향": "scent-04",
        "허브향": "scent-05",
        "시나몬": "scent-06",
        "우디향": "scent-07",
        "앰버향": "scent-08",
        "로즈마리": "scent-09",
        "정향향": "scent-10",
        "바닐라향": "scent-11",
        "흙향": "scent-12",
        "샌달우드": "scent-13",
        "카라멜향": "scent-14",
        "꿀향": "scent-15",
        "유칼립투스": "scent-16",
        "화이트머스크": "scent-17",
        "클린코튼향": "scent-18",
        "비누향": "scent-19",
        "티트리": "scent-20",
        "오션향": "scent-21",
        "라벤더": "scent-22",
        "머스크": "scent-23",
        "아쿠아향": "scent-24",
        "자스민": "scent-25",
    ]
    static func scentAsset(_ value: String) -> String? { scentMap[value] }

    // MARK: - 행운 아이템 (엔진 아이템값 → litem-NN, elementItems 오행순. 운세 컨디션 item-NN과 별개)
    private static let luckyItemMap: [String: String] = [
        "연필": "litem-01",
        "에코백": "litem-02",
        "메모지": "litem-03",
        "책": "litem-04",
        "녹색 계열 옷": "litem-05",
        "캔들": "litem-06",
        "무드등": "litem-07",
        "핑크 립밤": "litem-08",
        "선글라스": "litem-09",
        "빨간 머리끈": "litem-10",
        "갈색 종이백": "litem-11",
        "베이지 톤 옷": "litem-12",
        "갈색 노트": "litem-13",
        "따뜻한 차 한잔": "litem-14",
        "갈색 머리끈": "litem-15",
        "은색 악세서리": "litem-16",
        "흰 옷 입기": "litem-17",
        "흰색 양말": "litem-18",
        "스테인리스 텀블러": "litem-19",
        "은색 동전": "litem-20",
        "다크 초콜릿": "litem-21",
        "투명 텀블러": "litem-22",
        "검정 톤 옷": "litem-23",
        "검정 볼펜": "litem-24",
        "네이비 양말": "litem-25",
    ]
    static func luckyItemAsset(_ value: String) -> String? { luckyItemMap[value] }

    // MARK: - 운세 컨디션 (5종 고정 일러스트)
    // item-01 화병, 02 모란, 03 나비, 04 진주조개, 05 푸른꽃,
    // 06 만년필, 07 책더미, 08 여행가방, 09 잉크병, 10 골드키
    static let conditionAsset: [String: String] = [
        "재물": "item-01", "연애": "item-02", "인간관계": "item-03",
        "감정": "item-04", "건강": "item-05",
    ]

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
