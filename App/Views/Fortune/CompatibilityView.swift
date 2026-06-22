// 궁합 — 상대 생년월일 입력 + 일간/띠 관계 (웹 mobile-compat-page 대응, 온디바이스 약식)

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

                        Button {
                            calculate()
                        } label: {
                            Text("궁합 보기")
                                .font(DT.sans(15, .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(DT.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                if let errorText {
                    Text(errorText)
                        .font(DT.sans(13))
                        .foregroundStyle(DT.inkSoft)
                }

                if let me = appState.ensureSaju(), let partner {
                    let score = compatScore(me: me, partner: partner)

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "종합 궁합")
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(score)").font(DT.sans(34, .bold)).foregroundStyle(DT.accent)
                                Text("점").font(DT.sans(14)).foregroundStyle(DT.inkSoft)
                                Spacer()
                                StarRatingView(value: Double(score) / 20.0, size: 14)
                            }
                            Text(compatComment(score))
                                .font(DT.sans(13)).foregroundStyle(DT.ink).lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "두 사람의 사주")
                            DetailRow(label: "나", value: me.displayHanja)
                            DetailRow(label: "상대", value: partner.displayHanja)
                            DetailRow(label: "일간", value: "\(me.dayMaster.hanja) ↔ \(partner.dayMaster.hanja)")
                            DetailRow(label: "띠", value: "\(animalKo(me.animal)) ↔ \(animalKo(partner.animal))")
                            DetailRow(label: "띠 관계", value: zodiacRelation(me.animal, partner.animal))
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            SectionTitle(text: "일간 관계 (십성)")
                            let ptm = tenGod(of: partner, seenBy: me)
                            let mtp = tenGod(of: me, seenBy: partner)
                            DetailRow(label: "상대 → 나", value: "\(ptm) — \(tenGodMeaning(ptm))")
                            DetailRow(label: "나 → 상대", value: "\(mtp) — \(tenGodMeaning(mtp))")
                        }
                    }

                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "오행 보완")
                            Text(elementComplement(me: me, partner: partner))
                                .font(DT.sans(13))
                                .foregroundStyle(DT.ink)
                                .lineSpacing(4)
                        }
                    }
                }
            }
            .padding(.horizontal, DT.pagePadding)
            .padding(.vertical, 12)
        }
        .background(DT.bg)
        .navigationTitle("궁합")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func calculate() {
        do {
            partner = try SajuCalculator.calculate(
                year: year2, month: month2, day: day2,
                hour: nil, gender: gender2,
                calendar: "solar", isLeapMonth: false,
                useTrueSolarTime: false, region: "서울", minute: 0
            )
            errorText = nil
        } catch {
            errorText = "계산 실패: \(error)"
        }
    }

    private func animalKo(_ en: String) -> String {
        let map = ["Rat": "쥐", "Ox": "소", "Tiger": "호랑이", "Rabbit": "토끼", "Dragon": "용", "Snake": "뱀",
                   "Horse": "말", "Goat": "양", "Monkey": "원숭이", "Rooster": "닭", "Dog": "개", "Pig": "돼지"]
        return map[en] ?? en
    }

    /// fortuneteller.ts 띠 관계 테이블 (삼합/육합/충)
    private func zodiacRelation(_ a: String, _ b: String) -> String {
        let samhap: [[String]] = [["Monkey", "Rat", "Dragon"], ["Tiger", "Horse", "Dog"], ["Snake", "Rooster", "Ox"], ["Pig", "Rabbit", "Goat"]]
        let yukhap: [[String]] = [["Rat", "Ox"], ["Tiger", "Pig"], ["Rabbit", "Dog"], ["Dragon", "Rooster"], ["Snake", "Monkey"], ["Horse", "Goat"]]
        let chung: [[String]] = [["Rat", "Horse"], ["Ox", "Goat"], ["Tiger", "Monkey"], ["Rabbit", "Rooster"], ["Dragon", "Dog"], ["Snake", "Pig"]]

        if samhap.contains(where: { $0.contains(a) && $0.contains(b) && a != b }) {
            return "삼합(三合) — 서로를 끌어주는 최고의 인연"
        }
        if yukhap.contains(where: { Set($0) == Set([a, b]) }) {
            return "육합(六合) — 자연스럽게 어울리는 좋은 관계"
        }
        if chung.contains(where: { Set($0) == Set([a, b]) }) {
            return "충(沖) — 부딪힘이 있지만 서로 자극이 되는 관계"
        }
        if a == b {
            return "같은 띠 — 서로를 잘 이해하는 관계"
        }
        return "무난한 관계 — 노력에 따라 좋아질 수 있어요"
    }

    /// target 일간이 viewer 입장에서 갖는 십성
    private func tenGod(of target: FortuneTellerResult, seenBy viewer: FortuneTellerResult) -> String {
        EngineAnalysis.getTenGod(
            dayMasterElement: viewer.dayMaster.element, dayMasterYinYang: viewer.dayMaster.yin_yang,
            targetElement: target.dayMaster.element, targetYinYang: target.dayMaster.yin_yang
        )
    }
    private func tenGodMeaning(_ g: String) -> String {
        [
            "정관": "믿고 의지하는 안정적 관계", "편관": "끌리지만 긴장도 있는 관계",
            "정재": "아끼고 돌보는 다정한 관계", "편재": "활기차고 자유로운 관계",
            "정인": "보살핌을 주고받는 관계", "편인": "독특하게 통하는 관계",
            "식신": "함께 있으면 편하고 즐거운 관계", "상관": "자극과 표현이 오가는 관계",
            "비견": "친구처럼 동등한 관계", "겁재": "경쟁심이 생길 수 있는 관계",
        ][g] ?? "서로를 알아가는 관계"
    }
    private func tenGodPoints(_ g: String) -> Int {
        switch g {
        case "정관", "정재", "정인", "식신": return 10
        case "편재", "편인": return 4
        case "비견", "상관": return 0
        case "편관", "겁재": return -8
        default: return 0
        }
    }
    /// 종합 궁합 점수 (띠 관계 + 일간 십성 양방향 + 오행 보완)
    private func compatScore(me: FortuneTellerResult, partner: FortuneTellerResult) -> Int {
        var s = 50
        let rel = zodiacRelation(me.animal, partner.animal)
        if rel.contains("삼합") { s += 20 }
        else if rel.contains("육합") { s += 15 }
        else if rel.contains("같은 띠") { s += 5 }
        else if rel.contains("충") { s -= 10 }
        s += tenGodPoints(tenGod(of: partner, seenBy: me))
        s += tenGodPoints(tenGod(of: me, seenBy: partner))
        if me.elements.weakest == partner.elements.dominant { s += 8 }
        if partner.elements.weakest == me.elements.dominant { s += 8 }
        return max(15, min(98, s))
    }
    private func compatComment(_ score: Int) -> String {
        switch score {
        case 80...: return "서로를 끌어주고 채워주는 깊은 인연이에요. 신뢰를 바탕으로 오래 함께하기 좋아요."
        case 65..<80: return "잘 어울리는 편이에요. 작은 배려를 더하면 더 단단해지는 관계예요."
        case 50..<65: return "무난한 관계예요. 다른 점을 인정하면 서로에게 좋은 자극이 돼요."
        default: return "부딪힘이 있을 수 있는 관계예요. 천천히 맞춰가면 오히려 단단해질 수 있어요."
        }
    }

    private func elementComplement(me: FortuneTellerResult, partner: FortuneTellerResult) -> String {
        let ko = ["Wood": "목(木)", "Fire": "화(火)", "Earth": "토(土)", "Metal": "금(金)", "Water": "수(水)"]
        var lines: [String] = []
        let myWeak = me.elements.weakest
        let partnerDominant = partner.elements.dominant
        if myWeak == partnerDominant {
            lines.append("나에게 부족한 \(ko[myWeak] ?? myWeak) 기운을 상대가 채워줘요.")
        }
        let partnerWeak = partner.elements.weakest
        let myDominant = me.elements.dominant
        if partnerWeak == myDominant {
            lines.append("상대에게 부족한 \(ko[partnerWeak] ?? partnerWeak) 기운을 내가 채워줘요.")
        }
        if lines.isEmpty {
            lines.append("나는 \(ko[myDominant] ?? myDominant) 기운이 강하고, 상대는 \(ko[partnerDominant] ?? partnerDominant) 기운이 강해요. 서로 다른 색의 기운이 만나 균형을 찾아가는 관계예요.")
        }
        return lines.joined(separator: "\n")
    }
}
