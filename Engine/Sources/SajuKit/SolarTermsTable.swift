// 정밀 절기 테이블 (1900~2200) — fortuneteller src/data/solar_terms.ts 포팅
// solar-terms.json: { termOrder: [24절기명, 입춘=0], entries: [[year, termIndex, timestampMs], ...] }
// timestamp는 UTC ms (원본 datetime 기준 보정 완료값 — TS correctTimestamp 결과와 동일)

import Foundation

/// 절기 1건 (TS SolarTermComplete 등가 — 대운 기산에 필요한 필드만)
public struct SolarTermEntry: Sendable {
    public let year: Int
    public let name: String          // 절기명 (입춘~대한)
    public let timestampMs: Double   // UTC ms
}

public enum SolarTermsTable {
    public static let minYear = 1900
    public static let maxYear = 2200

    /// 24절기 중 **절(節)** — TS 원본 SOLAR_TERMS_JIE 그대로 (소설 포함·소한 제외).
    /// 정통 12절과 다르지만 골든 픽스처(=웹 서비스 동작) 일치가 기준이므로 원본을 따른다.
    public static let jieTerms: [String] = [
        "입춘", "경칩", "청명", "입하", "망종", "소서",
        "입추", "백로", "한로", "입동", "소설", "대설",
    ]
    private static let jieSet = Set(jieTerms)

    /// 연도별 절기 엔트리 (테이블 수록 순서 유지)
    private static let byYear: [Int: [SolarTermEntry]] = load()

    /// 출생 시각 **이전(포함)**의 가장 최근 절(節) — getPreviousJieSolarTermByInstant (대운 역행 기산)
    public static func previousJieTerm(atOrBefore instant: Date) -> SolarTermEntry? {
        let ms = instant.timeIntervalSince1970 * 1000
        var best: SolarTermEntry?
        for entry in jieCandidates(around: instant) where entry.timestampMs <= ms {
            if best == nil || entry.timestampMs > best!.timestampMs { best = entry }
        }
        return best
    }

    /// 출생 시각 **이후**의 가장 이른 절(節) — getNextJieSolarTermByInstant (대운 순행 기산)
    public static func nextJieTerm(after instant: Date) -> SolarTermEntry? {
        let ms = instant.timeIntervalSince1970 * 1000
        var best: SolarTermEntry?
        for entry in jieCandidates(around: instant) where entry.timestampMs > ms {
            if best == nil || entry.timestampMs < best!.timestampMs { best = entry }
        }
        return best
    }

    /// TS와 동일한 탐색 창: Seoul 달력 연도 ±1 (1900~2200 클램프) 범위의 절(節) 후보
    private static func jieCandidates(around instant: Date) -> [SolarTermEntry] {
        let seoulYear = SajuCore.seoulCalendar.component(.year, from: instant)
        let minY = max(minYear, seoulYear - 1)
        let maxY = min(maxYear, seoulYear + 1)
        guard minY <= maxY else { return [] }
        var result: [SolarTermEntry] = []
        for y in minY...maxY {
            result.append(contentsOf: (byYear[y] ?? []).filter { jieSet.contains($0.name) })
        }
        return result
    }

    private static func load() -> [Int: [SolarTermEntry]] {
        guard let url = Bundle.module.url(forResource: "solar-terms", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode(RawTable.self, from: data)
        else {
            fatalError("SajuKit: solar-terms.json 리소스를 로드할 수 없습니다")
        }
        var byYear: [Int: [SolarTermEntry]] = [:]
        for entry in raw.entries where entry.count >= 3 {
            let year = Int(entry[0])
            let termIndex = Int(entry[1])
            guard termIndex >= 0, termIndex < raw.termOrder.count else { continue }
            byYear[year, default: []].append(
                SolarTermEntry(year: year, name: raw.termOrder[termIndex], timestampMs: entry[2])
            )
        }
        return byYear
    }

    private struct RawTable: Decodable {
        let termOrder: [String]
        let entries: [[Double]]
    }
}
