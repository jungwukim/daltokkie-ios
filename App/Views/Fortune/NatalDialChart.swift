// 출생 차트 — 고급 기계식 계기판(크로노그래프·나침반) 재해석
// 메탈 베젤(베벨 음영) · 유리 반사 · 음각 챕터링 · 옥스블러드 바늘
// 진입 시 링/바늘이 스윕하며 정착(calibration). 천체 매핑은 검증된 lonToAngle 유지.

import SwiftUI
import NatalKit

struct NatalDialChart: View {
    let chart: NatalChart

    @State private var startedAt = Date()
    @State private var finished = false

    // U+FE0E(텍스트 변형 셀렉터) — iOS가 컬러 이모지로 렌더하지 않고 모노크롬 음각 글리프로 표시
    private let planetGlyph: [String: String] = [
        "Sun": "☉\u{FE0E}", "Moon": "☽\u{FE0E}", "Mercury": "☿\u{FE0E}", "Venus": "♀\u{FE0E}", "Mars": "♂\u{FE0E}",
        "Jupiter": "♃\u{FE0E}", "Saturn": "♄\u{FE0E}", "Uranus": "♅\u{FE0E}", "Neptune": "♆\u{FE0E}", "Pluto": "♇\u{FE0E}",
        "Chiron": "⚷\u{FE0E}", "NorthNode": "☊\u{FE0E}", "SouthNode": "☋\u{FE0E}", "Fortuna": "⊗\u{FE0E}",
    ]
    private let signGlyphs = ["♈\u{FE0E}","♉\u{FE0E}","♊\u{FE0E}","♋\u{FE0E}","♌\u{FE0E}","♍\u{FE0E}",
                             "♎\u{FE0E}","♏\u{FE0E}","♐\u{FE0E}","♑\u{FE0E}","♒\u{FE0E}","♓\u{FE0E}"]

    // 팔레트 — 따뜻한 럭셔리 인스트루먼트 (밤하늘 보라/청록 배제)
    private let bezelLight = Color(hex: 0x4A4944)
    private let bezelMid   = Color(hex: 0x2A2825)
    private let bezelDark  = Color(hex: 0x121110)
    private let brass      = Color(hex: 0xB8975A)
    private let brassSoft  = Color(hex: 0x8C6E3C)
    private let dialHi     = Color(hex: 0xF8F2E6)
    private let dialLo     = Color(hex: 0xE4D6BC)
    private let ink        = Color(hex: 0x2C2620)
    private let tickInk    = Color(hex: 0x6E5C3C)
    private let oxblood    = Color(hex: 0xA8392F)

    var body: some View {
        // TimelineView(.animation)로 매 프레임 구동 — Canvas는 withAnimation만으로 보간 redraw 안 됨
        TimelineView(.animation(paused: finished)) { timeline in
            let t = timeline.date.timeIntervalSince(startedAt)
            Canvas { ctx, size in draw(ctx, side: size.width, t: t) }
                .aspectRatio(1, contentMode: .fit)
        }
        .onAppear {
            startedAt = Date()
            finished = false
            Task { try? await Task.sleep(for: .seconds(2.4)); finished = true }
        }
        .accessibilityElement()
        .accessibilityLabel("출생 천궁도 — 계기판형 차트")
    }

