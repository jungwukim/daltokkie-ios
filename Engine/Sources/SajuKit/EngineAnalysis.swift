// EngineAnalysis — saju-api lib/saju/saju-engine.ts 분석 함수 충실 포팅
// 모든 한국어 문자열/배열 순서/옵셔널 분기는 TS 원본과 1:1 동일해야 한다 (골든 픽스처 검증)

import Foundation

public enum EngineAnalysis {

    // ========== Mapping helpers ==========

    static let ELEMENT_KR_TO_EN: [String: String] = [
        "목": "Wood", "화": "Fire", "토": "Earth", "금": "Metal", "수": "Water",
    ]

    static let BRANCH_KOREAN: [String: String] = [
        "子": "자", "丑": "축", "寅": "인", "卯": "묘", "辰": "진", "巳": "사",
        "午": "오", "未": "미", "申": "신", "酉": "유", "戌": "술", "亥": "해",
    ]

    static let STEM_KR: [String: String] = [
        "甲": "갑", "乙": "을", "丙": "병", "丁": "정", "戊": "무",
        "己": "기", "庚": "경", "辛": "신", "壬": "임", "癸": "계",
    ]

    static let PILLAR_NAMES = ["년주", "월주", "일주", "시주"]

    static let STEMS_HANJA = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]
    static let BRANCHES_HANJA = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

    // ========== 십성(十神) ==========

    static let TEN_GODS_TABLE: [String: [String: String]] = [
        "Wood":  ["Wood": "비견", "WoodYin": "겁재", "Fire": "식신", "FireYin": "상관", "Earth": "편재", "EarthYin": "정재", "Metal": "편관", "MetalYin": "정관", "Water": "편인", "WaterYin": "정인"],
        "Fire":  ["Fire": "비견", "FireYin": "겁재", "Earth": "식신", "EarthYin": "상관", "Metal": "편재", "MetalYin": "정재", "Water": "편관", "WaterYin": "정관", "Wood": "편인", "WoodYin": "정인"],
        "Earth": ["Earth": "비견", "EarthYin": "겁재", "Metal": "식신", "MetalYin": "상관", "Water": "편재", "WaterYin": "정재", "Wood": "편관", "WoodYin": "정관", "Fire": "편인", "FireYin": "정인"],
        "Metal": ["Metal": "비견", "MetalYin": "겁재", "Water": "식신", "WaterYin": "상관", "Wood": "편재", "WoodYin": "정재", "Fire": "편관", "FireYin": "정관", "Earth": "편인", "EarthYin": "정인"],
        "Water": ["Water": "비견", "WaterYin": "겁재", "Wood": "식신", "WoodYin": "상관", "Fire": "편재", "FireYin": "정재", "Earth": "편관", "EarthYin": "정관", "Metal": "편인", "MetalYin": "정인"],
    ]

    public static func getTenGod(dayMasterElement: String, dayMasterYinYang: String, targetElement: String, targetYinYang: String) -> String {
        let sameYY = dayMasterYinYang == targetYinYang
        guard let table = TEN_GODS_TABLE[dayMasterElement] else { return "" }
        if targetElement == dayMasterElement {
            return sameYY ? "비견" : "겁재"
        }
        let key = sameYY ? targetElement : targetElement + "Yin"
        return table[key] ?? ""
    }

    // 지장간 본기의 오행/음양 (지지 십성 계산용)
    static let BRANCH_HANJA_TO_PRIMARY_STEM: [String: (element: String, yin_yang: String)] = [
        "子": ("Water", "Yin"),     // 癸
        "丑": ("Earth", "Yin"),     // 己
        "寅": ("Wood", "Yang"),     // 甲
        "卯": ("Wood", "Yin"),      // 乙
        "辰": ("Earth", "Yang"),    // 戊
        "巳": ("Fire", "Yang"),     // 丙
        "午": ("Fire", "Yin"),      // 丁
        "未": ("Earth", "Yin"),     // 己
        "申": ("Metal", "Yang"),    // 庚
        "酉": ("Metal", "Yin"),     // 辛
        "戌": ("Earth", "Yang"),    // 戊
        "亥": ("Water", "Yang"),    // 壬
    ]

    public static func calculateTenGods(dayMasterElement: String, dayMasterYinYang: String, pillars: SajuPillars) -> TenGodChart {
        func calcStem(_ s: UIStem) -> String {
            getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: s.element, targetYinYang: s.yin_yang)
        }
        func calcBranch(_ b: UIBranch) -> String {
            guard let primary = BRANCH_HANJA_TO_PRIMARY_STEM[b.hanja] else { return "" }
            return getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: primary.element, targetYinYang: primary.yin_yang)
        }
        return TenGodChart(
            year: TenGodPillar(stem: calcStem(pillars.year.stem), branch: calcBranch(pillars.year.branch)),
            month: TenGodPillar(stem: calcStem(pillars.month.stem), branch: calcBranch(pillars.month.branch)),
            day: TenGodPillar(stem: "(본인)", branch: calcBranch(pillars.day.branch)),
            hour: pillars.hour.map { TenGodPillar(stem: calcStem($0.stem), branch: calcBranch($0.branch)) }
        )
    }

    // ========== 12운성(十二運星) ==========

    static let TWELVE_STAGE_MAP: [String: [String: String]] = [
        "甲": ["亥": "장생", "子": "목욕", "丑": "관대", "寅": "건록", "卯": "제왕", "辰": "쇠", "巳": "병", "午": "사", "未": "묘", "申": "절", "酉": "태", "戌": "양"],
        "乙": ["午": "장생", "巳": "목욕", "辰": "관대", "卯": "건록", "寅": "제왕", "丑": "쇠", "子": "병", "亥": "사", "戌": "묘", "酉": "절", "申": "태", "未": "양"],
        "丙": ["寅": "장생", "卯": "목욕", "辰": "관대", "巳": "건록", "午": "제왕", "未": "쇠", "申": "병", "酉": "사", "戌": "묘", "亥": "절", "子": "태", "丑": "양"],
        "丁": ["酉": "장생", "申": "목욕", "未": "관대", "午": "건록", "巳": "제왕", "辰": "쇠", "卯": "병", "寅": "사", "丑": "묘", "子": "절", "亥": "태", "戌": "양"],
        "戊": ["寅": "장생", "卯": "목욕", "辰": "관대", "巳": "건록", "午": "제왕", "未": "쇠", "申": "병", "酉": "사", "戌": "묘", "亥": "절", "子": "태", "丑": "양"],
        "己": ["酉": "장생", "申": "목욕", "未": "관대", "午": "건록", "巳": "제왕", "辰": "쇠", "卯": "병", "寅": "사", "丑": "묘", "子": "절", "亥": "태", "戌": "양"],
        "庚": ["巳": "장생", "午": "목욕", "未": "관대", "申": "건록", "酉": "제왕", "戌": "쇠", "亥": "병", "子": "사", "丑": "묘", "寅": "절", "卯": "태", "辰": "양"],
        "辛": ["子": "장생", "亥": "목욕", "戌": "관대", "酉": "건록", "申": "제왕", "未": "쇠", "午": "병", "巳": "사", "辰": "묘", "卯": "절", "寅": "태", "丑": "양"],
        "壬": ["申": "장생", "酉": "목욕", "戌": "관대", "亥": "건록", "子": "제왕", "丑": "쇠", "寅": "병", "卯": "사", "辰": "묘", "巳": "절", "午": "태", "未": "양"],
        "癸": ["卯": "장생", "寅": "목욕", "丑": "관대", "子": "건록", "亥": "제왕", "戌": "쇠", "酉": "병", "申": "사", "未": "묘", "午": "절", "巳": "태", "辰": "양"],
    ]

    public static func getTwelveStage(dayMasterHanja: String, branchHanja: String) -> String {
        TWELVE_STAGE_MAP[dayMasterHanja]?[branchHanja] ?? "절"
    }

    static let PILLAR_PERIODS = (
        year: "초년운 (0~15세)",
        month: "청년운 (15~35세)",
        day: "중년운 (35~50세)",
        hour: "말년운 (50세~)"
    )

    public static func calculateTwelveStages(dayMasterHanja: String, pillars: SajuPillars) -> TwelveStageChart {
        TwelveStageChart(
            year: TwelveStagePillar(stage: getTwelveStage(dayMasterHanja: dayMasterHanja, branchHanja: pillars.year.branch.hanja), period: PILLAR_PERIODS.year),
            month: TwelveStagePillar(stage: getTwelveStage(dayMasterHanja: dayMasterHanja, branchHanja: pillars.month.branch.hanja), period: PILLAR_PERIODS.month),
            day: TwelveStagePillar(stage: getTwelveStage(dayMasterHanja: dayMasterHanja, branchHanja: pillars.day.branch.hanja), period: PILLAR_PERIODS.day),
            hour: pillars.hour.map { TwelveStagePillar(stage: getTwelveStage(dayMasterHanja: dayMasterHanja, branchHanja: $0.branch.hanja), period: PILLAR_PERIODS.hour) }
        )
    }

    static let TWELVE_STAGE_DESC: [String: TwelveStageDescription] = [
        "장생": TwelveStageDescription(emoji: "🌱", meaning: "생명력이 시작되는 단계, 활력과 성장의 기운", strength: "강"),
        "목욕": TwelveStageDescription(emoji: "🛁", meaning: "묵묵하는 단계, 변화와 정화의 시기", strength: "중"),
        "관대": TwelveStageDescription(emoji: "👑", meaning: "성장하여 관을 쓰는 단계, 자신감과 기품", strength: "강"),
        "건록": TwelveStageDescription(emoji: "💪", meaning: "왕성한 활동기, 직장과 생산의 에너지", strength: "강"),
        "제왕": TwelveStageDescription(emoji: "👑", meaning: "최고의 전성기, 권위와 지배력", strength: "강"),
        "쇠":   TwelveStageDescription(emoji: "📉", meaning: "기운이 서서히 줄어드는 단계", strength: "중"),
        "병":   TwelveStageDescription(emoji: "🤒", meaning: "기운이 약해지는 단계, 관리가 필요", strength: "약"),
        "사":   TwelveStageDescription(emoji: "💀", meaning: "기운이 극도로 약한 단계", strength: "약"),
        "묘":   TwelveStageDescription(emoji: "⚰️", meaning: "에너지가 저장되는 단계, 잠재력 축적", strength: "약"),
        "절":   TwelveStageDescription(emoji: "✂️", meaning: "완전한 단절, 새로운 시작 직전", strength: "약"),
        "태":   TwelveStageDescription(emoji: "🤰", meaning: "새 생명이 잉태되는 단계", strength: "중"),
        "양":   TwelveStageDescription(emoji: "👶", meaning: "양육되는 단계, 보호와 성장의 기운", strength: "중"),
    ]

    public static func getTwelveStageDescription(stage: String) -> TwelveStageDescription? {
        TWELVE_STAGE_DESC[stage]
    }

    // ========== 지장간(地藏干) ==========

    static let HIDDEN_STEMS_MAP: [String: [HiddenStem]] = [
        "子": [HiddenStem(stem: "癸", element: "Water", type: "본기", ratio: 100)],
        "丑": [HiddenStem(stem: "己", element: "Earth", type: "본기", ratio: 60), HiddenStem(stem: "癸", element: "Water", type: "중기", ratio: 30), HiddenStem(stem: "辛", element: "Metal", type: "여기", ratio: 10)],
        "寅": [HiddenStem(stem: "甲", element: "Wood", type: "본기", ratio: 60), HiddenStem(stem: "丙", element: "Fire", type: "중기", ratio: 30), HiddenStem(stem: "戊", element: "Earth", type: "여기", ratio: 10)],
        "卯": [HiddenStem(stem: "乙", element: "Wood", type: "본기", ratio: 100)],
        "辰": [HiddenStem(stem: "戊", element: "Earth", type: "본기", ratio: 60), HiddenStem(stem: "乙", element: "Wood", type: "중기", ratio: 30), HiddenStem(stem: "癸", element: "Water", type: "여기", ratio: 10)],
        "巳": [HiddenStem(stem: "丙", element: "Fire", type: "본기", ratio: 60), HiddenStem(stem: "庚", element: "Metal", type: "중기", ratio: 30), HiddenStem(stem: "戊", element: "Earth", type: "여기", ratio: 10)],
        "午": [HiddenStem(stem: "丁", element: "Fire", type: "본기", ratio: 70), HiddenStem(stem: "己", element: "Earth", type: "중기", ratio: 30)],
        "未": [HiddenStem(stem: "己", element: "Earth", type: "본기", ratio: 60), HiddenStem(stem: "丁", element: "Fire", type: "중기", ratio: 30), HiddenStem(stem: "乙", element: "Wood", type: "여기", ratio: 10)],
        "申": [HiddenStem(stem: "庚", element: "Metal", type: "본기", ratio: 60), HiddenStem(stem: "壬", element: "Water", type: "중기", ratio: 30), HiddenStem(stem: "戊", element: "Earth", type: "여기", ratio: 10)],
        "酉": [HiddenStem(stem: "辛", element: "Metal", type: "본기", ratio: 100)],
        "戌": [HiddenStem(stem: "戊", element: "Earth", type: "본기", ratio: 60), HiddenStem(stem: "辛", element: "Metal", type: "중기", ratio: 30), HiddenStem(stem: "丁", element: "Fire", type: "여기", ratio: 10)],
        "亥": [HiddenStem(stem: "壬", element: "Water", type: "본기", ratio: 70), HiddenStem(stem: "甲", element: "Wood", type: "중기", ratio: 30)],
    ]

    public static func getHiddenStems(branchHanja: String) -> [HiddenStem] {
        HIDDEN_STEMS_MAP[branchHanja] ?? []
    }

    // STEM_HANJA_INFO / STEM_ELEMENT_MAP 공용 — 삽입 순서 보존을 위한 배열 + 조회용 사전
    static let STEM_ELEMENT_ORDER: [(hanja: String, element: String, yinYang: String)] = [
        ("甲", "Wood", "Yang"),
        ("乙", "Wood", "Yin"),
        ("丙", "Fire", "Yang"),
        ("丁", "Fire", "Yin"),
        ("戊", "Earth", "Yang"),
        ("己", "Earth", "Yin"),
        ("庚", "Metal", "Yang"),
        ("辛", "Metal", "Yin"),
        ("壬", "Water", "Yang"),
        ("癸", "Water", "Yin"),
    ]

    static let STEM_ELEMENT_MAP: [String: (element: String, yinYang: String)] = {
        var map: [String: (element: String, yinYang: String)] = [:]
        for entry in STEM_ELEMENT_ORDER {
            map[entry.hanja] = (entry.element, entry.yinYang)
        }
        return map
    }()

    static func getHiddenStemsWithTenGod(branchHanja: String, dayMasterElement: String, dayMasterYinYang: String) -> [HiddenStem] {
        let stems = getHiddenStems(branchHanja: branchHanja)
        return stems.map { hs in
            let tenGod: String
            if let info = STEM_ELEMENT_MAP[hs.stem] {
                tenGod = getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: info.element, targetYinYang: info.yinYang)
            } else {
                tenGod = ""
            }
            return HiddenStem(stem: hs.stem, element: hs.element, type: hs.type, ratio: hs.ratio, tenGod: tenGod)
        }
    }

    public static func calculateHiddenStems(pillars: SajuPillars, dayMasterElement: String? = nil, dayMasterYinYang: String? = nil) -> HiddenStemsChart {
        if let dmEl = dayMasterElement, let dmYY = dayMasterYinYang {
            return HiddenStemsChart(
                year: getHiddenStemsWithTenGod(branchHanja: pillars.year.branch.hanja, dayMasterElement: dmEl, dayMasterYinYang: dmYY),
                month: getHiddenStemsWithTenGod(branchHanja: pillars.month.branch.hanja, dayMasterElement: dmEl, dayMasterYinYang: dmYY),
                day: getHiddenStemsWithTenGod(branchHanja: pillars.day.branch.hanja, dayMasterElement: dmEl, dayMasterYinYang: dmYY),
                hour: pillars.hour.map { getHiddenStemsWithTenGod(branchHanja: $0.branch.hanja, dayMasterElement: dmEl, dayMasterYinYang: dmYY) }
            )
        }
        return HiddenStemsChart(
            year: getHiddenStems(branchHanja: pillars.year.branch.hanja),
            month: getHiddenStems(branchHanja: pillars.month.branch.hanja),
            day: getHiddenStems(branchHanja: pillars.day.branch.hanja),
            hour: pillars.hour.map { getHiddenStems(branchHanja: $0.branch.hanja) }
        )
    }

    // ========== 합충형파해(合沖刑破害) 테이블 ==========

    static let SIX_HARMONIES: [(String, String, String)] = [
        ("子", "丑", "토(土)로 합화"), ("寅", "亥", "목(木)으로 합화"), ("卯", "戌", "화(火)로 합화"),
        ("辰", "酉", "금(金)으로 합화"), ("巳", "申", "수(水)로 합화"), ("午", "未", "토(土)/화(火)로 합화"),
    ]

    static let SIX_CLASHES: [(String, String)] = [
        ("子", "午"), ("丑", "未"), ("寅", "申"), ("卯", "酉"), ("辰", "戌"), ("巳", "亥"),
    ]

    static let THREE_PUNISHMENTS: [(String, String, String)] = [
        ("寅", "巳", "무례지형(無禮之刑)"), ("巳", "申", "무례지형(無禮之刑)"), ("寅", "申", "무례지형(無禮之刑)"),
        ("丑", "戌", "지세지형(持勢之刑)"), ("戌", "未", "지세지형(持勢之刑)"), ("丑", "未", "지세지형(持勢之刑)"),
        ("子", "卯", "무은지형(無恩之刑)"),
        ("辰", "辰", "자형(自刑)"), ("午", "午", "자형(自刑)"), ("酉", "酉", "자형(自刑)"), ("亥", "亥", "자형(自刑)"),
    ]

    static let DESTRUCTIONS: [(String, String)] = [
        ("子", "酉"), ("丑", "辰"), ("寅", "亥"), ("卯", "午"), ("巳", "申"), ("未", "戌"),
    ]

    static let HARMS: [(String, String, String)] = [
        ("子", "未", "서로 해치는 관계"), ("丑", "午", "서로 해치는 관계"),
        ("寅", "巳", "서로 해치는 관계"), ("卯", "辰", "서로 해치는 관계"),
        ("申", "亥", "서로 해치는 관계"), ("酉", "戌", "서로 해치는 관계"),
    ]

    static let WON_JIN: [(String, String)] = [
        ("子", "未"), ("丑", "午"), ("寅", "酉"), ("卯", "申"), ("辰", "亥"), ("巳", "戌"),
    ]

    static let GWI_MUN: [(String, String)] = [
        ("子", "酉"), ("丑", "午"), ("寅", "未"), ("卯", "申"), ("辰", "亥"), ("巳", "戌"),
    ]

    static let SAM_HAP: [(branches: [String], element: String, name: String)] = [
        (["寅", "午", "戌"], "火", "인오술 화국(火局)"),
        (["巳", "酉", "丑"], "金", "사유축 금국(金局)"),
        (["申", "子", "辰"], "水", "신자진 수국(水局)"),
        (["亥", "卯", "未"], "木", "해묘미 목국(木局)"),
    ]

    static let BAN_HAP: [(pair: [String], element: String, name: String)] = [
        (["寅", "午"], "火", "인오 반합 화국"),
        (["午", "戌"], "火", "오술 반합 화국"),
        (["巳", "酉"], "金", "사유 반합 금국"),
        (["酉", "丑"], "金", "유축 반합 금국"),
        (["申", "子"], "水", "신자 반합 수국"),
        (["子", "辰"], "水", "자진 반합 수국"),
        (["亥", "卯"], "木", "해묘 반합 목국"),
        (["卯", "未"], "木", "묘미 반합 목국"),
    ]

    static let BANG_HAP: [(branches: [String], element: String, name: String)] = [
        (["寅", "卯", "辰"], "木", "인묘진 동방목국"),
        (["巳", "午", "未"], "火", "사오미 남방화국"),
        (["申", "酉", "戌"], "金", "신유술 서방금국"),
        (["亥", "子", "丑"], "水", "해자축 북방수국"),
    ]

    static let CHEONGAN_HAP_TABLE: [(pair: [String], element: String, name: String)] = [
        (["甲", "己"], "土", "갑기합토(甲己合土)"),
        (["乙", "庚"], "金", "을경합금(乙庚合金)"),
        (["丙", "辛"], "水", "병신합수(丙辛合水)"),
        (["丁", "壬"], "木", "정임합목(丁壬合木)"),
        (["戊", "癸"], "火", "무계합화(戊癸合火)"),
    ]

    static let CHEONGAN_CHUNG_TABLE: [(String, String)] = [
        ("甲", "庚"), ("乙", "辛"), ("丙", "壬"), ("丁", "癸"),
    ]

    // ========== 합충형파해(合沖刑破害) ==========

    public static func calculateBranchRelations(pillars: SajuPillars) -> [BranchRelation] {
        var bs: [String] = [pillars.year.branch.hanja, pillars.month.branch.hanja, pillars.day.branch.hanja]
        if let hour = pillars.hour { bs.append(hour.branch.hanja) }
        func bk(_ h: String) -> String { BRANCH_KOREAN[h] ?? h }
        var results: [BranchRelation] = []

        for i in 0..<bs.count {
            for j in (i + 1)..<bs.count {
                let b1 = bs[i]
                let b2 = bs[j]
                let pillarPair = [PILLAR_NAMES[i], PILLAR_NAMES[j]]

                for (a, b, desc) in SIX_HARMONIES {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "합", typeName: "육합(六合)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: desc))
                    }
                }
                for (a, b) in SIX_CLASHES {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "충", typeName: "육충(六沖)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: "서로 충돌하는 관계"))
                    }
                }
                for (a, b, desc) in THREE_PUNISHMENTS {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "형", typeName: "형(刑)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: desc))
                    }
                }
                for (a, b) in DESTRUCTIONS {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "파", typeName: "파(破)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: "관계가 깨지는 기운"))
                    }
                }
                for (a, b, desc) in HARMS {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "해", typeName: "해(害)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: desc))
                    }
                }
                for (a, b) in WON_JIN {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "원진", typeName: "원진(怨嗔)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: "원한과 미움의 관계, 서로 불편함"))
                    }
                }
                for (a, b) in GWI_MUN {
                    if (b1 == a && b2 == b) || (b1 == b && b2 == a) {
                        results.append(BranchRelation(type: "귀문관살", typeName: "귀문관살(鬼門關殺)", branches: [b1, b2], branchesKorean: [bk(b1), bk(b2)], pillars: pillarPair, description: "정신적 불안, 예민한 감수성"))
                    }
                }
            }
        }

        return results
    }

    // ========== 삼합/반합/방합 ==========

    public static func calculateMultiRelations(pillars: SajuPillars) -> [MultiRelation] {
        var bs: [String] = [pillars.year.branch.hanja, pillars.month.branch.hanja, pillars.day.branch.hanja]
        if let hour = pillars.hour { bs.append(hour.branch.hanja) }
        func bk(_ h: String) -> String { BRANCH_KOREAN[h] ?? h }
        let branchSet = Set(bs)
        var results: [MultiRelation] = []

        for entry in SAM_HAP {
            if entry.branches.allSatisfy({ branchSet.contains($0) }) {
                let pNames = entry.branches.map { PILLAR_NAMES[bs.firstIndex(of: $0)!] }
                results.append(MultiRelation(type: "삼합", typeName: "삼합(三合)", branches: entry.branches, branchesKorean: entry.branches.map(bk), pillars: pNames, description: entry.name, resultElement: entry.element))
            }
        }

        for entry in BANG_HAP {
            if entry.branches.allSatisfy({ branchSet.contains($0) }) {
                let pNames = entry.branches.map { PILLAR_NAMES[bs.firstIndex(of: $0)!] }
                results.append(MultiRelation(type: "방합", typeName: "방합(方合)", branches: entry.branches, branchesKorean: entry.branches.map(bk), pillars: pNames, description: entry.name, resultElement: entry.element))
            }
        }

        for entry in BAN_HAP {
            if entry.pair.allSatisfy({ branchSet.contains($0) }) {
                let alreadySamHap = SAM_HAP.contains { sh in
                    sh.branches.contains(entry.pair[0]) && sh.branches.contains(entry.pair[1]) && sh.branches.allSatisfy { branchSet.contains($0) }
                }
                if !alreadySamHap {
                    let pNames = entry.pair.map { PILLAR_NAMES[bs.firstIndex(of: $0)!] }
                    results.append(MultiRelation(type: "반합", typeName: "반합(半合)", branches: entry.pair, branchesKorean: entry.pair.map(bk), pillars: pNames, description: entry.name, resultElement: entry.element))
                }
            }
        }

        return results
    }

    // ========== 천간합/천간충 ==========

    public static func calculateStemRelations(pillars: SajuPillars) -> [StemRelation] {
        var ss: [String] = [pillars.year.stem.hanja, pillars.month.stem.hanja, pillars.day.stem.hanja]
        if let hour = pillars.hour { ss.append(hour.stem.hanja) }
        func sk(_ h: String) -> String { STEM_KR[h] ?? h }
        var results: [StemRelation] = []

        for i in 0..<ss.count {
            for j in (i + 1)..<ss.count {
                let s1 = ss[i]
                let s2 = ss[j]
                let pillarPair = [PILLAR_NAMES[i], PILLAR_NAMES[j]]

                for entry in CHEONGAN_HAP_TABLE {
                    if (s1 == entry.pair[0] && s2 == entry.pair[1]) || (s1 == entry.pair[1] && s2 == entry.pair[0]) {
                        results.append(StemRelation(type: "천간합", typeName: "천간합(天干合)", stems: [s1, s2], stemsKorean: [sk(s1), sk(s2)], pillars: pillarPair, description: entry.name, resultElement: entry.element))
                    }
                }
                for (a, b) in CHEONGAN_CHUNG_TABLE {
                    if (s1 == a && s2 == b) || (s1 == b && s2 == a) {
                        results.append(StemRelation(type: "천간충", typeName: "천간충(天干沖)", stems: [s1, s2], stemsKorean: [sk(s1), sk(s2)], pillars: pillarPair, description: "서로 충돌하는 천간"))
                    }
                }
            }
        }

        return results
    }

    // ========== 공망(空亡) ==========

    public static func calculateGongMang(dayStemHanja: String, dayBranchHanja: String, pillars: SajuPillars) -> GongMangResult {
        let stemIdx = STEMS_HANJA.firstIndex(of: dayStemHanja) ?? -1
        let branchIdx = BRANCHES_HANJA.firstIndex(of: dayBranchHanja) ?? -1
        let startBranch = ((branchIdx - stemIdx) % 12 + 12) % 12
        let void1Idx = (startBranch + 10) % 12
        let void2Idx = (startBranch + 11) % 12
        let voidBranch1 = BRANCHES_HANJA[void1Idx]
        let voidBranch2 = BRANCHES_HANJA[void2Idx]

        let group = "甲\(BRANCHES_HANJA[startBranch])旬"

        func bk(_ h: String) -> String { BRANCH_KOREAN[h] ?? h }
        var allBranches: [(hanja: String, name: String)] = [
            (pillars.year.branch.hanja, "년주"),
            (pillars.month.branch.hanja, "월주"),
            (pillars.day.branch.hanja, "일주"),
        ]
        if let hour = pillars.hour { allBranches.append((hour.branch.hanja, "시주")) }
        let affected = allBranches
            .filter { $0.name != "일주" && ($0.hanja == voidBranch1 || $0.hanja == voidBranch2) }
            .map { $0.name }

        return GongMangResult(
            group: group,
            voidBranches: [voidBranch1, voidBranch2],
            voidBranchesKorean: [bk(voidBranch1), bk(voidBranch2)],
            affectedPillars: affected,
            description: affected.count > 0
                ? "\(affected.joined(separator: ", "))에 공망 — 해당 궁의 기운이 허(虛)합니다"
                : "공망이 사주 원국의 지지에 해당하지 않습니다"
        )
    }

    // ========== 12신살(十二神殺) ==========

    static let SPIRITS_12: [(hanja: String, hangul: String, type: String, description: String)] = [
        ("劫殺", "겁살", "흉살", "갑작스러운 재물 손실, 도난의 기운"),
        ("災殺", "재살", "흉살", "재난, 질병, 사고의 기운"),
        ("天殺", "천살", "흉살", "하늘에서 오는 재앙, 예측불가한 변화"),
        ("地殺", "지살", "흉살", "땅에서 오는 재앙, 부동산·거주 문제"),
        ("桃花殺", "도화살", "중성", "매력과 유혹의 기운, 이성 관계, 예술적 감각"),
        ("月殺", "월살", "흉살", "고독과 방황, 정신적 불안"),
        ("亡身", "망신", "흉살", "체면 손상, 명예 실추"),
        ("將星", "장성", "길신", "리더십, 권위, 조직 내 상승"),
        ("攀鞍", "반안", "길신", "안정과 편안함, 귀인의 도움"),
        ("驛馬", "역마", "중성", "이동, 변화, 활동적 에너지"),
        ("六害", "육해", "흉살", "인간관계 파열, 배신"),
        ("華蓋", "화개", "중성", "예술, 학문, 종교적 기운, 고독한 재능"),
    ]

    static let SPIRIT_START: [String: Int] = [
        "寅": 11, "午": 11, "戌": 11,  // 亥에서 시작
        "巳": 2,  "酉": 2,  "丑": 2,   // 寅에서 시작
        "申": 5,  "子": 5,  "辰": 5,   // 巳에서 시작
        "亥": 8,  "卯": 8,  "未": 8,   // 申에서 시작
    ]

    public static func calculateTwelveSpirits(yearBranchHanja: String, pillars: SajuPillars) -> [TwelveSpiritEntry] {
        guard let start = SPIRIT_START[yearBranchHanja] else { return [] }

        var entries: [TwelveSpiritEntry] = []
        var pillarData: [(name: String, branch: String)] = [
            ("년주", pillars.year.branch.hanja),
            ("월주", pillars.month.branch.hanja),
            ("일주", pillars.day.branch.hanja),
        ]
        if let hour = pillars.hour { pillarData.append(("시주", hour.branch.hanja)) }

        for pd in pillarData {
            guard let targetIdx = BRANCHES_HANJA.firstIndex(of: pd.branch) else { continue }
            let offset = ((targetIdx - start) % 12 + 12) % 12
            let spirit = SPIRITS_12[offset]
            entries.append(TwelveSpiritEntry(
                pillar: pd.name,
                branchHanja: pd.branch,
                branchKorean: BRANCH_KOREAN[pd.branch] ?? pd.branch,
                spiritHanja: spirit.hanja,
                spiritHangul: spirit.hangul,
                spiritType: spirit.type,
                description: spirit.description
            ))
        }

        return entries
    }

    // ========== 확장 신살(神殺) — orrery 알고리즘 기반 자체 구현 ==========

    static let YANGIN_MAP: [String: String] = [
        "甲": "卯", "丙": "午", "戊": "午", "庚": "酉", "壬": "子",
    ]

    static let BAEKHO_PILLARS: Set<String> = ["甲辰", "乙未", "丙戌", "丁丑", "戊辰", "壬戌", "癸丑"]
    static let GOEGANG_PILLARS: Set<String> = ["庚辰", "庚戌", "壬辰", "壬戌"]

    static let DOHWA_MAP: [String: String] = [
        "寅": "卯", "午": "卯", "戌": "卯",
        "申": "酉", "子": "酉", "辰": "酉",
        "巳": "午", "酉": "午", "丑": "午",
        "亥": "子", "卯": "子", "未": "子",
    ]

    static let CHEONUL_MAP: [String: [String]] = [
        "甲": ["丑", "未"], "戊": ["丑", "未"], "庚": ["丑", "未"],
        "乙": ["子", "申"], "己": ["子", "申"],
        "丙": ["亥", "酉"], "丁": ["亥", "酉"],
        "辛": ["午", "寅"],
        "壬": ["巳", "卯"], "癸": ["巳", "卯"],
    ]

    static let CHEONDUK_MAP: [String: String] = [
        "寅": "丁", "卯": "申", "辰": "壬", "巳": "辛",
        "午": "亥", "未": "甲", "申": "癸", "酉": "寅",
        "戌": "丙", "亥": "乙", "子": "巳", "丑": "庚",
    ]

    static let WOLDUK_MAP: [String: String] = [
        "寅": "丙", "午": "丙", "戌": "丙",
        "申": "壬", "子": "壬", "辰": "壬",
        "巳": "庚", "酉": "庚", "丑": "庚",
        "亥": "甲", "卯": "甲", "未": "甲",
    ]

    static let MUNCHANG_MAP: [String: String] = [
        "甲": "巳", "乙": "午", "丙": "申", "丁": "酉",
        "戊": "申", "己": "酉", "庚": "亥", "辛": "子",
        "壬": "寅", "癸": "卯",
    ]

    static let HONGYEOM_PILLARS: Set<String> = ["甲午", "丙寅", "丁未", "戊辰", "庚戌", "辛酉", "壬子"]

    static let GEUMYEO_MAP: [String: String] = [
        "甲": "辰", "乙": "巳", "丙": "未", "丁": "申",
        "戊": "未", "己": "申", "庚": "戌", "辛": "亥",
        "壬": "丑", "癸": "寅",
    ]

    public static func calculateSpecialSals(stems: [String], branches: [String], dayPillar: String) -> [SpecialSalEntry] {
        let dayStem = stems[1]
        let dayBranch = branches[1]
        let monthBranch = branches[2]
        var results: [SpecialSalEntry] = []

        // 양인살
        if let yanginBranch = YANGIN_MAP[dayStem] {
            var indices: [Int] = []
            for (i, b) in branches.enumerated() where b == yanginBranch { indices.append(i) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "양인살", hanja: "羊刃殺", type: "흉살", pillarIndices: indices, description: "날카로운 기운, 과감하나 부상·수술 주의"))
            }
        }

        // 백호살
        if BAEKHO_PILLARS.contains(dayPillar) {
            results.append(SpecialSalEntry(name: "백호살", hanja: "白虎殺", type: "흉살", pillarIndices: [1], description: "사고, 부상, 급격한 변화"))
        }

        // 괴강살
        if GOEGANG_PILLARS.contains(dayPillar) {
            results.append(SpecialSalEntry(name: "괴강살", hanja: "魁罡殺", type: "중성", pillarIndices: [1], description: "강한 결단력과 카리스마, 극과 극의 성향"))
        }

        // 도화살 (일지 삼합 기준)
        if let dohwaBranch = DOHWA_MAP[dayBranch] {
            var indices: [Int] = []
            for (i, b) in branches.enumerated() where i != 1 && b == dohwaBranch { indices.append(i) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "도화살", hanja: "桃花殺", type: "중성", pillarIndices: indices, description: "매력, 인기, 예술적 감각, 이성 관계"))
            }
        }

        // 천을귀인 (일간 기준)
        let cheonulBranches = CHEONUL_MAP[dayStem] ?? []
        if cheonulBranches.count > 0 {
            var indices: [Int] = []
            for (i, b) in branches.enumerated() where cheonulBranches.contains(b) { indices.append(i) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "천을귀인", hanja: "天乙貴人", type: "길신", pillarIndices: indices, description: "귀인의 도움, 위기에서 구원받는 기운"))
            }
        }

        // 천덕귀인 (월지 기준)
        if let cheondukChar = CHEONDUK_MAP[monthBranch] {
            var rawIndices: [Int] = []
            for (i, ch) in (stems + branches).enumerated() where ch == cheondukChar { rawIndices.append(i % 4) }
            var indices: [Int] = []
            for v in rawIndices where !indices.contains(v) { indices.append(v) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "천덕귀인", hanja: "天德貴人", type: "길신", pillarIndices: indices, description: "하늘의 덕이 함께하는 기운, 재앙 소멸"))
            }
        }

        // 월덕귀인 (월지 기준)
        if let woldukChar = WOLDUK_MAP[monthBranch] {
            var indices: [Int] = []
            for (i, s) in stems.enumerated() where s == woldukChar { indices.append(i) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "월덕귀인", hanja: "月德貴人", type: "길신", pillarIndices: indices, description: "달의 덕으로 보호받는 기운, 흉을 길로 전환"))
            }
        }

        // 문창귀인 (일간 기준)
        if let munchangBranch = MUNCHANG_MAP[dayStem] {
            var indices: [Int] = []
            for (i, b) in branches.enumerated() where b == munchangBranch { indices.append(i) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "문창귀인", hanja: "文昌貴人", type: "길신", pillarIndices: indices, description: "학문과 글재주, 시험운, 문서운"))
            }
        }

        // 홍염살
        if HONGYEOM_PILLARS.contains(dayPillar) {
            results.append(SpecialSalEntry(name: "홍염살", hanja: "紅艶殺", type: "중성", pillarIndices: [1], description: "강한 이성 매력, 정열적 성향"))
        }

        // 금여록 (일간 기준)
        if let geumyeoBranch = GEUMYEO_MAP[dayStem] {
            var indices: [Int] = []
            for (i, b) in branches.enumerated() where b == geumyeoBranch { indices.append(i) }
            if indices.count > 0 {
                results.append(SpecialSalEntry(name: "금여록", hanja: "金輿祿", type: "길신", pillarIndices: indices, description: "귀한 수레를 탈 기운, 배우자 복"))
            }
        }

        return results
    }

    // ========== 좌법(坐法) ==========

    public static func calculateJwabeop(dayStemHanja: String, dayBranchHanja: String, pillars: SajuPillars) -> JwabeopChart {
        var branches: [String] = [pillars.year.branch.hanja, pillars.month.branch.hanja, pillars.day.branch.hanja]
        if let hour = pillars.hour { branches.append(hour.branch.hanja) }

        guard let dayInfo = STEM_ELEMENT_MAP[dayStemHanja] else {
            return branches.map { _ in [JwaEntry]() }
        }

        return branches.map { branch in
            let hiddenStems = getHiddenStems(branchHanja: branch)
            return hiddenStems.map { hs in
                let sipsin: String
                if let targetInfo = STEM_ELEMENT_MAP[hs.stem] {
                    sipsin = getTenGod(dayMasterElement: dayInfo.element, dayMasterYinYang: dayInfo.yinYang, targetElement: targetInfo.element, targetYinYang: targetInfo.yinYang)
                } else {
                    sipsin = ""
                }
                let unseong = getTwelveStage(dayMasterHanja: hs.stem, branchHanja: dayBranchHanja)
                return JwaEntry(
                    stem: hs.stem,
                    stemKorean: STEM_KR[hs.stem] ?? hs.stem,
                    sipsin: sipsin,
                    unseong: unseong
                )
            }
        }
    }

    // ========== 일주 성향 분석 (누락 십성 양간 시딩) ==========

    static let YANG_STEM_OF: [String: String] = [
        "Wood": "甲", "Fire": "丙", "Earth": "戊", "Metal": "庚", "Water": "壬",
    ]

    static let SIPSIN_CATEGORIES: [(name: String, hanja: String, interactions: [String])] = [
        ("비겁", "比劫", ["same"]),
        ("식상", "食傷", ["output"]),
        ("재성", "財星", ["sword"]),
        ("관성", "官星", ["shield"]),
        ("인성", "印星", ["input"]),
    ]

    static func getElementInteraction(_ e0: String, _ e1: String) -> String? {
        if e0 == e1 { return "same" }
        let generating: [String: String] = ["Wood": "Fire", "Fire": "Earth", "Earth": "Metal", "Metal": "Water", "Water": "Wood"]
        let controlled: [String: String] = ["Wood": "Earth", "Fire": "Metal", "Earth": "Water", "Metal": "Wood", "Water": "Fire"]
        if generating[e0] == e1 { return "output" }
        if generating[e1] == e0 { return "input" }
        if controlled[e0] == e1 { return "sword" }
        if controlled[e1] == e0 { return "shield" }
        return nil
    }

    public static func calculateInjongbeop(dayStemHanja: String, dayBranchHanja: String) -> [InjongEntry] {
        guard let dayInfo = STEM_ELEMENT_MAP[dayStemHanja] else { return [] }

        let hiddenStems = getHiddenStems(branchHanja: dayBranchHanja)
        var presentInteractions = Set<String>()
        for hs in hiddenStems {
            guard let info = STEM_ELEMENT_MAP[hs.stem] else { continue }
            if let interaction = getElementInteraction(dayInfo.element, info.element) {
                presentInteractions.insert(interaction)
            }
        }

        var results: [InjongEntry] = []
        for cat in SIPSIN_CATEGORIES {
            let missing = cat.interactions.allSatisfy { !presentInteractions.contains($0) }
            if !missing { continue }

            var targetElement: String? = nil
            for entry in STEM_ELEMENT_ORDER {
                if entry.yinYang != "Yang" { continue }
                if let inter = getElementInteraction(dayInfo.element, entry.element), cat.interactions.contains(inter) {
                    targetElement = entry.element
                    break
                }
            }
            guard let targetEl = targetElement else { continue }

            guard let yangStem = YANG_STEM_OF[targetEl] else { continue }
            let unseong = getTwelveStage(dayMasterHanja: yangStem, branchHanja: dayBranchHanja)
            results.append(InjongEntry(
                category: cat.name,
                categoryHanja: cat.hanja,
                yangStem: yangStem,
                yangStemKorean: STEM_KR[yangStem] ?? yangStem,
                unseong: unseong
            ))
        }

        return results
    }

    // ========== 신강/신약 — 라이브러리 기반 ==========

    public static func buildStrengthFromLibrary(raw: SajuRawData, pillars: SajuPillars) -> StrengthAnalysis {
        guard let dms = raw.dayMasterStrength else {
            return StrengthAnalysis(
                score: 50, isStrong: false, label: "신약(身弱)",
                details: StrengthDetails(
                    deukryeong: StrengthDetail(score: 0, description: "분석 데이터 없음"),
                    deukji: StrengthDetail(score: 0, description: ""),
                    deukse: StrengthDetail(score: 0, description: "")
                )
            )
        }

        let isStrong = dms.level == "very_strong" || dms.level == "strong" || (dms.level == "medium" && dms.score > 50)
        let wolRyeong = raw.wolRyeong

        let label: String
        if dms.level == "medium" { label = "중화(中和)" }
        else if isStrong { label = "신강(身強)" }
        else { label = "신약(身弱)" }

        return StrengthAnalysis(
            score: dms.score,
            isStrong: isStrong,
            label: label,
            details: StrengthDetails(
                deukryeong: StrengthDetail(
                    score: (wolRyeong?.isDeukRyeong ?? false) ? 1.5 : -1.0,
                    description: wolRyeong?.reason ?? "월지 \(BRANCH_KOREAN[pillars.month.branch.hanja] ?? "") 기준"
                ),
                deukji: StrengthDetail(score: 0, description: dms.analysis),
                deukse: StrengthDetail(score: 0, description: "")
            )
        )
    }

    // ========== 세운(歲運) ==========

    static let HEAVENLY_STEMS_DATA: [(hanja: String, korean: String, element: String, yin_yang: String)] = [
        ("甲", "갑", "Wood", "Yang"),
        ("乙", "을", "Wood", "Yin"),
        ("丙", "병", "Fire", "Yang"),
        ("丁", "정", "Fire", "Yin"),
        ("戊", "무", "Earth", "Yang"),
        ("己", "기", "Earth", "Yin"),
        ("庚", "경", "Metal", "Yang"),
        ("辛", "신", "Metal", "Yin"),
        ("壬", "임", "Water", "Yang"),
        ("癸", "계", "Water", "Yin"),
    ]

    static let EARTHLY_BRANCHES_DATA: [(hanja: String, korean: String, animal: String, element: String, yin_yang: String)] = [
        ("子", "자", "쥐", "Water", "Yang"),
        ("丑", "축", "소", "Earth", "Yin"),
        ("寅", "인", "호랑이", "Wood", "Yang"),
        ("卯", "묘", "토끼", "Wood", "Yin"),
        ("辰", "진", "용", "Earth", "Yang"),
        ("巳", "사", "뱀", "Fire", "Yin"),
        ("午", "오", "말", "Fire", "Yang"),
        ("未", "미", "양", "Earth", "Yin"),
        ("申", "신", "원숭이", "Metal", "Yang"),
        ("酉", "유", "닭", "Metal", "Yin"),
        ("戌", "술", "개", "Earth", "Yang"),
        ("亥", "해", "돼지", "Water", "Yin"),
    ]

    public static func calculateYearFortune(targetYear: Int, dayMasterElement: String, dayMasterYinYang: String, dayMasterHanja: String) -> YearFortune {
        let stemIndex = ((targetYear - 4) % 10 + 10) % 10
        let branchIndex = ((targetYear - 4) % 12 + 12) % 12
        let stem = HEAVENLY_STEMS_DATA[stemIndex]
        let branch = EARTHLY_BRANCHES_DATA[branchIndex]

        let branchPrimary = BRANCH_HANJA_TO_PRIMARY_STEM[branch.hanja]
        return YearFortune(
            year: targetYear,
            stemHanja: stem.hanja,
            stemKorean: stem.korean,
            stemElement: stem.element,
            branchHanja: branch.hanja,
            branchKorean: branch.korean,
            branchElement: branch.element,
            branchAnimal: branch.animal,
            tenGodStem: getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: stem.element, targetYinYang: stem.yin_yang),
            tenGodBranch: branchPrimary.map { getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: $0.element, targetYinYang: $0.yin_yang) } ?? "",
            twelveStage: getTwelveStage(dayMasterHanja: dayMasterHanja, branchHanja: branch.hanja)
        )
    }

    // ========== 용신 — 라이브러리 기반 ==========

    static let ELEMENT_KO_MAP: [String: String] = ["Wood": "목(木)", "Fire": "화(火)", "Earth": "토(土)", "Metal": "금(金)", "Water": "수(水)"]
    static let CONTROLLING: [String: String] = ["Wood": "Earth", "Fire": "Metal", "Earth": "Water", "Metal": "Wood", "Water": "Fire"]
    static let GENERATING: [String: String] = ["Wood": "Water", "Fire": "Wood", "Earth": "Fire", "Metal": "Earth", "Water": "Metal"]
    static let GENERATED_BY: [String: String] = ["Water": "Wood", "Wood": "Fire", "Fire": "Earth", "Earth": "Metal", "Metal": "Water"]
    static let CONTROLLED_BY: [String: String] = ["Wood": "Metal", "Fire": "Water", "Earth": "Wood", "Metal": "Fire", "Water": "Earth"]

    // hoshin yong_sin.ts:232-244 — 사주 wuxingCount에서 가장 적은 오행 반환 (영문)
    // TS Object.entries 순회 = hoshin 생성 삽입 순서(목→화→토→금→수) 재현
    static func findWeakestElementEn(_ raw: SajuRawData) -> String {
        let counts = raw.wuxingCount
        var weakest = "Wood"
        var minCount = Int.max
        let krToEn: [String: String] = ["목": "Wood", "화": "Fire", "토": "Earth", "금": "Metal", "수": "Water"]
        for kr in ["목", "화", "토", "금", "수"] {
            guard let count = counts[kr] else { continue }
            if count < minCount {
                minCount = count
                weakest = krToEn[kr] ?? kr
            }
        }
        return weakest
    }

    // hoshin은 용신 오행만 반환하고 음양을 지정하지 않음.
    // 따라서 십신은 "식신/상관" 처럼 같은 오행의 양 변종을 모두 표기.
    static func tenGodPairLabel(_ dayMasterElement: String, _ dayMasterYinYang: String, _ targetElement: String) -> String {
        if targetElement == dayMasterElement { return "비견/겁재" }
        let same = getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: targetElement, targetYinYang: dayMasterYinYang)
        let diff = getTenGod(dayMasterElement: dayMasterElement, dayMasterYinYang: dayMasterYinYang, targetElement: targetElement, targetYinYang: dayMasterYinYang == "Yang" ? "Yin" : "Yang")
        if same == diff { return same }
        return "\(same)/\(diff)"
    }

    public static func buildYongsinFromLibrary(raw: SajuRawData?, dayMasterElement: String, dayMasterYinYang: String, isStrong: Bool, strengthLevel: String? = nil) -> YongsinAnalysis {
        let ys = raw?.yongSin

        if let ys = ys {
            let primaryEn = ELEMENT_KR_TO_EN[ys.primaryYongSin] ?? ys.primaryYongSin
            let secondaryEn = ys.secondaryYongSin.map { ELEMENT_KR_TO_EN[$0] ?? $0 } ?? ""

            // 기신 2개 — hoshin yong_sin.ts:112,127 기준
            // 신강: 비겁(동일오행) + 인성(나를 생하는 오행) → 일간을 더 강하게 하여 균형 파괴
            // 신약: 재성(내가 극하는 오행) + 관살(나를 극하는 오행) → 약한 일간을 더 소모시킴
            // 중화: 용신을 극하는 오행 (hoshin yong_sin.ts:141)
            let gisin1El: String
            let gisin2El: String?
            let gisinDesc: String

            if strengthLevel == "medium" {
                gisin1El = CONTROLLED_BY[primaryEn] ?? ""  // 용신을 극하는 오행
                gisin2El = nil
                gisinDesc = "용신 오행을 극하여 균형을 깨뜨림"
            } else if isStrong {
                gisin1El = dayMasterElement                     // 비겁
                gisin2El = GENERATING[dayMasterElement]         // 인성
                gisinDesc = "일간을 더 강하게 하여 균형을 깨뜨림"
            } else {
                gisin1El = CONTROLLING[dayMasterElement] ?? ""  // 재성
                gisin2El = CONTROLLED_BY[dayMasterElement]      // 관살
                gisinDesc = "약한 일간을 더 소모시킴"
            }

            let gisinSecondary: YongsinElement? = gisin2El.map { el in
                YongsinElement(
                    element: el,
                    elementKo: ELEMENT_KO_MAP[el] ?? "",
                    tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, el),
                    description: gisinDesc
                )
            }

            return YongsinAnalysis(
                yongsin: YongsinElement(
                    element: primaryEn,
                    elementKo: ELEMENT_KO_MAP[primaryEn] ?? ys.primaryYongSin,
                    tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, primaryEn),
                    description: ys.reasoning
                ),
                heesin: YongsinElement(
                    element: secondaryEn.isEmpty ? dayMasterElement : secondaryEn,
                    elementKo: (secondaryEn.isEmpty ? nil : ELEMENT_KO_MAP[secondaryEn]) ?? ELEMENT_KO_MAP[dayMasterElement] ?? "",
                    tenGod: secondaryEn.isEmpty ? "비견/겁재" : tenGodPairLabel(dayMasterElement, dayMasterYinYang, secondaryEn),
                    description: secondaryEn.isEmpty ? "같은 기운으로 힘을 보탬" : "용신을 돕는 오행"
                ),
                gisin: YongsinElement(
                    element: gisin1El,
                    elementKo: ELEMENT_KO_MAP[gisin1El] ?? "",
                    tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, gisin1El),
                    description: gisinDesc
                ),
                gisinSecondary: gisinSecondary
            )
        }

        // fallback — hoshin yong_sin.ts 로직 직접 구현
        // 중화: 가장 약한 오행을 용신으로, 용신을 극하는 오행이 기신 — hoshin:136-143
        // 신강: 1순위 식상(GENERATED_BY), 2순위 재성(CONTROLLING) — hoshin:108-109
        // 신약: 1순위 인성(GENERATING), 2순위 비겁(동일오행) — hoshin:123-124
        if strengthLevel == "medium" {
            // 중화 fallback: raw가 없으면 wuxingCount를 알 수 없음 → 일간을 생하는 오행을 기본 용신으로 사용
            let yongsinEl = raw.map { findWeakestElementEn($0) } ?? (GENERATING[dayMasterElement] ?? "")
            let gisinEl = CONTROLLED_BY[yongsinEl] ?? ""
            let heesinEl = GENERATED_BY[yongsinEl] ?? ""
            return YongsinAnalysis(
                yongsin: YongsinElement(element: yongsinEl, elementKo: ELEMENT_KO_MAP[yongsinEl] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, yongsinEl), description: "중화된 사주에서 가장 약한 오행을 보강"),
                heesin: YongsinElement(element: heesinEl, elementKo: ELEMENT_KO_MAP[heesinEl] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, heesinEl), description: "용신을 돕는 오행"),
                gisin: YongsinElement(element: gisinEl, elementKo: ELEMENT_KO_MAP[gisinEl] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, gisinEl), description: "용신 오행을 극하여 균형을 깨뜨림")
            )
        } else if isStrong {
            let yongsinEl = GENERATED_BY[dayMasterElement] ?? ""  // 식상 = 설기 (hoshin 1순위)
            let heesinEl = CONTROLLING[dayMasterElement] ?? ""    // 재성 (hoshin 2순위)
            let gisin1El = dayMasterElement                       // 비겁 (hoshin:112)
            let gisin2El = GENERATING[dayMasterElement] ?? ""     // 인성 (hoshin:112)
            return YongsinAnalysis(
                yongsin: YongsinElement(element: yongsinEl, elementKo: ELEMENT_KO_MAP[yongsinEl] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, yongsinEl), description: "신강하여 일간의 기운을 설기(泄氣)하는 오행이 용신"),
                heesin: YongsinElement(element: heesinEl, elementKo: ELEMENT_KO_MAP[heesinEl] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, heesinEl), description: "용신을 돕는 오행"),
                gisin: YongsinElement(element: gisin1El, elementKo: ELEMENT_KO_MAP[gisin1El] ?? "", tenGod: "비견/겁재", description: "일간을 더 강하게 하여 균형을 깨뜨림"),
                gisinSecondary: YongsinElement(element: gisin2El, elementKo: ELEMENT_KO_MAP[gisin2El] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, gisin2El), description: "일간을 더 강하게 하여 균형을 깨뜨림")
            )
        } else {
            let yongsinEl = GENERATING[dayMasterElement] ?? ""    // 인성 (hoshin:123)
            let heesinEl = dayMasterElement                       // 비겁 (hoshin:124)
            let gisin1El = CONTROLLING[dayMasterElement] ?? ""    // 재성 (hoshin:127)
            let gisin2El = CONTROLLED_BY[dayMasterElement] ?? ""  // 관살 (hoshin:127)
            return YongsinAnalysis(
                yongsin: YongsinElement(element: yongsinEl, elementKo: ELEMENT_KO_MAP[yongsinEl] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, yongsinEl), description: "신약하여 일간을 생(生)해주는 오행이 용신"),
                heesin: YongsinElement(element: heesinEl, elementKo: ELEMENT_KO_MAP[heesinEl] ?? "", tenGod: "비견/겁재", description: "같은 기운으로 힘을 보탬"),
                gisin: YongsinElement(element: gisin1El, elementKo: ELEMENT_KO_MAP[gisin1El] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, gisin1El), description: "약한 일간을 더 소모시킴"),
                gisinSecondary: YongsinElement(element: gisin2El, elementKo: ELEMENT_KO_MAP[gisin2El] ?? "", tenGod: tenGodPairLabel(dayMasterElement, dayMasterYinYang, gisin2El), description: "약한 일간을 더 소모시킴")
            )
        }
    }
}
