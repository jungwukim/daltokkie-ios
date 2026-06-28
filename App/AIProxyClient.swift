// AI 프록시 클라이언트 — daltokkie.vercel.app 해석 API (유일한 서버 의존)
// Vercel AI SDK 스트리밍(text 프로토콜) 수신: URLSession.bytes 라인 단위 처리
//
// 스키마 규칙 (DESIGN.md 9-5): 계산 결과를 API 원본 타입 형태(JSON)로 전달

import Foundation
import SajuKit
import NatalKit
import ZiweiKit

enum AIProxy {
    static let baseURL = URL(string: "https://daltokkie.vercel.app")!

    /// Codable → JSON 객체 (엔진 타입을 API 원본 JSON 형태로 전달)
    static func jsonValue<T: Encodable>(_ value: T) -> Any {
        (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(value))) ?? NSNull()
    }

    /// 모든 AI 생성에 공통 주입할 컨텍스트 — 현재 날짜/나이/지역(없으면 서버가 과거 연도 환각·맥락 부족)
    static func commonContext(birthYear: Int? = nil, region: String? = nil) -> [String: Any] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let now = cal.dateComponents([.year, .month, .day], from: Date())
        var ctx: [String: Any] = [:]
        if let cy = now.year {
            ctx["currentYear"] = cy
            ctx["today"] = String(format: "%04d-%02d-%02d", cy, now.month ?? 1, now.day ?? 1)
            if let by = birthYear { ctx["age"] = cy - by; ctx["koreanAge"] = cy - by + 1 }
        }
        if let r = region, !r.isEmpty { ctx["region"] = r }
        return ctx
    }

    private static func merged(_ payload: [String: Any], _ ctx: [String: Any]) -> [String: Any] {
        var p = payload
        for (k, v) in ctx { p[k] = v }
        return p
    }

    /// 점성술 AI 해석 — POST /api/natal/interpret
    static func interpretNatal(chart: NatalChart, gender: String, birthYear: Int, region: String? = nil) -> AsyncThrowingStream<String, Error> {
        stream(path: "/api/natal/interpret", payload: merged(
            ["chart": jsonValue(chart), "gender": gender, "birthYear": birthYear],
            commonContext(birthYear: birthYear, region: region)))
    }

    /// 자미두수 AI 해석 — POST /api/ziwei/interpret
    static func interpretZiwei(chart: ZiweiChart, liunian: LiuNianInfo?, daxianList: [DaxianInfo], gender: String, birthYear: Int, region: String? = nil) -> AsyncThrowingStream<String, Error> {
        stream(path: "/api/ziwei/interpret", payload: merged([
            "chart": jsonValue(chart),
            "liunian": liunian.map { jsonValue($0) } ?? NSNull(),
            "daxianList": daxianList.map { jsonValue($0) },
            "gender": gender, "birthYear": birthYear,
        ], commonContext(birthYear: birthYear, region: region)))
    }

    /// 타로 AI 리딩 — POST /api/tarot/interpret
    static func interpretTarot(cards: [[String: Any]], spread: String, topic: String, question: String?,
                               gender: String? = nil, birthYear: Int? = nil, region: String? = nil) -> AsyncThrowingStream<String, Error> {
        var payload: [String: Any] = ["cards": cards, "spread": spread, "topic": topic]
        if let q = question, !q.trimmingCharacters(in: .whitespaces).isEmpty { payload["question"] = q }
        if let g = gender { payload["gender"] = g }
        if let by = birthYear { payload["birthYear"] = by }
        return stream(path: "/api/tarot/interpret", payload: merged(payload, commonContext(birthYear: birthYear, region: region)))
    }

    /// AI 콘텐츠 — POST /api/saju/content/{id} (48종, 엔진 자동 라우팅)
    static func content(
        id: String, tone: String,
        gender: String, birthYear: Int, birthMonth: Int, birthDay: Int, birthHour: Int?, birthMinute: Int,
        sajuResult: FortuneTellerResult? = nil, natalChart: NatalChart? = nil,
        region: String? = nil, timeline: [String: Any]? = nil, daily: [String: Any]? = nil,
        isLunar: Bool? = nil, isLeapMonth: Bool? = nil, useTrueSolarTime: Bool? = nil
    ) -> AsyncThrowingStream<String, Error> {
        var payload: [String: Any] = [
            "gender": gender, "birthYear": birthYear, "birthMonth": birthMonth, "birthDay": birthDay,
            "birthMinute": birthMinute, "tone": tone,
        ]
        if let h = birthHour { payload["birthHour"] = h }
        if let v = isLunar { payload["isLunar"] = v }                       // 서버 사주 재계산(음력 정확)
        if let v = isLeapMonth { payload["isLeapMonth"] = v }
        if let v = useTrueSolarTime { payload["useTrueSolarTime"] = v }
        if let s = sajuResult { payload["sajuResult"] = sajuResultJSON(s) }
        if let n = natalChart { payload["natalChart"] = jsonValue(n) }
        if let tl = timeline { payload["timeline"] = tl }   // 실제 연도 대운/세운/월운
        if let d = daily { payload["daily"] = d }           // 오늘의 일진 (daily-* 콘텐츠 정확도)
        return stream(path: "/api/saju/content/\(id)",
                      payload: merged(payload, commonContext(birthYear: birthYear, region: region)))
    }

    enum ProxyError: Error {
        case badResponse(Int)
    }

    /// 사주 AI 해석 스트리밍 — POST /api/saju/interpret
    /// 반환: 텍스트 청크 AsyncStream
    static func interpretSaju(
        result: FortuneTellerResult, gender: String, birthYear: Int, region: String? = nil, timeline: [String: Any]? = nil
    ) -> AsyncThrowingStream<String, Error> {
        var payload: [String: Any] = [
            "sajuResult": sajuResultJSON(result),
            "gender": gender,
            "birthYear": birthYear,
        ]
        if let tl = timeline { payload["timeline"] = tl }
        return stream(path: "/api/saju/interpret", payload: merged(payload, commonContext(birthYear: birthYear, region: region)))
    }

    /// 일일운세 AI 심층 편지 스트리밍 — POST /api/daily/interpret
    static func interpretDaily(
        day: DailyFortuneResult, weekday: String, sinsals: [String],
        gender: String, birthYear: Int, region: String? = nil, style: String = "letter"
    ) -> AsyncThrowingStream<String, Error> {
        let conditions: [[String: Any]] = day.cards.map {
            ["name": $0.category, "score": $0.score, "grade": $0.grade]
        }
        var relations: [String] = []
        for tr in day.transitRelations {
            for r in tr.stemRelations { relations.append("\(tr.natalPillar)와 \(r.type)") }
            for r in tr.branchRelations { relations.append("\(tr.natalPillar)와 \(r.type)") }
        }
        // 매일 다른 최고 영역 + 주말 인지 — 직장/재물 default·일요일 상사 조언 방지
        let isWeekend = (weekday == "토요일" || weekday == "일요일")
        let (topArea, lowArea) = AppState.dailyAreas(cards: day.cards, date: day.date, isWeekend: isWeekend)
        let payload: [String: Any] = [
            "date": day.date,
            "weekday": weekday,
            "isWeekend": isWeekend,
            "topArea": topArea,
            "lowArea": lowArea,
            "dayPillarKo": "\(day.dayStemKorean)\(day.dayBranchKorean)",
            "tenGod": day.tenGodOfDay,
            "twelveStage": day.twelveStageOfDay,
            "overallScore": day.overallScore,
            "overallGrade": day.overallGrade,
            "conditions": conditions,
            "relations": relations,
            "sinsals": sinsals,
            "gender": gender,
            "birthYear": birthYear,
            "style": style,
        ]
        return stream(path: "/api/daily/interpret", payload: merged(payload, commonContext(birthYear: birthYear, region: region)))
    }

    /// 공용 스트리밍 POST
    static func stream(path: String, payload: [String: Any]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var request = URLRequest(url: baseURL.appending(path: path))
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw ProxyError.badResponse((response as? HTTPURLResponse)?.statusCode ?? -1)
                    }

                    // Vercel AI SDK data stream: `0:"텍스트"` 라인 또는 SSE `data: {...}` — 둘 다 처리
                    for try await line in bytes.lines {
                        if line.hasPrefix("0:") {
                            let jsonPart = String(line.dropFirst(2))
                            if let data = jsonPart.data(using: .utf8),
                               let text = try? JSONDecoder().decode(String.self, from: data) {
                                continuation.yield(text)
                            }
                        } else if line.hasPrefix("data: ") {
                            let jsonPart = String(line.dropFirst(6))
                            if jsonPart == "[DONE]" { break }
                            if let data = jsonPart.data(using: .utf8),
                               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                if let delta = obj["textDelta"] as? String { continuation.yield(delta) }
                                else if let text = obj["text"] as? String { continuation.yield(text) }
                            }
                        } else if !line.hasPrefix("e:") && !line.hasPrefix("d:") && !line.hasPrefix("f:") && !line.hasPrefix("8:") {
                            // 평문(마크다운) 스트리밍 폴백 — 빈 줄도 문단 구분으로 유지
                            continuation.yield(line + "\n")
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - FortuneTellerResult → API JSON (formatSajuForAI가 기대하는 필드)

    static func pillarJSON(_ p: UIPillar) -> [String: Any] {
        [
            "stem": ["hanja": p.stem.hanja, "korean": p.stem.korean, "element": p.stem.element, "yin_yang": p.stem.yin_yang],
            "branch": ["hanja": p.branch.hanja, "korean": p.branch.korean, "animal": p.branch.animal, "element": p.branch.element, "yin_yang": p.branch.yin_yang],
        ]
    }

    static func sajuResultJSON(_ r: FortuneTellerResult) -> [String: Any] {
        var pillars: [String: Any] = [
            "year": pillarJSON(r.pillars.year),
            "month": pillarJSON(r.pillars.month),
            "day": pillarJSON(r.pillars.day),
        ]
        pillars["hour"] = r.pillars.hour.map(pillarJSON) ?? NSNull()

        var profile: Any = NSNull()
        if let p = r.dayMasterProfile {
            profile = ["name": p.name, "image": p.image, "traits": p.traits]
        }

        return [
            "pillars": pillars,
            "elements": [
                "counts": r.elements.counts,
                "dominant": r.elements.dominant,
                "weakest": r.elements.weakest,
                "total": r.elements.total,
            ],
            "energyFlow": r.energyFlow,
            "gender": r.gender,
            "dayMaster": ["hanja": r.dayMaster.hanja, "korean": r.dayMaster.korean, "element": r.dayMaster.element, "yin_yang": r.dayMaster.yin_yang],
            "dayMasterProfile": profile,
            "animal": r.animal,
            "display": ["hanja": r.displayHanja, "korean": r.displayKorean],
        ]
    }
}