    // 이징
    private func clamp01(_ x: Double) -> Double { max(0, min(1, x)) }
    private func easeOutCubic(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
    private func easeOutBack(_ x: Double) -> Double {
        let c1 = 1.70158, c3 = 2.70158
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }

    private func draw(_ ctx0: GraphicsContext, side: CGFloat, t: TimeInterval) {
        var ctx = ctx0
        let cx = side / 2, cy = side / 2

        // 진행도 — 구조(베젤/링) → 행성/바늘 정착(살짝 오버슈트)
        let appear = easeOutCubic(clamp01(t / 0.9))            // 불투명도/스케일
        let sRaw = clamp01((t - 0.30) / 1.05)
        let sweep = easeOutCubic(sRaw)                         // 행성/바늘 불투명도
        let settleRing = easeOutBack(clamp01(t / 1.0))         // 챕터링 정착(오버슈트)
        let settleBody = easeOutBack(sRaw)                     // 행성/바늘 정착(오버슈트)

        let scale = 0.93 + 0.07 * appear
        let R = side / 2 * 0.97 * scale
        let ascLon = chart.angles?.asc.longitude ?? 0

        // 진입 회전 오프셋(정착 스윕)
        let ringRot = (1 - settleRing) * 22.0
        let bodyRot = (1 - settleBody) * 40.0

        func lonToAngle(_ lon: Double, _ rot: Double = 0) -> Double { -(lon - ascLon) + 180 - rot }
        func pt(_ deg: Double, _ r: CGFloat) -> CGPoint {
            let rad = deg * .pi / 180
            return CGPoint(x: cx + r * CGFloat(cos(rad)), y: cy - r * CGFloat(sin(rad)))
        }
        func disc(_ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)) }

        // 반지름 비율
        let rBezel = R
        let rDial  = R * 0.84
        let rZodOut = R * 0.81
        let rZodIn  = R * 0.62
        let rGlyph  = R * 0.715
        let rPlanet = R * 0.50
        let rHub    = R * 0.085

        // 1) 외곽 드롭 섀도 (입체)
        ctx.fill(disc(rBezel + R * 0.012),
                 with: .radialGradient(Gradient(colors: [.black.opacity(0.0), .black.opacity(0.32)]),
                                       center: CGPoint(x: cx, y: cy + R * 0.03),
                                       startRadius: rBezel * 0.9, endRadius: rBezel + R * 0.05))

        // 2) 메탈 베젤 — 코닉 그라데이션(머신드 사틴)
        let metal = Gradient(stops: [
            .init(color: bezelLight, location: 0.00), .init(color: bezelDark, location: 0.13),
            .init(color: bezelMid,   location: 0.27), .init(color: bezelLight, location: 0.40),
            .init(color: bezelDark,  location: 0.55), .init(color: bezelMid,  location: 0.68),
            .init(color: bezelLight, location: 0.82), .init(color: bezelDark, location: 0.95),
            .init(color: bezelLight, location: 1.00),
        ])
        ctx.fill(disc(rBezel), with: .conicGradient(metal, center: CGPoint(x: cx, y: cy), angle: .degrees(-55)))
        // 베젤 하이라이트/섀도 림
        ctx.stroke(disc(rBezel - 0.5), with: .color(.white.opacity(0.10 * appear)), lineWidth: 1)
        ctx.stroke(disc(rDial + (rBezel - rDial) * 0.5), with: .color(.black.opacity(0.25)), lineWidth: max(1, (rBezel - rDial) * 0.16))

        // 3) 브라스 인레이 링
        ctx.stroke(disc(rDial + R * 0.022), with: .color(brassSoft.opacity(appear)), lineWidth: R * 0.012)
        ctx.stroke(disc(rDial + R * 0.012), with: .color(brass.opacity(appear)), lineWidth: R * 0.006)

        // 4) 다이얼 면 — 따뜻한 아이보리 라디얼
        ctx.fill(disc(rDial),
                 with: .radialGradient(Gradient(colors: [dialHi, dialLo]),
                                       center: CGPoint(x: cx - rDial * 0.18, y: cy - rDial * 0.22),
                                       startRadius: 0, endRadius: rDial * 1.15))
        // 다이얼 내측 음영(오목감)
        ctx.stroke(disc(rDial - 1), with: .color(brassSoft.opacity(0.25)), lineWidth: 1.5)

        // 5) 챕터링 — 음각 눈금 (5°마다, 사인 경계 30°는 길게)
        let rotForRing = ringRot
        for k in 0..<72 {
            let lon = Double(k) * 5
            let a = lonToAngle(lon, rotForRing)
            let major = (k % 6 == 0)
            let p0 = pt(a, rZodOut)
            let p1 = pt(a, rZodOut - R * (major ? 0.055 : 0.028))
            var tk = Path(); tk.move(to: p0); tk.addLine(to: p1)
            ctx.stroke(tk, with: .color(tickInk.opacity((major ? 0.85 : 0.5) * appear)),
                       lineWidth: major ? 1.6 : 0.8)
        }
        ctx.stroke(disc(rZodOut), with: .color(tickInk.opacity(0.35 * appear)), lineWidth: 0.8)
        ctx.stroke(disc(rZodIn), with: .color(tickInk.opacity(0.30 * appear)), lineWidth: 0.8)

