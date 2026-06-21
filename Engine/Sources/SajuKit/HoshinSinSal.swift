// HoshinSinSal — fortuneteller src/lib/sin_sal.ts 포팅
// 신살(神殺) 체계: 사주에 나타나는 특수한 길흉신
// 반환 값은 TS SinSalType 문자열 코드 그대로 ("cheon_eul_gwi_in" 등), TS 반환 순서 유지

import Foundation

public enum HoshinSinSal {
    // MARK: - 천을귀인 판단표 (일간 기준, ts: CHEON_EUL_GWI_IN_TABLE)

    static let cheonEulGwiInTable: [String: [String]] = [
        "갑": ["축", "미"],
        "을": ["자", "신"],
        "병": ["해", "유"],
        "정": ["해", "유"],
        "무": ["축", "미"],
        "기": ["자", "신"],
        "경": ["축", "미"],
        "신": ["인", "오"],
        "임": ["사", "묘"],
        "계": ["사", "묘"],
    ]

    // MARK: - 도화살 판단 (지지 조합, ts: checkDoHwaSal)

    static func checkDoHwaSal(_ branches: [String]) -> Bool {
        let branchSet = Set(branches)

        // 인오술 → 묘
        if (branchSet.contains("인") || branchSet.contains("오") || branchSet.contains("술"))
            && branchSet.contains("묘") {
            return true
        }

        // 사유축 → 오
        if (branchSet.contains("사") || branchSet.contains("유") || branchSet.contains("축"))
            && branchSet.contains("오") {
            return true
        }

        // 신자진 → 유
        if (branchSet.contains("신") || branchSet.contains("자") || branchSet.contains("진"))
            && branchSet.contains("유") {
            return true
        }

        // 해묘미 → 자
        if (branchSet.contains("해") || branchSet.contains("묘") || branchSet.contains("미"))
            && branchSet.contains("자") {
            return true
        }

        return false
    }

    // MARK: - 역마살 판단 (지지 조합, ts: checkYeokMaSal)

    static func checkYeokMaSal(_ branches: [String]) -> Bool {
        let branchSet = Set(branches)

        // 인오술일주 → 신
        if (branchSet.contains("인") || branchSet.contains("오") || branchSet.contains("술"))
            && branchSet.contains("신") {
            return true
        }

        // 사유축일주 → 해
        if (branchSet.contains("사") || branchSet.contains("유") || branchSet.contains("축"))
            && branchSet.contains("해") {
            return true
        }

        // 신자진일주 → 인
        if (branchSet.contains("신") || branchSet.contains("자") || branchSet.contains("진"))
            && branchSet.contains("인") {
            return true
        }

        // 해묘미일주 → 사
        if (branchSet.contains("해") || branchSet.contains("묘") || branchSet.contains("미"))
            && branchSet.contains("사") {
            return true
        }

        return false
    }

    // MARK: - 공망 판단 (일주 기준 60갑자 순환, ts: checkGongMang)

    static func checkGongMang(dayBranch: String, branches: [String]) -> Bool {
        let gongMangTable: [String: [String]] = [
            "자": ["술", "해"],
            "축": ["술", "해"],
            "인": ["자", "축"],
            "묘": ["자", "축"],
            "진": ["인", "묘"],
            "사": ["인", "묘"],
            "오": ["진", "사"],
            "미": ["진", "사"],
            "신": ["오", "미"],
            "유": ["오", "미"],
            "술": ["신", "유"],
            "해": ["신", "유"],
        ]

        guard let gongMangBranches = gongMangTable[dayBranch] else { return false }
        return branches.contains { gongMangBranches.contains($0) }
    }

    // MARK: - 화개살 판단 (지지 조합, ts: checkHwaGaeSal)

