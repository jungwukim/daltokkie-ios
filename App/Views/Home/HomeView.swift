// 홈 — 일일운세 (메인 시안 기준 재구성)
// 헤더 / 달빛 편지 히어로(배너 내장 행운지수) / 행운 아이템 5칸(일러스트+도트) /
// 운세 컨디션 별점 카드 5개 / 달토끼의 한마디 CTA

import SwiftUI
import SajuKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showYongsinInfo = false
    @State private var showLuckyDetail = false

    var body: some View {
        let bundle = appState.ensureDailyBundle()

        VStack(spacing: 0) {
            header

            if let bundle {
                ScrollView {
                    VStack(spacing: 20) {
                        heroBanner(bundle)
                        luckyItemsSection(bundle)
                        conditionSection(bundle)
                    }
                    .padding(.horizontal, DT.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 14)
                }
                ctaBanner(bundle)
            } else {
                Spacer()
                Text("운세를 계산할 수 없어요\n\(appState.lastError ?? "")")
                    .font(DT.sans(14))
                    .foregroundStyle(DT.inkSoft)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .sheet(isPresented: $showLuckyDetail) {
            if let bundle { LuckyIndexDetailView(bundle: bundle) }
        }
    }

    // MARK: - 헤더 (햄버거 + 로고 + 메일뱃지 + 캘린더)

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DT.ink)
            Spacer()
            Text("DAL TOKKIE")
                .font(DT.serif(20, .bold))
                .tracking(2)
                .foregroundStyle(DT.ink)
            Spacer()
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "envelope")
                        .font(.system(size: 19))
                        .foregroundStyle(DT.ink)
                    Circle()
                        .fill(DT.accent)
                        .frame(width: 7, height: 7)
                        .offset(x: 3, y: -2)
                }
                Image(systemName: "calendar")
                    .font(.system(size: 19))
                    .foregroundStyle(DT.ink)
            }
        }
        .padding(.horizontal, DT.pagePadding)
        .padding(.vertical, 12)
        .background(DT.bg)
    }

    // MARK: - 히어로 (오늘의 달빛 편지) — 코너 프레임 + 토끼 + 행운지수 내장

    private func heroBanner(_ bundle: DailyFortuneBundle) -> some View {
        ZStack(alignment: .topTrailing) {
            // 토끼 일러스트 (배경 창문 합성본) — 우측
            Image("moon-rabbit")
                .resizable()
                .scaledToFit()
                .frame(height: 270)
                .offset(x: 30, y: -6)

            VStack(alignment: .leading, spacing: 0) {
                // 날짜 + 달빛 편지
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(dateMD(bundle.today.date))
                        .font(DT.sans(30, .bold))
                        .foregroundStyle(DT.ink)
                    Text(weekday(bundle.today.date))
                        .font(DT.sans(13, .semibold))
                        .foregroundStyle(DT.inkSoft)
                }
                HStack(spacing: 4) {
                    Text("오늘의 달빛 편지")
                        .font(DT.serif(13, .semibold))
                        .foregroundStyle(DT.inkSoft)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: 0xE0B450))
                }
                .padding(.top, 2)

                Text(letterTitle(bundle.today))
                    .font(DT.serif(23, .bold))
                    .foregroundStyle(DT.ink)
                    .lineSpacing(3)
                    .frame(width: 210, alignment: .leading)
                    .padding(.top, 14)

                Text(letterBody(bundle.today.fortuneSummary))
                    .font(DT.sans(12))
                    .foregroundStyle(DT.inkSoft)
                    .lineSpacing(3)
                    .frame(width: 200, alignment: .leading)
                    .padding(.top, 10)

                Divider()
                    .frame(width: 150)
                    .padding(.top, 14)

                Text("오늘의 행운지수")
                    .font(DT.serif(12, .semibold))
                    .foregroundStyle(DT.inkSoft)
                    .padding(.top, 12)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(bundle.today.overallScore)")
                        .font(DT.sans(34, .bold))
                        .foregroundStyle(DT.ink)
                    Text("점")
                        .font(DT.sans(14))
                        .foregroundStyle(DT.inkSoft)
                    Text(trendText(bundle))
                        .font(DT.sans(11, .medium))
                        .foregroundStyle(DT.accent)
                        .padding(.leading, 4)
                }
                .padding(.top, 2)

                Button {
                    showLuckyDetail = true
                } label: {
                    HStack(spacing: 3) {
                        Text("자세히 보기")
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(DT.sans(12, .semibold))
                    .foregroundStyle(DT.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(DT.accentSoft)
                    .clipShape(Capsule())
                }
                .padding(.top, 14)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(cornerFrame)
    }

    // 코너 장식 프레임 (┌ ┐ └ ┘)
    private var cornerFrame: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(DT.line, lineWidth: 1)
            .overlay(
                GeometryReader { geo in
                    let len: CGFloat = 16
                    let inset: CGFloat = 8
                    Path { p in
                        let w = geo.size.width, h = geo.size.height
                        // 4 모서리 L자
                        for (cx, cy, dx, dy) in [
                            (inset, inset, 1.0, 1.0), (w - inset, inset, -1.0, 1.0),
                            (inset, h - inset, 1.0, -1.0), (w - inset, h - inset, -1.0, -1.0),
                        ] {
                            p.move(to: CGPoint(x: cx, y: cy + dy * len))
                            p.addLine(to: CGPoint(x: cx, y: cy))
                            p.addLine(to: CGPoint(x: cx + dx * len, y: cy))
                        }
                    }
                    .stroke(DT.strokeBrown.opacity(0.6), lineWidth: 1.2)
                }
            )
    }

    // MARK: - 행운 아이템 (5칸 일러스트 + 도트)

    private func luckyItemsSection(_ bundle: DailyFortuneBundle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "leaf.fill").font(.system(size: 12)).foregroundStyle(Color(hex: 0x8FB996))
                Text("달빛처럼 스미는 행운")
                    .font(DT.serif(16, .bold))
                    .foregroundStyle(DT.ink)
                Button { withAnimation { showYongsinInfo.toggle() } } label: {
                    Image(systemName: "info.circle").font(.system(size: 12)).foregroundStyle(DT.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(DT.inkSoft)
            }

            if showYongsinInfo {
                Text("\(bundle.yongsin.strengthLabel) · 용신 \(bundle.yongsin.elementKo) — \(bundle.yongsin.description)")
                    .font(DT.sans(11))
                    .foregroundStyle(DT.inkSoft)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DT.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // 시안: 카드 하나 안에 5칸 (구분선)
            HStack(spacing: 0) {
                luckyCell("컬러", bundle.luckyItems.color,
                          LuckyAssets.colorAsset(bundle.luckyItems.color), "paintpalette.fill")
                cellDivider
                luckyCell("음료", bundle.luckyItems.drink,
                          LuckyAssets.itemAsset(category: .drink), "cup.and.saucer.fill")
                cellDivider
                luckyCell("장소", bundle.luckyItems.place,
                          LuckyAssets.placeAsset(bundle.luckyItems.place), "mappin.and.ellipse")
                cellDivider
                luckyCell("향기", bundle.luckyItems.scent,
                          LuckyAssets.itemAsset(category: .scent), "leaf.fill")
                cellDivider
                luckyCell("아이템", bundle.luckyItems.item,
                          LuckyAssets.itemAsset(category: .item), "gift.fill")
            }
            .padding(.vertical, 14)
            .background(DT.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DT.line, lineWidth: 1))
        }
    }

    private var cellDivider: some View {
        Rectangle().fill(DT.line.opacity(0.6)).frame(width: 1, height: 64)
    }

    private func luckyCell(_ label: String, _ value: String, _ asset: String?, _ fallback: String) -> some View {
        VStack(spacing: 7) {
            Text(label)
                .font(DT.sans(11, .semibold))
                .foregroundStyle(DT.ink)
            LuckyIconView(assetName: asset, fallbackSymbol: fallback, size: 42)
            Text(value)
                .font(DT.sans(9.5, .medium))
                .foregroundStyle(DT.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 2)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == 0 ? DT.accent : DT.line)
                        .frame(width: 3.5, height: 3.5)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 운세 컨디션 (별점 카드 5개)

    private func conditionSection(_ bundle: DailyFortuneBundle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "cloud.fill").font(.system(size: 12)).foregroundStyle(Color(hex: 0xB39DC9))
                Text("오늘의 운세 컨디션")
                    .font(DT.serif(16, .bold))
                    .foregroundStyle(DT.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(DT.inkSoft)
            }
            HStack(spacing: 7) {
                ForEach(HomeConditions.from(cards: bundle.today.cards), id: \.title) { item in
                    ConditionCard(item: item)
                }
            }
        }
    }

    // MARK: - CTA (달토끼의 한마디)

    private func ctaBanner(_ bundle: DailyFortuneBundle) -> some View {
        Button {
            appState.selectedTab = .talisman
        } label: {
            ZStack(alignment: .trailing) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.06))
                    .offset(x: -10)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("달토끼의 한마디")
                            .font(DT.serif(13, .bold))
                            .foregroundStyle(Color(hex: 0xF5D78A))
                        Text("당신의 하루가 빛나길,\n늘 달빛이 함께할게요.")
                            .font(DT.sans(12))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineSpacing(2)
                    }
                    Spacer()
                    HStack(spacing: 3) {
                        Text("오늘의 부적 보기")
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(DT.sans(12, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DT.accent)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x3A3563), DT.night, Color(hex: 0x4A3F5E)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, DT.pagePadding)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 유틸

    private func dateMD(_ d: String) -> String {
        let p = d.split(separator: "-")
        guard p.count == 3 else { return d }
        return "\(Int(p[1]) ?? 0)/\(Int(p[2]) ?? 0)"
    }
    private func weekday(_ d: String) -> String {
        let p = d.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return "" }
        // Zeller 없이 JDN으로 요일 (0=일)
        let jdn = jdnOf(p[0], p[1], p[2])
        let names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        return names[((jdn + 1) % 7 + 7) % 7]
    }
    private func jdnOf(_ y: Int, _ m: Int, _ d: Int) -> Int {
        let a = (14 - m) / 12, yy = y + 4800 - a, mm = m + 12 * a - 3
        return d + (153 * mm + 2) / 5 + 365 * yy + yy / 4 - yy / 100 + yy / 400 - 32045
    }
    private func trendText(_ bundle: DailyFortuneBundle) -> String {
        guard let idx = bundle.fortunes.firstIndex(where: { $0.date == bundle.today.date }), idx > 0 else { return "" }
        let diff = bundle.today.overallScore - bundle.fortunes[idx - 1].overallScore
        if diff > 0 { return "어제보다 +\(diff)" }
        if diff < 0 { return "어제보다 \(diff)" }
        return "어제와 같아요"
    }
    private func letterTitle(_ f: DailyFortuneResult) -> String {
        // fortuneSummary 첫 문장을 편지 제목으로
        let first = f.fortuneSummary.split(separator: ".").first.map(String.init) ?? f.fortuneSummary
        return first.count > 24 ? String(first.prefix(24)) + "…" : first + "."
    }
    private func letterBody(_ summary: String) -> String {
        let parts = summary.split(separator: ".", maxSplits: 1)
        guard parts.count > 1 else { return "당신의 속도가 당신을 지켜줄 거예요." }
        return parts[1].trimmingCharacters(in: .whitespaces) + "."
    }
}

