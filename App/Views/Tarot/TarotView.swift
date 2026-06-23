// 타로 — 웹 mobile-tarot-page 대응 (스프레드·주제·질문·플립 리딩 + AI 타로 + 78장 도감)

import SwiftUI

struct TarotView: View {
    @EnvironmentObject var appState: AppState

    @State private var spread: TarotSpread = .three
    @State private var topic = "general"
    @State private var question = ""
    @State private var drawn: [TarotDrawn]?
    @State private var flipped: Set<UUID> = []

    private let cardCols = [GridItem(.adaptive(minimum: 88), spacing: 10)]
    private let dexCols = [GridItem(.adaptive(minimum: 76), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("달토끼 타로")
                        .font(DT.serif(20, .bold)).foregroundStyle(DT.ink)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 12)

                    if let drawn {
                        readingView(drawn)
                    } else {
                        setupView
                    }

                    catalogCard
                }
                .padding(.horizontal, DT.pagePadding)
                .padding(.bottom, 24)
            }
            .background(DT.bg)
        }
    }

    // MARK: - 뽑기 전 (스프레드·주제·질문)
    private var setupView: some View {
        VStack(spacing: 16) {
            CraftCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "스프레드 선택")
                    HStack(spacing: 8) {
                        ForEach(TarotSpread.allCases, id: \.self) { s in
                            Button { spread = s } label: {
                                VStack(spacing: 3) {
                                    Text(s.label).font(DT.sans(13, .bold))
                                    Text(s.desc).font(DT.sans(9)).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(spread == s ? DT.accent : DT.bg)
                                .foregroundStyle(spread == s ? .white : DT.ink)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            CraftCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "주제")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                        ForEach(TarotData.topics, id: \.value) { t in
                            Button { topic = t.value } label: {
                                Text("\(t.emoji) \(t.label)").font(DT.sans(12, .medium))
                                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                                    .background(topic == t.value ? DT.accent : DT.bg)
                                    .foregroundStyle(topic == t.value ? .white : DT.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            CraftCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle(text: "질문 (선택)")
                    TextField("궁금한 점을 적어보세요", text: $question, axis: .vertical)
                        .font(DT.sans(13)).foregroundStyle(DT.ink)
                        .lineLimit(1...3)
                        .padding(10).background(DT.bg).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Button { draw() } label: {
                Text("🃏 카드 뽑기").font(DT.sans(15, .bold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background(DT.accent).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - 뽑은 뒤 (플립 + AI 리딩)
    private func readingView(_ cards: [TarotDrawn]) -> some View {
        VStack(spacing: 16) {
            CraftCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            SectionTitle(text: "\(spread.label) 리딩")
                            Text(TarotData.topics.first { $0.value == topic }.map { "\($0.emoji) \($0.label)" } ?? "")
                                .font(DT.sans(11)).foregroundStyle(DT.inkSoft)
                        }
                        Spacer()
                        Button { drawn = nil; flipped = [] } label: {
                            Text("다시 뽑기").font(DT.sans(12, .semibold)).foregroundStyle(DT.accent)
                        }
                    }
                    if flipped.count < cards.count {
                        Text("카드를 탭하여 뒤집어 보세요").font(DT.sans(11)).foregroundStyle(DT.inkSoft)
                    }
                    LazyVGrid(columns: cardCols, spacing: 12) {
                        ForEach(cards) { d in cardCell(d) }
                    }
                }
            }

            if flipped.count == cards.count {
                AIInterpretationView(title: "AI 타로 리딩") {
                    AIProxy.interpretTarot(
                        cards: cards.map { d in
                            ["name": d.card.name, "nameKo": d.card.nameKo, "isReversed": d.isReversed,
                             "position": d.position, "keywords": d.isReversed ? d.card.keywordsReversed : d.card.keywords]
                        },
                        spread: spread.rawValue, topic: topic, question: question)
                }
            }
        }
    }

    private func cardCell(_ d: TarotDrawn) -> some View {
        let isFlipped = flipped.contains(d.id)
        return VStack(spacing: 4) {
            Text(d.position).font(DT.sans(9, .semibold)).foregroundStyle(DT.inkSoft).lineLimit(1)
            Image(isFlipped ? d.card.asset : "tarot-back")
                .resizable().scaledToFit().frame(height: 120)
                .rotationEffect(.degrees(isFlipped && d.isReversed ? 180 : 0))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture { withAnimation(.spring(duration: 0.4)) { _ = flipped.insert(d.id) } }
            if isFlipped {
                Text(d.card.nameKo + (d.isReversed ? " (역)" : ""))
                    .font(DT.sans(10, .semibold)).foregroundStyle(d.isReversed ? Color(hex: 0xD45555) : DT.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text((d.isReversed ? d.card.keywordsReversed : d.card.keywords).joined(separator: "·"))
                    .font(DT.sans(8)).foregroundStyle(DT.inkSoft).multilineTextAlignment(.center)
                    .lineLimit(2).minimumScaleFactor(0.7)
            }
        }
    }

    // MARK: - 78장 도감
    private var catalogCard: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "카드 도감 (78장)")
                LazyVGrid(columns: dexCols, spacing: 12) {
                    ForEach(TarotData.all) { card in
                        VStack(spacing: 4) {
                            Image(card.asset).resizable().scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(card.nameKo).font(DT.sans(9)).foregroundStyle(DT.inkSoft)
                                .lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                }
            }
        }
    }

    private func draw() {
        let p = appState.profile
        let seed = TarotData.makeSeed(year: p?.year ?? 2000, month: p?.month ?? 1, day: p?.day ?? 1, spread: spread)
        flipped = []
        drawn = TarotData.drawCards(spread: spread, seed: seed)
    }
}
