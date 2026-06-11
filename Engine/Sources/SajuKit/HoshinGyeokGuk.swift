// HoshinGyeokGuk — 격국(格局) 판단 시스템
// 원본: packages/fortuneteller/src/lib/gyeok_guk.ts (determineGyeokGuk)
// Swift GyeokGukInfo는 gyeokGuk/name/hanja/description만 사용하므로
// GYEOK_GUK_INFO에서 해당 필드만 포팅한다.

import Foundation

public enum HoshinGyeokGuk {
    /// TS Object.entries(tenGodsDistribution) 삽입 순서 재현
    /// (calculateTenGodsDistribution의 초기화 순서: 비견→정인)
    private static let tenGodOrder = [
        "비견", "겁재", "식신", "상관", "편재", "정재", "편관", "정관", "편인", "정인",
    ]

    /// 격국별 상세 정보 (TS GYEOK_GUK_INFO — name/hanja/description만)
    private static let gyeokGukInfo: [String: (name: String, hanja: String, description: String)] = [
        "jeong_gwan": ("정관격", "正官格", "정관이 월지에 투출하여 일간을 다스리는 격국. 리더십과 책임감이 강한 타입"),
        "jeong_jae": ("정재격", "正財格", "정재가 월지에 투출한 격국. 꾸준함과 안정을 추구하는 타입"),
        "sig_sin": ("식신격", "食神格", "식신이 월지에 투출한 격국. 창의적이고 낙천적인 타입"),
        "jeong_in": ("정인격", "正印格", "정인이 월지에 투출한 격국. 학문과 지혜를 추구하는 타입"),
        "sang_gwan": ("상관격", "傷官格", "상관이 강한 격국. 비판적이고 독창적인 타입"),
        "pyeon_in": ("편인격", "偏印格", "편인이 강한 격국. 독특하고 신비로운 타입"),
        "pyeon_jae": ("편재격", "偏財格", "편재가 강한 격국. 사교적이고 사업 수완이 뛰어난 타입"),
        "chil_sal": ("칠살격", "七殺格", "편관(칠살)이 강한 격국. 강한 추진력과 승부욕을 지닌 타입"),
        "bi_gyeon": ("비견격", "比肩格", "비견이 강한 격국. 독립심과 자존심이 강한 타입"),
        "geob_jae": ("겁재격", "劫財格", "겁재가 강한 격국. 경쟁심과 야망이 강한 타입"),
        "jong_wang": ("종왕격", "從旺格", "일간이 극강하고 비겁이 많아 강함을 따르는 특수 격국"),
        "jong_sal": ("종살격", "從殺格", "관살이 극강하고 일간이 약하여 관살을 따르는 특수 격국"),
        "jong_jae": ("종재격", "從財格", "재성이 극강하고 일간이 약하여 재성을 따르는 특수 격국"),
        "balanced": ("중화격", "中和格", "오행과 십성이 고르게 분포된 균형잡힌 격국"),
    ]

    /// 십성 → 격국 매핑 (TS gyeokGukMap)
    private static let tenGodToGyeokGuk: [String: String] = [
        "정관": "jeong_gwan",
        "정재": "jeong_jae",
        "식신": "sig_sin",
        "정인": "jeong_in",
        "상관": "sang_gwan",
        "편인": "pyeon_in",
        "편재": "pyeon_jae",
        "편관": "chil_sal",
        "비견": "bi_gyeon",
        "겁재": "geob_jae",
    ]

    /// 격국 판단 메인 함수 (TS determineGyeokGuk 1:1 포팅)
    public static func determineGyeokGuk(_ raw: SajuRawData) -> GyeokGukInfo {
        // 1. 특수 격국 판단 (종격)
        if let special = checkSpecialGyeokGuk(raw) {
            return makeInfo(special)
        }

        // 2. 십성 분포에서 가장 많은 십성 찾기
        var dominantTenGod: String? = nil

        let dist = raw.tenGodsDistribution
        if !dist.isEmpty {
            // Object.entries 순서(삽입 순서) + 안정 정렬(동률 시 삽입 순서 유지) 재현
            let entries: [(key: String, count: Double, idx: Int)] = tenGodOrder.enumerated()
                .compactMap { idx, key in
                    guard let count = dist[key], count > 0 else { return nil }
                    return (key, count, idx)
                }
            let sorted = entries.sorted { a, b in
                if a.count != b.count { return a.count > b.count }
                return a.idx < b.idx
            }
            if let first = sorted.first {
                dominantTenGod = first.key
            }
        }

        // 3. 십성별 격국 매핑
        let gyeokGuk = mapTenGodToGyeokGuk(dominantTenGod)
        return makeInfo(gyeokGuk)
    }

    /// 특수 격국(종격) 판단 (TS checkSpecialGyeokGuk)
    private static func checkSpecialGyeokGuk(_ raw: SajuRawData) -> String? {
        let dist = raw.tenGodsDistribution
        if dist.isEmpty { return nil }

        let totalCount = dist.values.reduce(0, +)

        // 비겁이 5개 이상이고 전체의 60% 이상 → 종왕격
        let biGeopCount = (dist["비견"] ?? 0) + (dist["겁재"] ?? 0)
        if biGeopCount >= 5 && biGeopCount / totalCount >= 0.6 {
            return "jong_wang"
        }

        // 관살이 5개 이상이고 전체의 60% 이상 → 종살격
        let gwanSalCount = (dist["정관"] ?? 0) + (dist["편관"] ?? 0)
        if gwanSalCount >= 5 && gwanSalCount / totalCount >= 0.6 {
            return "jong_sal"
        }

        // 재성이 5개 이상이고 전체의 60% 이상 → 종재격
        let jaeCount = (dist["정재"] ?? 0) + (dist["편재"] ?? 0)
        if jaeCount >= 5 && jaeCount / totalCount >= 0.6 {
            return "jong_jae"
        }

        return nil
    }

    /// 십성을 격국으로 매핑 (TS mapTenGodToGyeokGuk)
    private static func mapTenGodToGyeokGuk(_ tenGod: String?) -> String {
        guard let tenGod else { return "balanced" }
        return tenGodToGyeokGuk[tenGod] ?? "balanced"
    }

    private static func makeInfo(_ gyeokGuk: String) -> GyeokGukInfo {
        let info = gyeokGukInfo[gyeokGuk] ?? gyeokGukInfo["balanced"]!
        return GyeokGukInfo(
            gyeokGuk: gyeokGuk,
            name: info.name,
            hanja: info.hanja,
            description: info.description
        )
    }
}
