// 점성술 원형 차트 — 웹 natal-wheel-chart 포팅 (Canvas)
// 황도 12별자리 띠(원소색) + 12하우스 + 행성 글리프 + 어스펙트 라인 + ASC/MC 축
// onDark: 밤하늘 히어로 배경용 다크 테마

import SwiftUI
import NatalKit

struct NatalWheelChart: View {
    let chart: NatalChart
    var onDark: Bool = false

    private let planetGlyph: [String: String] = [
        "Sun": "☉", "Moon": "☽", "Mercury": "☿", "Venus": "♀", "Mars": "♂",
        "Jupiter": "♃", "Saturn": "♄", "Uranus": "♅", "Neptune": "♆", "Pluto": "♇",
        "Chiron": "⚷", "NorthNode": "☊", "SouthNode": "☋", "Fortuna": "⊗",
    ]
    private let signGlyphs = ["♈","♉","♊","♋","♌","♍","♎","♏","♐","♑","♒","♓"]

    // 원소색 (불/흙/바람/물) — 별자리 인덱스 % 4
    private func signFill(_ i: Int) -> Color {
        if onDark {
            switch i % 4 {
            case 0:  return Color(hex: 0xE8927C).opacity(0.16)  // Fire
            case 1:  return Color(hex: 0x8FBF9F).opacity(0.16)  // Earth
            case 2:  return Color(hex: 0xE8C77A).opacity(0.16)  // Air
            default: return Color(hex: 0x88B4E0).opacity(0.16)  // Water
            }
        }
        switch i % 4 {
        case 0:  return Color(hex: 0xFEF2F2)   // Fire
        case 1:  return Color(hex: 0xF0FDF4)   // Earth
        case 2:  return Color(hex: 0xFEFCE8)   // Air
        default: return Color(hex: 0xEFF6FF)   // Water
        }
    }
    private func aspectStyle(_ type: String) -> (color: Color, dash: [CGFloat]) {
        switch type {
        case "conjunction": return (Color(hex: 0xB794F6), [])
        case "sextile":     return (Color(hex: 0x4ADE80), [4, 3])
        case "trine":       return (Color(hex: 0x60A5FA), [6, 3])
        case "square":      return (Color(hex: 0xF87171), [])
        case "opposition":  return (Color(hex: 0xFB923C), [])
        default:            return (Color(hex: 0x9CA3AF), [2, 2])
        }
    }

    // 테마별 선/글자색
    private var ringStrong: Color { onDark ? .white.opacity(0.22) : Color(hex: 0xD9CDB5) }
    private var ringSoft: Color   { onDark ? .white.opacity(0.12) : Color(hex: 0xE8DCC4) }
    private var glyphColor: Color { onDark ? Color(hex: 0xF0E6D2) : Color(hex: 0x6B7280) }
    private var houseLine: Color  { onDark ? .white.opacity(0.10) : Color(hex: 0xE5E0D2) }
    private var houseAngular: Color { onDark ? .white.opacity(0.34) : Color(hex: 0x9CA3AF) }
    private var houseNum: Color   { onDark ? .white.opacity(0.45) : DT.inkSoft }
    private var planetInk: Color  { onDark ? Color(hex: 0xFBF7EF) : DT.ink }
    private var connColor: Color  { onDark ? .white.opacity(0.16) : Color(hex: 0xCBB994) }

    var body: some View {
        Canvas { ctx, size in draw(ctx, side: size.width) }
            .aspectRatio(1, contentMode: .fit)
    }

