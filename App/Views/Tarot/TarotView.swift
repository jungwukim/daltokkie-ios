// 타로 — 78장 카탈로그 + 카드 뽑기 (웹 mobile-tarot-page 대응)

import SwiftUI

struct TarotCard: Identifiable {
    let id: String          // 에셋 이름
    let name: String

    static let majorNames = [
        "바보", "마법사", "여사제", "여황제", "황제", "교황", "연인", "전차",
        "힘", "은둔자", "운명의 수레바퀴", "정의", "매달린 사람", "죽음",
        "절제", "악마", "탑", "별", "달", "태양", "심판", "세계",
    ]
    static let suitKo = ["cups": "컵", "pentacles": "펜타클", "swords": "소드", "wands": "완드"]

    static let all: [TarotCard] = {
        var cards: [TarotCard] = []
        for i in 0..<22 {
            cards.append(TarotCard(id: String(format: "tarot-major-%02d", i), name: majorNames[i]))
        }
        for suit in ["cups", "pentacles", "swords", "wands"] {
            for n in 1...14 {
                let label: String
                switch n {
                case 1: label = "에이스"
                case 11: label = "시종"
                case 12: label = "기사"
                case 13: label = "여왕"
                case 14: label = "왕"
                default: label = "\(n)"
                }
                cards.append(TarotCard(id: String(format: "tarot-%@-%02d", suit, n), name: "\(suitKo[suit]!) \(label)"))
            }
        }
        return cards
    }()
}

struct TarotView: View {
    @State private var drawn: [TarotCard] = []
    @State private var revealed = false

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("달토끼 타로")
                        .font(DT.serif(20, .bold))
                        .foregroundStyle(DT.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)

                    // 오늘의 카드 뽑기
                    CraftCard {
                        VStack(spacing: 14) {
                            SectionTitle(text: "오늘의 카드")
                            HStack(spacing: 12) {
                                ForEach(drawn) { card in
                                    VStack(spacing: 6) {
                                        Image(revealed ? card.id : "tarot-back")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 130)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        if revealed {
                                            Text(card.name)
                                                .font(DT.sans(11, .semibold))
                                                .foregroundStyle(DT.ink)
                                        }
                                    }
                                }
                                if drawn.isEmpty {
                                    ForEach(0..<3, id: \.self) { _ in
                                        Image("tarot-back")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 130)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .opacity(0.5)
                                    }
                                }
                            }
                            Button {
                                withAnimation(.spring(duration: 0.5)) {
                                    if drawn.isEmpty || revealed {
                                        drawn = Array(TarotCard.all.shuffled().prefix(3))
                                        revealed = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            withAnimation { revealed = true }
                                        }
                                    }
                                }
                            } label: {
                                Text(drawn.isEmpty ? "세 장 뽑기" : "다시 뽑기")
                                    .font(DT.sans(14, .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 10)
                                    .background(DT.accent)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // 카드 도감
                    CraftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "카드 도감 (78장)")
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(TarotCard.all) { card in
                                    VStack(spacing: 4) {
                                        Image(card.id)
                                            .resizable()
                                            .scaledToFit()
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                        Text(card.name)
                                            .font(DT.sans(9))
                                            .foregroundStyle(DT.inkSoft)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.bottom, 24)
            }
            .background(DT.bg)
        }
    }
}