        // 6) 별자리 글리프 (음각 톤, 각 사인 중앙)
        for i in 0..<12 {
            let mid = lonToAngle(Double(i) * 30 + 15, rotForRing)
            ctx.opacity = appear
            ctx.draw(Text(signGlyphs[i]).font(.system(size: side * 0.044, weight: .medium)).foregroundColor(ink.opacity(0.85)),
                     at: pt(mid, rGlyph))
            ctx.opacity = 1
        }

        // 7) 하우스 라인 (가는 음각)
        for h in chart.houses {
            let a = lonToAngle(h.cuspLongitude, rotForRing)
            let angular = [1, 4, 7, 10].contains(h.number)
            var ln = Path(); ln.move(to: pt(a, rHub * 1.2)); ln.addLine(to: pt(a, rZodIn))
            ctx.stroke(ln, with: .color(tickInk.opacity((angular ? 0.45 : 0.18) * appear)),
                       lineWidth: angular ? 1.1 : 0.5)
        }

        // 8) 유리 돔 반사 (상단 좌측 하이라이트) — 다이얼에 클립
        var glass = ctx
        glass.clip(to: disc(rDial))
        let hi = Path(ellipseIn: CGRect(x: cx - rDial * 1.0, y: cy - rDial * 1.25,
                                        width: rDial * 1.7, height: rDial * 1.25))
        glass.fill(hi, with: .radialGradient(Gradient(colors: [.white.opacity(0.22 * appear), .white.opacity(0)]),
                                             center: CGPoint(x: cx - rDial * 0.25, y: cy - rDial * 0.55),
                                             startRadius: 0, endRadius: rDial * 0.95))

        // 9) 어스펙트 라인 (중앙, 가늘게) — sweep로 페이드
        let byId = Dictionary(uniqueKeysWithValues: chart.planets.map { ($0.id, $0.longitude) })
        for asp in chart.aspects.prefix(16) {
            guard let l1 = byId[asp.planet1], let l2 = byId[asp.planet2] else { continue }
            let st = aspectColor(asp.type)
            var ln = Path()
            ln.move(to: pt(lonToAngle(l1, rotForRing + bodyRot), rPlanet * 0.86))
            ln.addLine(to: pt(lonToAngle(l2, rotForRing + bodyRot), rPlanet * 0.86))
            ctx.stroke(ln, with: .color(st.opacity(0.30 * sweep)), style: StrokeStyle(lineWidth: 0.7, dash: st == oxblood ? [] : [3, 2.5]))
        }

        // 10) 행성 마커 — 충돌 분산 + sweep 정착
        var items = chart.planets.map { (id: $0.id, deg: lonToAngle($0.longitude, rotForRing + bodyRot), retro: $0.isRetrograde) }
        items.sort { $0.deg < $1.deg }
        let minGap = 9.0
        if items.count > 1 {
            for i in 1..<items.count where items[i].deg - items[i - 1].deg < minGap {
                items[i].deg = items[i - 1].deg + minGap
            }
        }
        let mScale = 0.5 + 0.5 * sweep
        for it in items {
            // 연결 틱(별자리 띠 → 마커)
            var conn = Path(); conn.move(to: pt(it.deg, rZodIn)); conn.addLine(to: pt(it.deg, rPlanet + R * 0.05))
            ctx.stroke(conn, with: .color(brassSoft.opacity(0.5 * sweep)), lineWidth: 0.6)
            let c = pt(it.deg, rPlanet)
            let mr = R * 0.052 * mScale
            // 마커 디스크(브라스 림 + 크림)
            ctx.fill(disc2(c, mr + 1.2), with: .color(brassSoft.opacity(sweep)))
            ctx.fill(disc2(c, mr), with: .radialGradient(Gradient(colors: [dialHi, dialLo]),
                                                         center: CGPoint(x: c.x - mr * 0.3, y: c.y - mr * 0.3),
                                                         startRadius: 0, endRadius: mr * 1.3))
            ctx.opacity = sweep
            ctx.draw(Text(planetGlyph[it.id] ?? "•").font(.system(size: side * 0.044 * mScale, weight: .semibold)).foregroundColor(ink),
                     at: c)
            ctx.opacity = 1
            if it.retro {
                ctx.draw(Text("℞").font(.system(size: side * 0.022, weight: .bold)).foregroundColor(oxblood.opacity(sweep)),
                         at: CGPoint(x: c.x + mr * 1.1, y: c.y - mr * 1.1))
            }
        }