    private func draw(_ ctx: GraphicsContext, side: CGFloat) {
        let cx = side / 2, cy = side / 2, R = side / 2
        let rOuter = R * 0.97, rSignIn = R * 0.80, rHouseLbl = R * 0.70
        let rPlanet = R * 0.56, rInner = R * 0.42
        let ascLon = chart.angles?.asc.longitude ?? 0

        func lonToAngle(_ lon: Double) -> Double { -(lon - ascLon) + 180 }
        func pt(_ deg: Double, _ r: CGFloat) -> CGPoint {
            let rad = deg * .pi / 180
            return CGPoint(x: cx + r * CGFloat(cos(rad)), y: cy - r * CGFloat(sin(rad)))
        }
        func ring(_ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)) }

        // 별자리 섹터 (원소색 채움) + 글리프
        for i in 0..<12 {
            let aStart = lonToAngle(Double(i) * 30), aEnd = lonToAngle(Double(i) * 30 + 30)
            var p = Path()
            let steps = 12
            for s in 0...steps {
                let a = aStart + (aEnd - aStart) * Double(s) / Double(steps)
                let q = pt(a, rOuter); s == 0 ? p.move(to: q) : p.addLine(to: q)
            }
            for s in stride(from: steps, through: 0, by: -1) {
                let a = aStart + (aEnd - aStart) * Double(s) / Double(steps)
                p.addLine(to: pt(a, rSignIn))
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(signFill(i)))
            let mid = (aStart + aEnd) / 2
            ctx.draw(Text(signGlyphs[i]).font(.system(size: side * 0.045)).foregroundColor(glyphColor),
                     at: pt(mid, (rOuter + rSignIn) / 2))
        }
        ctx.stroke(ring(rOuter), with: .color(ringStrong), lineWidth: 1)
        ctx.stroke(ring(rSignIn), with: .color(ringSoft), lineWidth: 1)
        ctx.stroke(ring(rInner), with: .color(ringSoft), lineWidth: 0.8)

        // 하우스 라인 + 번호
        let houses = chart.houses
        for (idx, h) in houses.enumerated() {
            let a = lonToAngle(h.cuspLongitude)
            let angular = [1, 4, 7, 10].contains(h.number)
            var line = Path(); line.move(to: pt(a, rInner)); line.addLine(to: pt(a, rSignIn))
            ctx.stroke(line, with: .color(angular ? houseAngular : houseLine),
                       lineWidth: angular ? 1.1 : 0.5)
            let next = houses[(idx + 1) % houses.count]
            var midLon = (h.cuspLongitude + next.cuspLongitude) / 2
            if abs(next.cuspLongitude - h.cuspLongitude) > 180 { midLon += 180 }
            ctx.draw(Text("\(h.number)").font(.system(size: side * 0.032)).foregroundColor(houseNum),
                     at: pt(lonToAngle(midLon), rHouseLbl))
        }

        // 어스펙트 라인 (중앙)
        let byId = Dictionary(uniqueKeysWithValues: chart.planets.map { ($0.id, $0.longitude) })
        for a in chart.aspects.prefix(18) {
            guard let l1 = byId[a.planet1], let l2 = byId[a.planet2] else { continue }
            let st = aspectStyle(a.type)
            var line = Path(); line.move(to: pt(lonToAngle(l1), rInner)); line.addLine(to: pt(lonToAngle(l2), rInner))
            ctx.stroke(line, with: .color(st.color.opacity(onDark ? 0.55 : 0.45)),
                       style: StrokeStyle(lineWidth: 0.8, dash: st.dash))
        }

        // ASC / MC 축
        if let ang = chart.angles {
            let ascCol = onDark ? Color(hex: 0xE8C77A) : Color(hex: 0x374151)
            let mcCol  = onDark ? .white.opacity(0.7) : Color(hex: 0x6B7280)
            for (lon, label, w, col) in [(ang.asc.longitude, "ASC", 1.8, ascCol),
                                         (ang.mc.longitude, "MC", 1.0, mcCol)] {
                let a = lonToAngle(lon)
                var line = Path(); line.move(to: pt(a, 0)); line.addLine(to: pt(a, rOuter))
                ctx.stroke(line, with: .color(col), lineWidth: w)
                ctx.draw(Text(label).font(.system(size: side * 0.03, weight: .bold)).foregroundColor(col),
                         at: pt(a, rOuter + R * 0.02))
            }
        }

        // 행성 글리프 (충돌 분산)
        var items = chart.planets.map { (id: $0.id, deg: lonToAngle($0.longitude), retro: $0.isRetrograde) }
        items.sort { $0.deg < $1.deg }
        let minGap = 9.0
        for i in 1..<max(1, items.count) where items[i].deg - items[i - 1].deg < minGap {
            items[i].deg = items[i - 1].deg + minGap
        }
        for it in items {
            let base = pt(it.deg, rSignIn - R * 0.02), glyphPt = pt(it.deg, rPlanet)
            var conn = Path(); conn.move(to: base); conn.addLine(to: pt(it.deg, rPlanet + R * 0.05))
            ctx.stroke(conn, with: .color(connColor), lineWidth: 0.5)
            ctx.draw(Text(planetGlyph[it.id] ?? "•").font(.system(size: side * 0.05)).foregroundColor(planetInk),
                     at: glyphPt)
            if it.retro {
                ctx.draw(Text("R").font(.system(size: side * 0.025, weight: .bold)).foregroundColor(DT.accent),
                         at: CGPoint(x: glyphPt.x + side * 0.035, y: glyphPt.y - side * 0.03))
            }
        }
    }
}
