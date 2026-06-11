// 골든 픽스처 검증 — saju-analysis.json 106건
// 십성/12운성/지장간/합충형파해/공망/12신살/특수살/좌법/인종법/신강신약/용신/세운/대운 + hoshin 원본값
//
// 비교 방식: 계산 결과를 JSON으로 직렬화해 픽스처 JSON과 재귀 비교 (키·값·배열 순서 일치, 수치는 ε 허용)

import XCTest
@testable import SajuKit

final class SajuAnalysisGoldenTests: XCTestCase {

    // MARK: - 범용 JSON 비교

    static func jsonObject<T: Encodable>(_ value: T) throws -> Any {
        let data = try JSONEncoder().encode(value)
        return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
    }

    /// 재귀 비교 — 불일치 경로 반환 (nil이면 일치)
    static func diff(_ a: Any?, _ b: Any?, path: String = "") -> String? {
        switch (a, b) {
        case (nil, nil), (is NSNull, nil), (nil, is NSNull), (is NSNull, is NSNull):
            return nil
        case let (x as NSNumber, y as NSNumber):
            // Bool도 NSNumber — 타입 구분
            let xIsBool = CFGetTypeID(x) == CFBooleanGetTypeID()
            let yIsBool = CFGetTypeID(y) == CFBooleanGetTypeID()
            if xIsBool != yIsBool { return "\(path): bool/number 타입 불일치" }
            if xIsBool { return x.boolValue == y.boolValue ? nil : "\(path): \(x) vs \(y)" }
            return abs(x.doubleValue - y.doubleValue) < 1e-9 ? nil : "\(path): \(x) vs \(y)"
        case let (x as String, y as String):
            return x == y ? nil : "\(path): \"\(x)\" vs \"\(y)\""
        case let (x as [Any], y as [Any]):
            if x.count != y.count { return "\(path): 배열 길이 \(x.count) vs \(y.count)" }
            for (i, (xi, yi)) in zip(x, y).enumerated() {
                if let d = diff(xi, yi, path: "\(path)[\(i)]") { return d }
            }
            return nil
        case let (x as [String: Any], y as [String: Any]):
            // null 값은 키 부재와 동치로 취급 (JS undefined 생략 호환)
            let xKeys = Set(x.filter { !($0.value is NSNull) }.keys)
            let yKeys = Set(y.filter { !($0.value is NSNull) }.keys)
            if xKeys != yKeys {
                return "\(path): 키 차이 — 한쪽에만: \(xKeys.symmetricDifference(yKeys).sorted())"
            }
            for key in xKeys {
                if let d = diff(x[key], y[key], path: "\(path).\(key)") { return d }
            }
            return nil
        default:
            return "\(path): 타입 불일치 \(type(of: a as Any)) vs \(type(of: b as Any))"
        }
    }

    // MARK: - 픽스처

    struct RawFixture {
        let referenceYear: Int
        let cases: [[String: Any]]
    }

