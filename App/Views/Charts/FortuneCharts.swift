// 운세 차트 — 행운지수 꺾은선 / 컨디션 레이더 / 카테고리 막대
// 웹 SVG 차트(fortune-bar-chart, fortune-radar-chart) 대응, Canvas/Path 구현

import SwiftUI
import SajuKit

// MARK: - 행운지수 꺾은선 (오늘 중심 5일)

struct LuckyLineChart: View {
    let fortunes: [DailyFortuneResult]
    let todayDate: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = fortunes.count
            let stepX = w / CGFloat(max(count - 1, 1))
            let points: [CGPoint] = fortunes.enumerated().map { i, f in
                CGPoint(x: CGFloat(i) * stepX, y: h - h * CGFloat(f.overallScore) / 100)
            }

            ZStack {
                // 그리드
                ForEach(0..<5) { i in
                    Path { p in
                        let y = h * CGFloat(i) / 4
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(DT.line.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                }

                // 면 채움
                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: CGPoint(x: first.x, y: h))
                    for pt in points { p.addLine(to: pt) }
                    p.addLine(to: CGPoint(x: points.last!.x, y: h))
                    p.closeSubpath()
                }
                .fill(DT.accent.opacity(0.12))

                // 선
                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(DT.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // 점 + 라벨
                ForEach(Array(fortunes.enumerated()), id: \.offset) { i, f in
                    let isToday = f.date == todayDate
                    Circle()
                        .fill(isToday ? DT.accent : DT.card)
                        .stroke(DT.accent, lineWidth: 2)
                        .frame(width: isToday ? 12 : 8, height: isToday ? 12 : 8)
                        .position(points[i])
                    Text("\(f.overallScore)")
                        .font(DT.sans(10, isToday ? .bold : .regular))
                        .foregroundStyle(isToday ? DT.accent : DT.inkSoft)
                        .position(x: points[i].x, y: max(10, points[i].y - 16))
                }
            }
        }
    }
}

// MARK: - 레이더 차트 (운세 컨디션 — 카드 점수)

struct FortuneRadarChart: View {
    let cards: [DailyFortuneCard]   // 표시할 카드 (보통 5개)

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 24
            let n = cards.count

            ZStack {
                // 동심 그물 (3단)
                ForEach(1...3, id: \.self) { ring in
                    polygon(center: center, radius: radius * CGFloat(ring) / 3, sides: n)
                        .stroke(DT.line, lineWidth: 1)
                }
                // 축선
                ForEach(0..<n, id: \.self) { i in
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: vertex(center: center, radius: radius, index: i, total: n))
                    }
                    .stroke(DT.line, lineWidth: 1)
                }
                // 데이터 영역
                dataPath(center: center, radius: radius)
                    .fill(DT.accent.opacity(0.25))
                dataPath(center: center, radius: radius)
                    .stroke(DT.accent, lineWidth: 2)

                // 라벨
                ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                    let pos = vertex(center: center, radius: radius + 15, index: i, total: n)
                    Text(card.category.replacingOccurrences(of: "운", with: ""))
                        .font(DT.sans(11, .medium))
                        .foregroundStyle(DT.ink)
                        .position(pos)
                }
            }
        }
    }

    private func vertex(center: CGPoint, radius: CGFloat, index: Int, total: Int) -> CGPoint {
        let angle = -CGFloat.pi / 2 + 2 * .pi * CGFloat(index) / CGFloat(total)
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

    private func polygon(center: CGPoint, radius: CGFloat, sides: Int) -> Path {
        Path { p in
            for i in 0..<sides {
                let pt = vertex(center: center, radius: radius, index: i, total: sides)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }

    private func dataPath(center: CGPoint, radius: CGFloat) -> Path {
        Path { p in
            for (i, card) in cards.enumerated() {
                let r = radius * CGFloat(card.score) / 100
                let pt = vertex(center: center, radius: r, index: i, total: cards.count)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
        }
    }
}

// MARK: - 카테고리 막대 차트 (10개 전체)

struct FortuneBarChart: View {
    let cards: [DailyFortuneCard]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                VStack(spacing: 5) {
                    Text("\(card.score)")
                        .font(DT.sans(9))
                        .foregroundStyle(DT.inkSoft)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(card.score >= 70 ? DT.accent : DT.accent.opacity(0.45))
                        .frame(height: max(8, CGFloat(card.score)))
                    Text(card.category.replacingOccurrences(of: "운", with: ""))
                        .font(DT.sans(10))
                        .foregroundStyle(DT.ink)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150, alignment: .bottom)
    }
}
