// 운세 컨디션 — 메인 시안의 5종(재물/연애/인간관계/감정/건강)
// 엔진 10개 카드에서 5종을 선별·매핑

import SwiftUI
import SajuKit

struct ConditionItem {
    let title: String        // 재물/연애/인간관계/감정/건강
    let score: Int           // 0~100
    let asset: String        // item-0N
    let gaugeColor: Color
}

enum HomeConditions {
    /// 엔진 카드(재물운/연애운/대인운/가정운/건강운 등) → 시안 5종
    /// 매핑: 재물←재물, 연애←연애, 인간관계←대인, 감정←가정, 건강←건강
    static func from(cards: [DailyFortuneCard]) -> [ConditionItem] {
        func score(_ label: String) -> Int {
            cards.first { $0.category == label }?.score ?? 50
        }
        return [
            ConditionItem(title: "재물", score: score("재물운"), asset: "item-01", gaugeColor: Color(hex: 0x8DA9C4)),
            ConditionItem(title: "연애", score: score("연애운"), asset: "item-02", gaugeColor: Color(hex: 0xE89BB0)),
            ConditionItem(title: "인간관계", score: score("대인운"), asset: "item-03", gaugeColor: Color(hex: 0xE0B450)),
            ConditionItem(title: "감정", score: score("가정운"), asset: "item-04", gaugeColor: Color(hex: 0xB39DC9)),
            ConditionItem(title: "건강", score: score("건강운"), asset: "item-05", gaugeColor: Color(hex: 0x8FB996)),
        ]
    }

    /// 점수 → 5단계 별점 (0.5 단위)
    static func stars(_ score: Int) -> Double {
        // 10~100 → 1.0~5.0, 0.5 반올림
        let raw = 1.0 + Double(max(0, min(100, score))) / 100.0 * 4.0
        return (raw * 2).rounded() / 2
    }
}

/// 별점 행 (★ 채움/반/빈, 0.5 단위)
struct StarRatingView: View {
    let value: Double        // 0.0 ~ 5.0
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { i in
                let filled = value - Double(i)
                Image(systemName: filled >= 1 ? "star.fill" : (filled >= 0.5 ? "star.leadinghalf.filled" : "star"))
                    .font(.system(size: size))
                    .foregroundStyle(filled >= 0.5 ? Color(hex: 0xE0B450) : DT.line)
            }
        }
    }
}

/// 컨디션 카드 (시안: 일러스트 + 별점 + 게이지 바)
struct ConditionCard: View {
    let item: ConditionItem

    var body: some View {
        VStack(spacing: 10) {
            Text(item.title)
                .font(DT.sans(12, .semibold))
                .foregroundStyle(DT.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            LuckyIconView(assetName: item.asset, fallbackSymbol: "sparkles", size: 46)
                .padding(.vertical, 2)
            StarRatingView(value: HomeConditions.stars(item.score), size: 8.5)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DT.line, lineWidth: 1))
    }
}