    static let fixture: RawFixture = {
        guard let url = Bundle.module.url(forResource: "saju-analysis", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cases = obj["cases"] as? [[String: Any]],
              let refYear = obj["referenceYear"] as? Int
        else { fatalError("saju-analysis.json 로드 실패") }
        return RawFixture(referenceYear: refYear, cases: cases)
    }()

    // MARK: - 보조: hoshin 섹션 [String: Any] 구성

    static func jiJangGanDict(_ j: JiJangGanStrength) -> [String: Any] {
        var d: [String: Any] = ["primary": ["stem": j.primary.stem, "strength": j.primary.strength]]
        if let s = j.secondary { d["secondary"] = ["stem": s.stem, "strength": s.strength] }
        if let r = j.residual { d["residual"] = ["stem": r.stem, "strength": r.strength] }
        return d
    }

    static func hoshinDict(_ raw: SajuRawData) -> [String: Any] {
        var d: [String: Any] = [
            "sinSals": raw.sinSals,
            "wuxingCount": raw.wuxingCount,
        ]
        if let g = raw.gyeokGuk {
            d["gyeokGuk"] = ["gyeokGuk": g.gyeokGuk, "name": g.name, "hanja": g.hanja, "description": g.description]
        }
        if let y = raw.yongSin {
            var yd: [String: Any] = ["primaryYongSin": y.primaryYongSin, "reasoning": y.reasoning]
            if let s = y.secondaryYongSin { yd["secondaryYongSin"] = s }
            d["yongSin"] = yd
        }
        if let s = raw.dayMasterStrength {
            d["dayMasterStrength"] = ["level": s.level, "score": s.score, "analysis": s.analysis]
        }
        if !raw.jiJangGan.isEmpty {
            var jd: [String: Any] = [:]
            for (k, v) in raw.jiJangGan { jd[k] = jiJangGanDict(v) }
            d["jiJangGan"] = jd
        }
        return d
    }

    // MARK: - 테스트

    func test심층분석_골든픽스처_전건일치() throws {
        var failures: [String] = []

        for c in Self.fixture.cases {
            guard let input = c["input"] as? [String: Any],
                  let expected = c["output"] as? [String: Any] else { continue }

            let y = input["y"] as! Int, m = input["m"] as! Int, d = input["d"] as! Int
            let h = input["h"] as? Int
            let min = input["min"] as! Int
            let gender = input["gender"] as! String
            let desc = "\(y)-\(m)-\(d) \(h ?? -1):\(min) \(gender) [\(input["tag"] ?? "")]"

            let r: FortuneTellerResult
            do {
                r = try SajuCalculator.calculate(
                    year: y, month: m, day: d, hour: h, gender: gender,
                    calendar: input["calendar"] as! String,
                    isLeapMonth: input["leap"] as! Bool,
                    useTrueSolarTime: input["trueSolar"] as! Bool,
                    region: input["region"] as! String,
                    minute: min
                )
            } catch {
                failures.append("\(desc): 계산 에러 \(error)")
                continue
            }

            let raw = r.raw
            let dm = r.dayMaster
            let pillars = SajuPillars(year: r.pillars.year, month: r.pillars.month, day: r.pillars.day, hour: r.pillars.hour)
            let dayBranchHanja = r.pillars.day.branch.hanja
            let stems = [r.pillars.hour?.stem.hanja ?? "", r.pillars.day.stem.hanja, r.pillars.month.stem.hanja, r.pillars.year.stem.hanja]
            let branchArr = [r.pillars.hour?.branch.hanja ?? "", r.pillars.day.branch.hanja, r.pillars.month.branch.hanja, r.pillars.year.branch.hanja]

            let strength = EngineAnalysis.buildStrengthFromLibrary(raw: raw, pillars: pillars)

            // 픽스처 생성기와 동일한 출력 구성
            var computed: [String: Any] = [:]
            do {
                computed["pillars"] = [
                    "year": "\(r.pillars.year.stem.hanja)\(r.pillars.year.branch.hanja)",
                    "month": "\(r.pillars.month.stem.hanja)\(r.pillars.month.branch.hanja)",
                    "day": "\(r.pillars.day.stem.hanja)\(r.pillars.day.branch.hanja)",
                    "hour": r.pillars.hour.map { "\($0.stem.hanja)\($0.branch.hanja)" } as Any,
                ]
                computed["tenGods"] = try Self.jsonObject(EngineAnalysis.calculateTenGods(dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang, pillars: pillars))
                computed["twelveStages"] = try Self.jsonObject(EngineAnalysis.calculateTwelveStages(dayMasterHanja: dm.hanja, pillars: pillars))
                computed["hiddenStems"] = try Self.jsonObject(EngineAnalysis.calculateHiddenStems(pillars: pillars, dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang))
                computed["branchRelations"] = try Self.jsonObject(EngineAnalysis.calculateBranchRelations(pillars: pillars))
                computed["multiRelations"] = try Self.jsonObject(EngineAnalysis.calculateMultiRelations(pillars: pillars))
                computed["stemRelations"] = try Self.jsonObject(EngineAnalysis.calculateStemRelations(pillars: pillars))
                computed["gongMang"] = try Self.jsonObject(EngineAnalysis.calculateGongMang(dayStemHanja: dm.hanja, dayBranchHanja: dayBranchHanja, pillars: pillars))
                computed["twelveSpirits"] = try Self.jsonObject(EngineAnalysis.calculateTwelveSpirits(yearBranchHanja: r.pillars.year.branch.hanja, pillars: pillars))
                computed["specialSals"] = try Self.jsonObject(EngineAnalysis.calculateSpecialSals(stems: stems, branches: branchArr, dayPillar: "\(r.pillars.day.stem.hanja)\(dayBranchHanja)"))
                computed["jwabeop"] = try Self.jsonObject(EngineAnalysis.calculateJwabeop(dayStemHanja: dm.hanja, dayBranchHanja: dayBranchHanja, pillars: pillars))
                computed["injongbeop"] = try Self.jsonObject(EngineAnalysis.calculateInjongbeop(dayStemHanja: dm.hanja, dayBranchHanja: dayBranchHanja))
                computed["strength"] = try Self.jsonObject(strength)
                computed["yongsin"] = try Self.jsonObject(EngineAnalysis.buildYongsinFromLibrary(raw: raw, dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang, isStrong: strength.isStrong, strengthLevel: raw.dayMasterStrength?.level))
                computed["yearFortune"] = try Self.jsonObject(EngineAnalysis.calculateYearFortune(targetYear: Self.fixture.referenceYear, dayMasterElement: dm.element, dayMasterYinYang: dm.yin_yang, dayMasterHanja: dm.hanja))
                computed["daeun"] = try Self.jsonObject(HoshinDaeUn.calculateDaeUn(raw))
                computed["hoshin"] = Self.hoshinDict(raw)
            } catch {
                failures.append("\(desc): 직렬화 에러 \(error)")
                continue
            }

            // 섹션별 비교 (불일치 섹션을 특정하기 위함)
            for key in expected.keys.sorted() {
                if let d = Self.diff(computed[key], expected[key], path: key) {
                    failures.append("\(desc): \(d)")
                    break
                }
            }
        }

        XCTAssertEqual(failures.count, 0, "불일치 \(failures.count)건 — 처음 10건:\n" + failures.prefix(10).joined(separator: "\n"))
    }
}