    static func checkHwaGaeSal(_ branches: [String]) -> Bool {
        let branchSet = Set(branches)

        // 인오술 → 술
        if (branchSet.contains("인") || branchSet.contains("오") || branchSet.contains("술"))
            && branchSet.contains("술") {
            return true
        }

        // 사유축 → 축
        if (branchSet.contains("사") || branchSet.contains("유") || branchSet.contains("축"))
            && branchSet.contains("축") {
            return true
        }

        // 신자진 → 진
        if (branchSet.contains("신") || branchSet.contains("자") || branchSet.contains("진"))
            && branchSet.contains("진") {
            return true
        }

        // 해묘미 → 미
        if (branchSet.contains("해") || branchSet.contains("묘") || branchSet.contains("미"))
            && branchSet.contains("미") {
            return true
        }

        return false
    }

    // MARK: - 원진살 체크 - 자오충, 묘유충 등 충돌 관계 (ts: checkWonJinSal)

    static func checkWonJinSal(_ branches: [String]) -> Bool {
        let branchSet = Set(branches)

        let chungPairs: [(String, String)] = [
            ("자", "오"),
            ("축", "미"),
            ("인", "신"),
            ("묘", "유"),
            ("진", "술"),
            ("사", "해"),
        ]

        for (b1, b2) in chungPairs {
            if branchSet.contains(b1) && branchSet.contains(b2) {
                return true
            }
        }

        return false
    }

    // MARK: - 귀문관살 체크 - 인, 신, 사, 해가 있을 때 (ts: checkGwiMunGwanSal)

    static func checkGwiMunGwanSal(_ branches: [String]) -> Bool {
        let branchSet = Set(branches)
        let gwiMunBranches = ["인", "신", "사", "해"]

        // 귀문관살 관련 지지가 2개 이상 있으면
        var count = 0
        for branch in gwiMunBranches {
            if branchSet.contains(branch) { count += 1 }
        }

        return count >= 2
    }

    // MARK: - 전치(일진) 신살 — 그날 지지가 natal 일간/일지와 이루는 신살 (한글 표시명, 길흉 큰 순)

    /// 일진 신살: 천을귀인(일간 기준)·역마·도화·화개(일지 삼합 기준)·공망(일지 旬 기준)
    public static func transitSinSals(transitBranch: String, natalDayStem: String, natalDayBranch: String) -> [String] {
        let pair = [natalDayBranch, transitBranch]
        var result: [String] = []
        if let t = cheonEulGwiInTable[natalDayStem], t.contains(transitBranch) { result.append("천을귀인") }
        if checkYeokMaSal(pair) { result.append("역마") }
        if checkDoHwaSal(pair) { result.append("도화") }
        if checkHwaGaeSal(pair) { result.append("화개") }
        if checkGongMang(dayBranch: natalDayBranch, branches: [transitBranch]) { result.append("공망") }
        return result
    }

    // MARK: - findSinSals (ts: findSinSals)

    /// 사주에서 신살 찾기
    public static func findSinSals(_ raw: SajuRawData) -> [String] {
        var sinSals: [String] = []
        let dayStem = raw.day.stem
        let dayBranch = raw.day.branch

        // 4기둥의 지지 수집
        let branches = [raw.year.branch, raw.month.branch, raw.day.branch, raw.hour.branch]

        // 천을귀인 체크
        if let cheonEulBranches = cheonEulGwiInTable[dayStem],
           branches.contains(where: { cheonEulBranches.contains($0) }) {
            sinSals.append("cheon_eul_gwi_in")
        }

        // 도화살 체크
        if checkDoHwaSal(branches) {
            sinSals.append("do_hwa_sal")
        }

        // 역마살 체크
        if checkYeokMaSal(branches) {
            sinSals.append("yeok_ma_sal")
        }

        // 공망 체크
        if checkGongMang(dayBranch: dayBranch, branches: branches) {
            sinSals.append("gong_mang")
        }

        // 화개살 체크
        if checkHwaGaeSal(branches) {
            sinSals.append("hwa_gae_sal")
        }

        // 원진살 체크 (간단한 판단)
        if checkWonJinSal(branches) {
            sinSals.append("won_jin_sal")
        }

        // 귀문관살 체크 (간단한 판단)
        if checkGwiMunGwanSal(branches) {
            sinSals.append("gwi_mun_gwan_sal")
        }

        // 간단한 휴리스틱으로 다른 신살들도 추가 (실제 판단 로직은 더 복잡함)
        // 여기서는 일부만 구현

        return sinSals
    }
}
