// 대운(大運) 계산 — fortuneteller src/lib/dae_un.ts calculateDaeUn 포팅
//
// 규칙 (dae_un.ts와 동일):
// - 방향: 양년생 남자/음년생 여자 → 순행, 그 외 → 역행 (연간 천간 음양 × 성별)
// - 기산: 보정 출생 시각 → (순행) 다음 절(節) / (역행) 이전 절(節, 출생 시각 포함)까지
//   경과 일수(소수 포함, ms 정밀) ÷ 3 = 시작 나이 (내림, 0~10 클램프)
// - 절기 데이터 없으면 기본값 5세
// - 간지: 월주에서 i+1 칸 순방향/역방향 진행
//
// 시각 입력: TS는 getAdjustedBirthInstantForSaju(벽시계 Asia/Seoul + 경도 보정)를 재구성하며,
// SajuRawData.adjustedInstant가 동일 값(SajuCore.adjustedBirthInstant)이므로 그대로 사용.

import Foundation

/// ft-lib.ts DaeUnPeriod 등가
public struct DaeUnPeriod: Codable, Equatable, Sendable {
    public let startAge: Int
    public let endAge: Int
    public let stem: String           // 갑~계
    public let branch: String         // 자~해
    public let stemElement: String    // 목~수
    public let branchElement: String
    public let pillarIndex: Int       // 몇 번째 대운인지 (0부터 시작)
}

public enum HoshinDaeUn {
    /// dae_un.ts calculateDaeUn — lifespan 기본 120세
    public static func calculateDaeUn(_ raw: SajuRawData, lifespan: Int = 120) -> [DaeUnPeriod] {
        let startAge = calculateStartAge(raw)
        let forward = isForward(raw)

        let monthStemIndex = SajuTables.stemIndex(korean: raw.month.stem)
        let monthBranchIndex = SajuTables.branches.firstIndex { $0.korean == raw.month.branch } ?? -1

        // 최대 12개 대운 (120세까지)
        let maxPeriods = Int(ceil(Double(lifespan - startAge) / 10.0))
        guard maxPeriods > 0 else { return [] }

        var periods: [DaeUnPeriod] = []
        periods.reserveCapacity(maxPeriods)

        for i in 0..<maxPeriods {
            let stemIdx: Int
            let branchIdx: Int
            if forward {
                // 순행: 월주에서 순방향
                stemIdx = monthStemIndex + i + 1
                branchIdx = monthBranchIndex + i + 1
            } else {
                // 역행: 월주에서 역방향
                stemIdx = monthStemIndex - i - 1
                branchIdx = monthBranchIndex - i - 1
            }

            // SajuTables.stem(at:)/branch(at:)은 TS getHeavenlyStemByIndex와 동일하게
            // ((i % n) + n) % n 정규화 — 음수 인덱스도 안전
            let stem = SajuTables.stem(at: stemIdx)
            let branch = SajuTables.branch(at: branchIdx)

            periods.append(DaeUnPeriod(
                startAge: startAge + i * 10,
                endAge: startAge + (i + 1) * 10 - 1,
                stem: stem.korean,
                branch: branch.korean,
                stemElement: stem.element,
                branchElement: branch.element,
                pillarIndex: i
            ))
        }

        return periods
    }

    /// 특정 나이의 대운 조회 (dae_un.ts getDaeUnAtAge)
    public static func daeUnAtAge(_ raw: SajuRawData, age: Int) -> DaeUnPeriod? {
        calculateDaeUn(raw).first { age >= $0.startAge && age <= $0.endAge }
    }

    // MARK: - 기산

    /// 대운 시작 나이 (dae_un.ts calculateDaeUnStartAge)
    /// 순행: 출생 → 다음 절(節)까지 / 역행: 이전 절(節) → 출생까지 경과 일수 ÷ 3 (내림, 0~10)
    private static func calculateStartAge(_ raw: SajuRawData) -> Int {
        let birthMs = raw.adjustedInstant.timeIntervalSince1970 * 1000

        if isForward(raw) {
            guard let term = SolarTermsTable.nextJieTerm(after: raw.adjustedInstant) else {
                return 5  // TS: 절기 데이터 없으면 기본값 5세
            }
            let totalDays = (term.timestampMs - birthMs) / (1000 * 60 * 60 * 24)
            return startAgeFromThreeDayRule(totalDays)
        } else {
            guard let term = SolarTermsTable.previousJieTerm(atOrBefore: raw.adjustedInstant) else {
                return 5
            }
            let totalDays = (birthMs - term.timestampMs) / (1000 * 60 * 60 * 24)
            return startAgeFromThreeDayRule(totalDays)
        }
    }

    /// 전통 3일 = 1년: 경과 일(소수 포함)을 3으로 나눈 몫(내림), 0~10세로 제한
    private static func startAgeFromThreeDayRule(_ totalDays: Double) -> Int {
        let years = Int(floor(totalDays / 3))
        return max(0, min(10, years))
    }

    // MARK: - 순행/역행

    /// 양남음녀 순행, 음남양녀 역행 (dae_un.ts isDaeUnForward — 연간 천간 음양 기준)
    private static func isForward(_ raw: SajuRawData) -> Bool {
        let yinYang = raw.year.yinYang   // FtPillar.yinYang = 천간 음양
        return (yinYang == "양" && raw.gender == "male")
            || (yinYang == "음" && raw.gender == "female")
    }
}