// MARK: - 행운지수 자세히 보기 (배너에서 분리)

struct LuckyIndexDetailView: View {
    let bundle: DailyFortuneBundle
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    CraftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(text: "5일간 행운지수 흐름")
                            LuckyLineChart(fortunes: bundle.fortunes, todayDate: bundle.today.date)
                                .frame(height: 130)
                                .padding(.top, 8)
                            HStack {
                                ForEach(bundle.fortunes, id: \.date) { f in
                                    Text(shortDate(f.date))
                                        .font(DT.sans(10))
                                        .foregroundStyle(f.date == bundle.today.date ? DT.accent : DT.inkSoft)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "행운 시간대")
                            HStack {
                                Label(bundle.luckyHours.lucky, systemImage: "sun.max.fill")
                                    .font(DT.sans(13, .medium)).foregroundStyle(DT.accent)
                                Spacer()
                                Label(bundle.luckyHours.unlucky, systemImage: "cloud.fill")
                                    .font(DT.sans(13, .medium)).foregroundStyle(DT.inkSoft)
                            }
                        }
                    }
                }
                .padding(DT.pagePadding)
            }
            .background(DT.bg)
            .navigationTitle("오늘의 행운지수")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }

    private func shortDate(_ d: String) -> String {
        let p = d.split(separator: "-")
        guard p.count == 3 else { return d }
        return "\(Int(p[1]) ?? 0)/\(Int(p[2]) ?? 0)"
    }
}