        // 11) ASC / MC 바늘 — 옥스블러드/그래파이트, sweep 스윕
        if let ang = chart.angles {
            drawNeedle(ctx, cx: cx, cy: cy, pt: pt,
                       angle: lonToAngle(ang.mc.longitude, rotForRing + bodyRot),
                       length: rZodIn, width: R * 0.018, color: Color(hex: 0x3A3833), opacity: sweep, tail: rHub * 1.6)
            drawNeedle(ctx, cx: cx, cy: cy, pt: pt,
                       angle: lonToAngle(ang.asc.longitude, rotForRing + bodyRot),
                       length: rZodIn, width: R * 0.024, color: oxblood, opacity: sweep, tail: rHub * 2.0)
            // 축 라벨
            for (lon, label, col) in [(ang.asc.longitude, "ASC", oxblood), (ang.mc.longitude, "MC", Color(hex: 0x4A463E))] {
                let a = lonToAngle(lon, rotForRing)
                ctx.opacity = appear
                ctx.draw(Text(label).font(.system(size: side * 0.028, weight: .heavy)).foregroundColor(col),
                         at: pt(a, rDial + (rBezel - rDial) * 0.5))
                ctx.opacity = 1
            }
        }

        // 12) 중앙 허브 — 메탈 캡 + 브라스 림 + 주얼
        ctx.fill(disc(rHub + 2), with: .color(.black.opacity(0.25)))
        ctx.fill(disc(rHub), with: .radialGradient(Gradient(colors: [Color(hex: 0x6A665E), Color(hex: 0x26241F)]),
                                                   center: CGPoint(x: cx - rHub * 0.3, y: cy - rHub * 0.3),
                                                   startRadius: 0, endRadius: rHub * 1.4))
        ctx.stroke(disc(rHub), with: .color(brass.opacity(0.9)), lineWidth: 1.2)
        ctx.fill(disc(rHub * 0.34), with: .color(oxblood.opacity(0.9 * sweep)))
    }

    private func disc2(_ c: CGPoint, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }

    private func drawNeedle(_ ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                            pt: (Double, CGFloat) -> CGPoint, angle: Double,
                            length: CGFloat, width: CGFloat, color: Color, opacity: Double, tail: CGFloat) {
        let tip = pt(angle, length)
        let baseL = pt(angle + 90, width)
        let baseR = pt(angle - 90, width)
        let tailEnd = pt(angle + 180, tail)
        var p = Path()
        p.move(to: tip); p.addLine(to: baseL); p.addLine(to: tailEnd); p.addLine(to: baseR); p.closeSubpath()
        ctx.fill(p, with: .color(color.opacity(opacity)))
        // 바늘 하이라이트
        var hl = Path(); hl.move(to: tip); hl.addLine(to: cxcy(cx, cy))
        ctx.stroke(hl, with: .color(.white.opacity(0.18 * opacity)), lineWidth: 0.7)
    }
    private func cxcy(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private func aspectColor(_ type: String) -> Color {
        switch type {
        case "conjunction": return Color(hex: 0x9A7BC0)
        case "sextile":     return Color(hex: 0x4E9A6B)
        case "trine":       return Color(hex: 0x4A7CB0)
        case "square":      return oxblood
        case "opposition":  return Color(hex: 0xC2772E)
        default:            return Color(hex: 0x8A8276)
        }
    }
}
