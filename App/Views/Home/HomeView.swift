// 홈 — 일일운세 (메인 시안 정밀 일치)
// 헤더 / 달빛 편지 히어로(토끼 우측 가득 + 시적 글귀 + 행운지수) /
// 행운 아이템 5개 개별 카드 / 운세 컨디션 5개 카드 / 달토끼의 한마디 CTA

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
                    VStack(spacing: 26) {
                        heroBanner(bundle)
                        luckyItemsSection(bundle)
                        conditionSection(bundle)
                        ctaBanner(bundle)
                    }
                    .padding(.horizontal, DT.pagePadding)
                    .padding(.top, 6)
                    .padding(.bottom, 18)
                }
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

    // MARK: - 헤더 (햄버거 + 로고 + 메일 숫자뱃지 + 캘린더)

    private var header: some View {
        HStack(spacing: 0) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(DT.ink)
            Spacer()
            Text("DAL TOKKIE")
                .font(DT.serif(22, .bold))
                .tracking(2.5)
                .foregroundStyle(DT.ink)
            Spacer()
            HStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "envelope")
                        .font(.system(size: 21, weight: .light))
                        .foregroundStyle(DT.ink)
                    Text("6")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 15, height: 15)
                        .background(DT.accent)
                        .clipShape(Circle())
                        .offset(x: 7, y: -7)
                }
                Image(systemName: "calendar")
                    .font(.system(size: 21, weight: .light))
                    .foregroundStyle(DT.ink)
            }
        }
        .padding(.horizontal, DT.pagePadding)
        .padding(.vertical, 14)
        .background(DT.bg)
    }

    // MARK: - 히어로 (오늘의 달빛 편지) — 토끼 우측 가득 + 코너 프레임

    private func heroBanner(_ bundle: DailyFortuneBundle) -> some View {
        let letter = MoonLetters.of(score: bundle.today.overallScore, dateSeed: dateSeed(bundle.today.date))
        return ZStack(alignment: .bottomTrailing) {
            // 토끼 일러스트 — 우측, 책/찻잔이 배너 하단까지
            Image("moon-rabbit")
                .resizable()
                .scaledToFit()
                .frame(width: 245)
                .padding(.trailing, -10)
                .padding(.bottom, -2)

            VStack(alignment: .leading, spacing: 0) {
                // 날짜
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(dateMD(bundle.today.date))
                        .font(DT.sans(34, .bold))
                        .foregroundStyle(DT.ink)
                    Text(weekday(bundle.today.date))
                        .font(DT.sans(14, .semibold))
                        .foregroundStyle(DT.inkSoft)
                }
                HStack(spacing: 4) {
                    Text("오늘의 달빛 편지")
                        .font(DT.serif(14, .semibold))
                        .foregroundStyle(DT.inkSoft)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0xE0B450))
                }
                .padding(.top, 3)

                Text(letter.title)
                    .font(DT.serif(24, .bold))
                    .foregroundStyle(DT.ink)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 22)

                Text(letter.body)
                    .font(DT.sans(13))
                    .foregroundStyle(DT.inkSoft)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)

                Divider()
                    .frame(width: 130)
                    .padding(.top, 18)

                Text("오늘의 행운지수")
                    .font(DT.serif(13, .semibold))
                    .foregroundStyle(DT.inkSoft)
                    .padding(.top, 14)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(bundle.today.overallScore)")
                        .font(DT.sans(40, .bold))
                        .foregroundStyle(DT.ink)
                    Text("점")
                        .font(DT.sans(15))
                        .foregroundStyle(DT.inkSoft)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(trendText(bundle))
                            .font(DT.sans(11, .semibold))
                            .foregroundStyle(DT.accent)
                        if bundle.today.overallScore >= 65 {
                            Text("이번 주 최고예요!")
                                .font(DT.sans(11, .semibold))
                                .foregroundStyle(DT.accent)
                        }
                    }
                    .padding(.leading, 4)
                }
                .padding(.top, 3)

                Button {
                    showLuckyDetail = true
                } label: {
                    HStack(spacing: 4) {
                        Text("자세히 보기")
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                    }
                    .font(DT.sans(13, .semibold))
                    .foregroundStyle(DT.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(DT.accentSoft)
                    .clipShape(Capsule())
                }
                .padding(.top, 16)
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
                    let len: CGFloat = 18
                    let inset: CGFloat = 9
                    Path { p in
                        let w = geo.size.width, h = geo.size.height
                        for (cx, cy, dx, dy) in [
                            (inset, inset, 1.0, 1.0), (w - inset, inset, -1.0, 1.0),
                            (inset, h - inset, 1.0, -1.0), (w - inset, h - inset, -1.0, -1.0),
                        ] {
                            p.move(to: CGPoint(x: cx, y: cy + dy * len))
                            p.addLine(to: CGPoint(x: cx, y: cy))
                            p.addLine(to: CGPoint(x: cx + dx * len, y: cy))
                        }
                    }
                    .stroke(DT.strokeBrown.opacity(0.55), lineWidth: 1.3)
                }
            )
    }

    // MARK: - 행운 아이템 (5개 개별 카드 + 큰 일러스트)

    private func luckyItemsSection(_ bundle: DailyFortuneBundle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "clover.fill").font(.system(size: 14)).foregroundStyle(Color(hex: 0x8FB996))
                Text("오늘의 행운 아이템")
                    .font(DT.serif(17, .bold))
                    .foregroundStyle(DT.ink)
                Button { withAnimation { showYongsinInfo.toggle() } } label: {
                    Image(systemName: "info.circle").font(.system(size: 12)).foregroundStyle(DT.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(DT.inkSoft)
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

            HStack(spacing: 8) {
                luckyCard("컬러", bundle.luckyItems.color,
                          LuckyAssets.colorAsset(bundle.luckyItems.color), "paintpalette.fill")
                luckyCard("음료", bundle.luckyItems.drink,
                          LuckyAssets.itemAsset(category: .drink), "cup.and.saucer.fill")
                luckyCard("장소", bundle.luckyItems.place,
                          LuckyAssets.placeAsset(bundle.luckyItems.place), "mappin.and.ellipse")
                luckyCard("향기", bundle.luckyItems.scent,
                          LuckyAssets.itemAsset(category: .scent), "leaf.fill")
                luckyCard("아이템", bundle.luckyItems.item,
                          LuckyAssets.itemAsset(category: .item), "gift.fill")
            }
        }
    }

    private func luckyCard(_ label: String, _ value: String, _ asset: String?, _ fallback: String) -> some View {
        VStack(spacing: 10) {
            Text(label)
                .font(DT.sans(12, .semibold))
                .foregroundStyle(DT.ink)
            LuckyIconView(assetName: asset, fallbackSymbol: fallback, size: 50)
            Text(value)
                .font(DT.sans(10, .medium))
                .foregroundStyle(DT.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 1)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == 0 ? DT.accent : DT.line)
                        .frame(width: 3.5, height: 3.5)
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DT.line, lineWidth: 1))
    }

    // MARK: - 운세 컨디션 (5개 카드)

    private func conditionSection(_ bundle: DailyFortuneBundle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "clover.fill").font(.system(size: 14)).foregroundStyle(Color(hex: 0xB39DC9))
                Text("오늘의 운세 컨디션")
                    .font(DT.serif(17, .bold))
                    .foregroundStyle(DT.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(DT.inkSoft)
            }
            HStack(spacing: 8) {
                ForEach(HomeConditions.from(cards: bundle.today.cards), id: \.title) { item in
                    ConditionCard(item: item)
                }
            }
        }
    }

    // MARK: - CTA (달토끼의 한마디 + 별/꽃 장식)

    private func ctaBanner(_ bundle: DailyFortuneBundle) -> some View {
        Button {
            appState.selectedTab = .talisman
        } label: {
            ZStack {
                // 배경 장식 (별)
                GeometryReader { geo in
                    ForEach(0..<14, id: \.self) { i in
                        Image(systemName: i % 3 == 0 ? "sparkle" : "star.fill")
                            .font(.system(size: CGFloat(4 + (i * 7) % 6)))
                            .foregroundStyle(Color(hex: 0xF5D78A).opacity(0.35))
                            .position(
                                x: geo.size.width * CGFloat((i * 37) % 100) / 100,
                                y: geo.size.height * CGFloat((i * 53) % 100) / 100
                            )
                    }
                }
                // 우측 부적 태그 장식
                HStack {
                    Spacer()
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.white.opacity(0.12))
                        .padding(.trailing, 14)
                }
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("달토끼의 한마디")
                            .font(DT.serif(14, .bold))
                            .foregroundStyle(Color(hex: 0xF5D78A))
                        Text("당신의 하루가 빛나길,\n늘 달빛이 함께할게요.")
                            .font(DT.sans(12))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    HStack(spacing: 4) {
                        Text("오늘의 부적 보기")
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(DT.sans(12, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(DT.accent)
                    .clipShape(Capsule())
                    .fixedSize()
                }
                .padding(.horizontal, 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x3A3563), DT.night, Color(hex: 0x463B5C)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - 유틸

    private func dateMD(_ d: String) -> String {
        let p = d.split(separator: "-")
        guard p.count == 3 else { return d }
        return "\(Int(p[1]) ?? 0) / \(Int(p[2]) ?? 0)"
    }
    private func weekday(_ d: String) -> String {
        let p = d.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return "" }
        let jdn = jdnOf(p[0], p[1], p[2])
        let names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        return names[((jdn + 1) % 7 + 7) % 7]
    }
    private func jdnOf(_ y: Int, _ m: Int, _ d: Int) -> Int {
        let a = (14 - m) / 12, yy = y + 4800 - a, mm = m + 12 * a - 3
        return d + (153 * mm + 2) / 5 + 365 * yy + yy / 4 - yy / 100 + yy / 400 - 32045
    }
    private func dateSeed(_ d: String) -> Int {
        let p = d.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return 0 }
        return p[0] * 10000 + p[1] * 100 + p[2]
    }
    private func trendText(_ bundle: DailyFortuneBundle) -> String {
        guard let idx = bundle.fortunes.firstIndex(where: { $0.date == bundle.today.date }), idx > 0 else { return "" }
        let diff = bundle.today.overallScore - bundle.fortunes[idx - 1].overallScore
        if diff > 0 { return "어제보다 +\(diff)" }
        if diff < 0 { return "어제보다 \(diff)" }
        return "어제와 같아요"
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
