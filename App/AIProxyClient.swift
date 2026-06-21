// AI 프록시 클라이언트 — daltokkie.vercel.app 해석 API (유일한 서버 의존)
// Vercel AI SDK 스트리밍(text 프로토콜) 수신: URLSession.bytes 라인 단위 처리
//
// 스키마 규칙 (DESIGN.md 9-5): 계산 결과를 API 원본 타입 형태(JSON)로 전달

import Foundation
import SajuKit

enum AIProxy {
    static let baseURL = URL(string: "https://daltokkie.vercel.app")!

    enum ProxyError: Error {
        case badResponse(Int)
    }

    /// 사주 AI 해석 스트리밍 — POST /api/saju/interpret
    /// 반환: 텍스트 청크 AsyncStream
    static func interpretSaju(
        result: FortuneTellerResult, gender: String, birthYear: Int
    ) -> AsyncThrowingStream<String, Error> {
        let payload: [String: Any] = [
            "sajuResult": sajuResultJSON(result),
            "gender": gender,
            "birthYear": birthYear,
        ]
        return stream(path: "/api/saju/interpret", payload: payload)
    }

    /// 일일운세 AI 심층 편지 스트리밍 — POST /api/daily/interpret
    static func interpretDaily(
        day: DailyFortuneResult, weekday: String, sinsals: [String],
        gender: String, birthYear: Int
    ) -> AsyncThrowingStream<String, Error> {
        let conditions: [[String: Any]] = day.cards.map {
            ["name": $0.category, "score": $0.score, "grade": $0.grade]
        }
        var relations: [String] = []
        for tr in day.transitRelations {
            for r in tr.stemRelations { relations.append("\(tr.natalPillar)와 \(r.type)") }
            for r in tr.branchRelations { relations.append("\(tr.natalPillar)와 \(r.type)") }
        }
        let payload: [String: Any] = [
            "date": day.date,
            "weekday": weekday,
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
        ]
        return stream(path: "/api/daily/interpret", payload: payload)
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
