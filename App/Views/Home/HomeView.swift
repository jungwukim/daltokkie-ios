// 홈 — 일일운세 (웹 /mobile 홈 탭 대응)
// 히어로 배너(달빛 편지) / 행운지수 / 행운 아이템 / 운세 컨디션 / CTA

import SwiftUI
import SajuKit

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showYongsinInfo = false

    var body: some View {
        let bundle = appState.ensureDailyBundle()

        VStack(spacing: 0) {
            header

            if let bundle {
                ScrollView {
                    VStack(spacing: 18) {
                        heroBanner(bundle)
                        luckyIndexSection(bundle)
                        luckyItemsSection(bundle)
                        conditionSection(bundle)
                    }
                    .padding(.horizontal, DT.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
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
    }

    // MARK: - 헤더

    private var header: some View {
        HStack(spacing: 8) {
            Image("dal-tokkie-icon")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
            Text("DAL TOKKIE")
                .font(DT.serif(17, .bold))
                .foregroundStyle(DT.ink)
            Spacer()
            Image("carrot-icon")
                .resizable()
                .scaledToFit()
                .frame(height: 22)
        }
        .padding(.horizontal, DT.pagePadding)
        .padding(.vertical, 12)
        .background(DT.bg)
    }

    // MARK: - 히어로 배너 (오늘의 달빛 편지)

    private func heroBanner(_ bundle: DailyFortuneBundle) -> some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: DT.radius)
                .fill(DT.card)
                .overlay(RoundedRectangle(cornerRadius: DT.radius).stroke(DT.line, lineWidth: 1))

            // 토끼 일러스트 — 우측 하단, 배너 높이에 맞춤
            Image("moon-rabbit")
                .resizable()
                .scaledToFit()
                .frame(height: 230)
                .offset(x: 36, y: 0)
                .clipped()

            VStack(alignment: .leading, spacing: 7) {
                Text("오늘의 달빛 편지")
                    .font(DT.serif(13, .bold))
                    .foregroundStyle(DT.accent)
                Text(formattedDate(bundle.today.date))
                    .font(DT.sans(24, .bold))
                    .foregroundStyle(DT.ink)
                Text(bundle.today.fortuneSummary)
                    .font(DT.serif(15))
                    .foregroundStyle(DT.ink)
                    .lineSpacing(4)
                    .frame(width: 190, alignment: .leading)
                    .lineLimit(7)
                Spacer(minLength: 4)
                Text("오늘의 행운지수")
                    .font(DT.serif(13, .bold))
                    .foregroundStyle(DT.accent)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(bundle.today.overallScore)")
                        .font(DT.sans(34, .bold))
                        .foregroundStyle(DT.ink)
                    Text("점 · \(bundle.today.overallGrade)")
                        .font(DT.sans(13))
                        .foregroundStyle(DT.inkSoft)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 250)
        .clipShape(RoundedRectangle(cornerRadius: DT.radius))
    }

    // MARK: - 행운지수 차트

    private func luckyIndexSection(_ bundle: DailyFortuneBundle) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "행운지수 흐름")
                LuckyLineChart(fortunes: bundle.fortunes, todayDate: bundle.today.date)
                    .frame(height: 120)
                    .padding(.top, 8)
                HStack {
                    ForEach(bundle.fortunes, id: \.date) { f in
                        Text(shortDate(f.date))
                            .font(DT.sans(10))
                            .foregroundStyle(f.date == bundle.today.date ? DT.accent : DT.inkSoft)
                            .frame(maxWidth: .infinity)
                    }
                }
                HStack(spacing: 12) {
                    Label(bundle.luckyHours.lucky, systemImage: "sun.max.fill")
                        .font(DT.sans(11, .medium))
                        .foregroundStyle(DT.accent)
                    Label(bundle.luckyHours.unlucky, systemImage: "cloud.fill")
                        .font(DT.sans(11, .medium))
                        .foregroundStyle(DT.inkSoft)
                    Spacer()
                }
            }
        }
    }

    // MARK: - 행운 아이템

    private func luckyItemsSection(_ bundle: DailyFortuneBundle) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    SectionTitle(text: "오늘의 행운 아이템")
                    Button {
                        withAnimation { showYongsinInfo.toggle() }
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(DT.inkSoft)
                    }
                    Spacer()
                    Text(bundle.luckyItems.elementKo)
                        .font(DT.sans(11, .bold))
                        .foregroundStyle(DT.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DT.accentSoft)
                        .clipShape(Capsule())
                }

                if showYongsinInfo {
                    Text("\(bundle.yongsin.strengthLabel) · \(bundle.yongsin.description)")
                        .font(DT.sans(12))
                        .foregroundStyle(DT.inkSoft)
                        .padding(10)
                        .background(DT.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                HStack(spacing: 0) {
                    luckyCell("색깔", bundle.luckyItems.color, "paintpalette.fill")
                    luckyCell("음료", bundle.luckyItems.drink, "cup.and.saucer.fill")
                    luckyCell("장소", bundle.luckyItems.place, "mappin.and.ellipse")
                    luckyCell("향기", bundle.luckyItems.scent, "leaf.fill")
                    luckyCell("아이템", bundle.luckyItems.item, "gift.fill")
                }
            }
        }
    }

    private func luckyCell(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DT.accent)
                .frame(height: 24)
            Text(label)
                .font(DT.sans(10))
                .foregroundStyle(DT.inkSoft)
            Text(value)
                .font(DT.sans(10, .semibold))
                .foregroundStyle(DT.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 운세 컨디션

    private func conditionSection(_ bundle: DailyFortuneBundle) -> some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionTitle(text: "오늘의 운세 컨디션")
                HStack(spacing: 10) {
                    FortuneRadarChart(cards: Array(bundle.today.cards.prefix(5)))
                        .frame(height: 150)
                    FortuneRadarChart(cards: Array(bundle.today.cards.suffix(5)))
                        .frame(height: 150)
                }
                FortuneBarChart(cards: bundle.today.cards)
            }
        }
    }

    // MARK: - CTA 배너

    private func ctaBanner(_ bundle: DailyFortuneBundle) -> some View {
        Button {
            appState.selectedTab = .fortune
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(Color(hex: 0xF5D78A))
                VStack(alignment: .leading, spacing: 2) {
                    Text("달토끼의 한마디")
                        .font(DT.sans(11, .semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Text("사주팔자 전체 풀이 보러 가기")
                        .font(DT.sans(14, .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DT.night)
            .clipShape(RoundedRectangle(cornerRadius: DT.radius))
            .padding(.horizontal, DT.pagePadding)
            .padding(.vertical, 8)
        }
    }

    // MARK: - 유틸

    private func formattedDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        return "\(Int(parts[1]) ?? 0)월 \(Int(parts[2]) ?? 0)일"
    }

    private func shortDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3 else { return dateStr }
        return "\(Int(parts[1]) ?? 0)/\(Int(parts[2]) ?? 0)"
    }
}
