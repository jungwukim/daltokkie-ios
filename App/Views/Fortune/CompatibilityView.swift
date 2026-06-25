// 궁합 — 웹 fortuneteller.ts ftCheckCompatibility 네이티브 포팅
// 점수·일간조화·띠관계·오행보완·강점/약점/조언 (온디바이스, 서버 불필요)

import SwiftUI
import SajuKit

struct CompatibilityView: View {
    @EnvironmentObject var appState: AppState

    @State private var year2 = 1995
    @State private var month2 = 6
    @State private var day2 = 15
    @State private var gender2 = "male"
    @State private var partner: FortuneTellerResult?
    @State private var errorText: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CraftCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle(text: "상대방 정보")
                        Picker("", selection: $gender2) {
                            Text("여성").tag("female")
                            Text("남성").tag("male")
                        }
                        .pickerStyle(.segmented)
                        HStack {
                            Picker("년", selection: $year2) {
                                ForEach(Array((1920...2025).reversed()), id: \.self) { Text("\(String($0))년").tag($0) }
                            }
                            Picker("월", selection: $month2) {
                                ForEach(1...12, id: \.self) { Text("\($0)월").tag($0) }
                            }
                            Picker("일", selection: $day2) {
                                ForEach(1...31, id: \.self) { Text("\($0)일").tag($0) }
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(DT.ink)

                        Button { calculate() } label: {
                            Text("궁합 보기")
                                .font(DT.sans(15, .bold)).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(DT.accent).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                if let errorText {
                    Text(errorText).font(DT.sans(13)).foregroundStyle(DT.inkSoft)
                }

                if let me = appState.ensureSaju(), let partner {
                    let o = compute(me, partner)

                    // 두 사람의 사주
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "두 사람의 사주")
                            DetailRow(label: "나", value: "\(me.displayHanja)")
                            DetailRow(label: "", value: "\(me.dayMaster.hanja) · \(animalKo(me.animal))띠")
                            DetailRow(label: "상대", value: "\(partner.displayHanja)")
                            DetailRow(label: "", value: "\(partner.dayMaster.hanja) · \(animalKo(partner.animal))띠")
                        }
                    }

                    // 궁합 결과 (점수 + 요약)
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "궁합 결과")
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(o.score)").font(DT.sans(38, .bold)).foregroundStyle(scoreColor(o.score))
                                Text("점").font(DT.sans(15)).foregroundStyle(DT.inkSoft)
                                Spacer()
                                StarRatingView(value: Double(o.score) / 20.0, size: 14)
                            }
                            Text(o.summary).font(DT.sans(13)).foregroundStyle(DT.ink).lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // 일간(日干) 관계
                    CraftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "일간(日干) 관계")
                            Text(o.harmony).font(DT.sans(14, .semibold)).foregroundStyle(DT.accent)
                        }
                    }

                    // 띠 관계
                    CraftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "띠 관계")
                            Text(o.zodiacRelation).font(DT.sans(13)).foregroundStyle(DT.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // 오행 보완 관계
                    bulletCard("오행 보완 관계", o.complements, DT.ink)
                    // 강점 / 약점 / 조언
                    bulletCard("강점", o.strengths, dtDyn(0x5A9E6F, 0x7FC093))
                    bulletCard("약점", o.weaknesses, dtDyn(0xD45555, 0xE57E7E))
                    bulletCard("조언", o.advice, dtDyn(0x5A80B0, 0x82A6D2))
                }
            }
            .padding(.horizontal, DT.pagePadding)
            .padding(.vertical, 12)
        }
        .background(DT.bg)
        .navigationTitle("궁합")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let s = shareText {
                    ShareLink(item: s) {
                        Image(systemName: "square.and.arrow.up").foregroundStyle(DT.ink)
                    }
                }
            }
        }
    }

    private var shareText: String? {
        guard let me = appState.ensureSaju(), let partner else { return nil }
        let o = compute(me, partner)
        var parts = ["[궁합] \(animalKo(me.animal))띠 × \(animalKo(partner.animal))띠",
                     "\(o.score)점 — \(o.summary)"]
        if !o.strengths.isEmpty { parts.append("\n강점\n" + o.strengths.map { "· \($0)" }.joined(separator: "\n")) }
        if !o.advice.isEmpty { parts.append("\n조언\n" + o.advice.map { "· \($0)" }.joined(separator: "\n")) }
        parts.append("\n— 달토끼")
        return parts.joined(separator: "\n")
    }

    private func bulletCard(_ title: String, _ items: [String], _ color: Color) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(DT.serif(15, .bold)).foregroundStyle(color)
                ForEach(items.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: 6) {
                        Text("·").font(DT.sans(13, .bold)).foregroundStyle(color)
                        Text(items[i]).font(DT.sans(13)).foregroundStyle(DT.ink).lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func calculate() {
        do {
            partner = try SajuCalculator.calculate(
                year: year2, month: month2, day: day2, hour: nil, gender: gender2,
                calendar: "solar", isLeapMonth: false, useTrueSolarTime: false, region: "서울", minute: 0)
            errorText = nil
        } catch { errorText = "계산 실패: \(error)" }
    }

    // MARK: - 궁합 계산 (웹 ftCheckCompatibility 포팅)

    struct CompatOutcome {
        let score: Int, summary: String, harmony: String, zodiacRelation: String
        let complements: [String], strengths: [String], weaknesses: [String], advice: [String]
    }

    private static let elementKo = ["Wood": "목(木)", "Fire": "화(火)", "Earth": "토(土)", "Metal": "금(金)", "Water": "수(水)"]
    private static let generating = ["Wood": "Fire", "Fire": "Earth", "Earth": "Metal", "Metal": "Water", "Water": "Wood"]
    private static let controlling = ["Wood": "Earth", "Earth": "Water", "Water": "Fire", "Fire": "Metal", "Metal": "Wood"]
    private static let elementOrder = ["Wood", "Fire", "Earth", "Metal", "Water"]

    private func compute(_ me: FortuneTellerResult, _ partner: FortuneTellerResult) -> CompatOutcome {
        let e1 = me.dayMaster.element, e2 = partner.dayMaster.element
        var harmony = "중립 관계"
        if Self.generating[e1] == e2 { harmony = "상생 (나 → 상대를 생함)" }
        else if Self.generating[e2] == e1 { harmony = "상생 (상대 → 나를 생함)" }
        else if e1 == e2 { harmony = "비화 — 같은 오행, 거울 에너지" }
        else if Self.controlling[e1] == e2 { harmony = "상극 (나 → 상대를 극함)" }
        else if Self.controlling[e2] == e1 { harmony = "상극 (상대 → 나를 극함)" }

        var complements: [String] = []
        for el in Self.elementOrder where (me.elements.counts[el] ?? 0) == 0 && (partner.elements.counts[el] ?? 0) > 0 {
            complements.append("상대가 나에게 부족한 \(Self.elementKo[el]!)을 보완")
        }
        for el in Self.elementOrder where (partner.elements.counts[el] ?? 0) == 0 && (me.elements.counts[el] ?? 0) > 0 {
            complements.append("내가 상대에게 부족한 \(Self.elementKo[el]!)을 보완")
        }

        let (zrel, zscore) = zodiacRelation(me.animal, partner.animal)
        let score = computeScore(harmony, zscore, complements.count)
        let (summary, strengths, weaknesses, advice) = analysis(harmony, zrel, complements, score, me.animal, partner.animal)
        let displayComp = complements.isEmpty ? ["직접적인 오행 보완 관계 없음 — 월주·일주 지지에서 더 세밀한 관계를 살펴보세요"] : complements
        return CompatOutcome(score: score, summary: summary, harmony: harmony, zodiacRelation: zrel,
                             complements: displayComp, strengths: strengths, weaknesses: weaknesses, advice: advice)
    }

    private func computeScore(_ harmony: String, _ zodiacScore: Int, _ complementCount: Int) -> Int {
        var base = zodiacScore
        if harmony.contains("상생") { base += 8 }
        else if harmony.contains("비화") { base += 3 }
        else if harmony.contains("상극") { base -= 5 }
        base += min(complementCount * 4, 12)
        return max(30, min(98, base))
    }

    private func zodiacRelation(_ a1: String, _ a2: String) -> (String, Int) {
        if a1 == a2 { return ("같은 띠 — 공감대가 크지만 충돌 가능성도 있음", 70) }
        let yukhap = [["Rat", "Ox"], ["Tiger", "Pig"], ["Rabbit", "Dog"], ["Dragon", "Rooster"], ["Snake", "Monkey"], ["Horse", "Goat"]]
        for p in yukhap where (p[0] == a1 && p[1] == a2) || (p[1] == a1 && p[0] == a2) {
            return ("육합(六合) — 서로를 끌어당기는 천생 조합", 92)
        }
        let samhap = [["Monkey", "Rat", "Dragon"], ["Tiger", "Horse", "Dog"], ["Snake", "Rooster", "Ox"], ["Pig", "Rabbit", "Goat"]]
        for t in samhap where t.contains(a1) && t.contains(a2) {
            return ("삼합(三合) — 함께할 때 시너지가 나는 조합", 85)
        }
        let chung = [["Rat", "Horse"], ["Ox", "Goat"], ["Tiger", "Monkey"], ["Rabbit", "Rooster"], ["Dragon", "Dog"], ["Snake", "Pig"]]
        for p in chung where (p[0] == a1 && p[1] == a2) || (p[1] == a1 && p[0] == a2) {
            return ("상충(相沖) — 에너지가 부딪히지만 성장의 자극제", 45)
        }
        let hyeong = [["Tiger", "Snake"], ["Tiger", "Monkey"], ["Snake", "Monkey"], ["Ox", "Dog"], ["Ox", "Goat"], ["Dog", "Goat"], ["Rat", "Rabbit"]]
        for p in hyeong where (p[0] == a1 && p[1] == a2) || (p[1] == a1 && p[0] == a2) {
            return ("상형(相刑) — 서로 자극하며 갈등 가능", 55)
        }
        let order = ["Rat", "Ox", "Tiger", "Rabbit", "Dragon", "Snake", "Horse", "Goat", "Monkey", "Rooster", "Dog", "Pig"]
        if let i1 = order.firstIndex(of: a1), let i2 = order.firstIndex(of: a2) {
            let diff = abs(i1 - i2), gap = min(diff, 12 - diff)
            if gap == 1 || gap == 11 { return ("인접 띠 — 평범하지만 안정적 관계", 65) }
        }
        return ("일반 관계 — 특별한 길흉 없이 무난", 68)
    }

    private func analysis(_ harmony: String, _ zrel: String, _ complements: [String], _ score: Int, _ a1: String, _ a2: String)
        -> (String, [String], [String], [String]) {
        let a1k = animalKo(a1), a2k = animalKo(a2)
        var strengths: [String] = [], weaknesses: [String] = [], advice: [String] = []

        if zrel.contains("육합") {
            strengths.append("\(a1k)띠와 \(a2k)띠는 육합으로 자연스러운 친밀감이 형성됩니다")
            strengths.append("서로의 부족한 점을 본능적으로 채워주는 관계입니다")
        } else if zrel.contains("삼합") {
            strengths.append("\(a1k)띠와 \(a2k)띠는 삼합으로 함께할 때 좋은 결과를 냅니다")
            strengths.append("공동 목표를 향해 협력하기 좋은 조합입니다")
        } else if zrel.contains("상충") {
            weaknesses.append("\(a1k)띠와 \(a2k)띠는 상충으로 의견 충돌이 잦을 수 있습니다")
            weaknesses.append("서로의 에너지가 정면 대립하여 갈등이 생기기 쉽습니다")
            advice.append("서로의 차이를 인정하고 양보하는 자세가 필요합니다")
        } else if zrel.contains("상형") {
            weaknesses.append("서로 자극을 주지만 과도하면 상처가 될 수 있습니다")
            advice.append("적절한 거리를 유지하며 존중하는 것이 중요합니다")
        }

        if harmony.contains("상생") && harmony.contains("나 → 상대") {
            strengths.append("나의 에너지가 상대를 자연스럽게 돕고 성장시킵니다")
        } else if harmony.contains("상생") && harmony.contains("상대 → 나") {
            strengths.append("상대의 에너지가 나를 자연스럽게 돕고 성장시킵니다")
        } else if harmony.contains("비화") {
            strengths.append("같은 오행끼리 공감대가 크고 이해가 빠릅니다")
            weaknesses.append("같은 성향이라 경쟁 의식이 생길 수 있습니다")
        } else if harmony.contains("상극") {
            weaknesses.append("일간의 오행이 상극하여 긴장감이 있을 수 있습니다")
            advice.append("상극 관계는 적절히 활용하면 서로를 단련시키는 힘이 됩니다")
        }

        if !complements.isEmpty { strengths.append("오행적으로 서로의 부족함을 보완해주는 관계입니다") }
        if strengths.isEmpty { strengths.append("특별히 강한 길흉 없이 안정적인 관계입니다") }
        if weaknesses.isEmpty { weaknesses.append("큰 갈등 요인이 적어 무난한 관계입니다") }
        if advice.isEmpty { advice.append("서로에 대한 관심과 배려를 꾸준히 유지하세요") }
        advice.append("궁합은 참고 사항이며, 관계의 핵심은 서로의 노력과 소통입니다")

        let summary: String
        if score >= 85 { summary = "\(a1k)띠와 \(a2k)띠는 매우 좋은 궁합입니다. 일간 관계: \(harmony)" }
        else if score >= 70 { summary = "\(a1k)띠와 \(a2k)띠는 양호한 궁합입니다. 일간 관계: \(harmony)" }
        else if score >= 55 { summary = "\(a1k)띠와 \(a2k)띠는 보통의 궁합입니다. 일간 관계: \(harmony)" }
        else { summary = "\(a1k)띠와 \(a2k)띠는 노력이 필요한 궁합입니다. 일간 관계: \(harmony)" }
        return (summary, strengths, weaknesses, advice)
    }

    private func scoreColor(_ s: Int) -> Color {
        if s >= 80 { return dtDyn(0x5A9E6F, 0x7FC093) }
        if s >= 60 { return dtDyn(0xE0B450, 0xEBC873) }
        return DT.accent
    }

    private func animalKo(_ en: String) -> String {
        ["Rat": "쥐", "Ox": "소", "Tiger": "호랑이", "Rabbit": "토끼", "Dragon": "용", "Snake": "뱀",
         "Horse": "말", "Goat": "양", "Monkey": "원숭이", "Rooster": "닭", "Dog": "개", "Pig": "돼지"][en] ?? en
    }
}
