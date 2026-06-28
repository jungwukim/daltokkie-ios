// 홈 — 일일운세 (메인 시안 정밀 일치)
// 헤더 / 달빛 편지 히어로(토끼 우측 가득 + 시적 글귀 + 행운지수) /
// 행운 아이템 5개 개별 카드 / 운세 컨디션 5개 카드 / 달토끼의 한마디 CTA

import SwiftUI
import SajuKit
import TipKit

/// 주간 페이저 코치마크 (첫 진입 1회)
struct WeeklyPagerTip: Tip {
    var title: Text { Text("요일별 운세") }
    var message: Text? { Text("좌우로 넘기면 이번 주 다른 날의 운세를 볼 수 있어요") }
    var image: Image? { Image(systemName: "hand.draw") }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    private let weeklyTip = WeeklyPagerTip()
    @State private var showYongsinInfo = false
    @State private var showLuckyDetail = false
    @State private var showCtaBanner = true   // 세션 한정 — X로 닫으면 앱 재실행 전까지 숨김
    @State private var selectedDayIndex: Int? = nil   // 주간 카드 페이징 (nil=오늘)
    @State private var showLuckyItemsDetail = false
    @State private var showConditionsDetail = false
    @State private var showAILetter = false
    @State private var showCalendar = false
    @State private var aiDay: DailyFortuneResult?
    private let heroHeight: CGFloat = 282

    var body: some View {
        let bundle = appState.ensureDailyBundle()

        VStack(spacing: 0) {
            header

            if let bundle {
                let todayIndex = bundle.fortunes.firstIndex { $0.date == bundle.today.date } ?? 0
                let sel = min(max(selectedDayIndex ?? todayIndex, 0), max(0, bundle.fortunes.count - 1))
                ScrollView {
                    VStack(spacing: 26) {
                        heroPager(bundle)
                        luckyItemsSection(bundle, sel)
                        conditionSection(bundle, sel)
                    }
                    .padding(.horizontal, DT.pagePadding)
                    .padding(.top, 6)
                    // 떠 있는 CTA 배너에 마지막 카드가 가리지 않도록 하단 여백 확보
                    .padding(.bottom, showCtaBanner ? 104 : 18)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .refreshable { appState.refresh() }
                .task(id: bundle.today.date) { appState.ensureHeroLines() }
            } else {
                ContentUnavailableView {
                    Label("운세를 불러올 수 없어요", systemImage: "moon.zzz")
                } description: {
                    Text(appState.lastError?.isEmpty == false ? appState.lastError! : "잠시 후 다시 시도해 주세요.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 탭바 위에 떠 있는 CTA 배너 레이어 (홈 탭 한정)
        .overlay(alignment: .bottom) {
            if showCtaBanner, let bundle {
                floatingCtaBanner(bundle)
            }
        }
        .fullScreenCover(isPresented: $showCalendar) {
            FortuneCalendarView().environmentObject(appState)
        }
        .sheet(isPresented: $showLuckyDetail) {
            if let bundle { LuckyIndexDetailView(bundle: bundle) }
        }
        .sheet(isPresented: $showAILetter) {
            if let bundle {
                let aiDay = aiDay ?? bundle.today
                AILetterSheet(
                    day: aiDay,
                    dayLabel: aiDay.date == bundle.today.date ? "오늘" : weekdayKo(aiDay.date),
                    weekday: weekdayKo(aiDay.date),
                    natalDayStem: bundle.saju.raw.day.stem,
                    natalDayBranch: bundle.saju.raw.day.branch,
                    gender: bundle.saju.gender,
                    birthYear: appState.profile?.year ?? 0,
                    region: appState.profile?.region ?? "서울"
                )
            }
        }
    }

    // MARK: - 헤더 (햄버거 + 로고 + 메일 숫자뱃지 + 캘린더)

    private var header: some View {
        ZStack {
            // 타이틀 — 좌우 아이콘 폭과 무관하게 화면 기준 정중앙 고정
            Text("DAL TOKKIE")
                .font(DT.sans(24, .bold))
                .tracking(0.5)
                .foregroundStyle(DT.ink)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 0) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(DT.ink)
                Spacer()
                HStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        Image("carrot-icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("6")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 15, height: 15)
                            .background(DT.accent)
                            .clipShape(Circle())
                            .offset(x: 7, y: -7)
                    }
                    Button { showCalendar = true } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 21, weight: .light))
                            .foregroundStyle(DT.ink)
                    }
                }
            }
        }
        .padding(.horizontal, DT.pagePadding)
        .padding(.vertical, 14)
        // 상단 바 — 라이트=흰색 / 다크=짙은 톤, 상태바 영역(상단 세이프에어리어)까지 함께 채움
        .background(DT.topBar, ignoresSafeAreaEdges: .top)
    }

    // MARK: - 히어로 (오늘의 달빛 편지) — 토끼 우측 가득 + 코너 프레임

    private func heroBanner(_ day: DailyFortuneResult, _ index: Int, _ bundle: DailyFortuneBundle) -> some View {
        let isToday = (day.date == bundle.today.date)
        // 주간 7일치 AI 한 줄(캐시) 우선, 없으면 규칙 기반 요약으로 폴백
        let letter = appState.heroLines[day.date] ?? MoonLetters.summary(from: day)
        let dayLabel = isToday ? "오늘" : weekdayKo(day.date)
        return ZStack(alignment: .bottomTrailing) {
            // 좌측 텍스트가 ZStack 폭을 결정 — 토끼는 overlay로 우측에 (폭 안 늘림)
            VStack(alignment: .leading, spacing: 0) {
                // 날짜 + 달빛 편지(우측 같은 라인 — 한 줄 절약)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(dateMD(day.date))
                        .font(DT.sans(30, .bold))
                        .foregroundStyle(DT.ink)
                    Text(weekday(day.date))
                        .font(DT.sans(14, .semibold))
                        .foregroundStyle(DT.inkSoft)
                    Spacer(minLength: 8)
                    Button {
                        aiDay = day
                        showAILetter = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("\(dayLabel)의 달빛 편지")
                                .font(DT.serif(13, .semibold))
                                .foregroundStyle(DT.inkSoft)
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                                .foregroundStyle(DT.accent)
                        }
                    }
                }

                Text(letter.title)
                    .font(DT.serif(20, .bold))
                    .foregroundStyle(DT.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: 300, alignment: .leading)   // 한 줄로 가로로 길게
                    .padding(.top, 12)

                Text(letter.body)
                    .font(DT.sans(13))
                    .foregroundStyle(DT.inkSoft)
                    .lineSpacing(4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)   // AI 한 줄 길이 편차 흡수 (항상 2줄로 고정)
                    .frame(maxWidth: 215, alignment: .leading)
                    .padding(.top, 10)

                Divider()
                    .frame(width: 130)
                    .padding(.top, 12)

                Text("\(dayLabel)의 행운지수")
                    .font(DT.serif(13, .semibold))
                    .foregroundStyle(DT.inkSoft)
                    .padding(.top, 10)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(day.overallScore)")
                        .font(DT.sans(32, .bold))
                        .foregroundStyle(DT.ink)
                    Text("점")
                        .font(DT.sans(15))
                        .foregroundStyle(DT.inkSoft)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(trendText(bundle, index))
                            .font(DT.sans(11, .semibold))
                            .foregroundStyle(DT.accent)
                        if day.overallScore >= 65 {
                            Text("기운이 좋은 흐름")
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
                    HStack(spacing: 3) {
                        Text("자세히 보기")
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                    }
                    .font(DT.sans(11, .semibold))
                    .foregroundStyle(DT.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DT.accentSoft)
                    .clipShape(Capsule())
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: heroHeight)   // 모든 요일 카드 높이 통일 → 페이저 정렬·꺾쇠 테두리 일관
        .background(DT.card)
        .overlay(alignment: .bottomTrailing) {
            // 토끼 — overlay라 히어로 폭에 영향 안 줌 (clipShape로 경계 안에 가둠)
            Image("moon-rabbit")
                .resizable()
                .scaledToFit()
                .frame(width: 150)
                .offset(x: 4, y: 18)   // 아래로 내려 토끼 밑선이 박스 하단에 클립되게
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(cornerFrame)
    }

    // MARK: - 주간 페이저 (월~일 7장) + 요일 점 인디케이터

    private func heroPager(_ bundle: DailyFortuneBundle) -> some View {
        let todayIndex = bundle.fortunes.firstIndex { $0.date == bundle.today.date } ?? 0
        let selection = Binding<Int>(
            get: { selectedDayIndex ?? todayIndex },
            set: { selectedDayIndex = $0 }
        )
        return VStack(spacing: 12) {
            TabView(selection: selection) {
                ForEach(Array(bundle.fortunes.enumerated()), id: \.offset) { idx, day in
                    heroBanner(day, idx, bundle)
                        .padding(.horizontal, 7)   // 캐러셀 시 카드 사이 간격
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: heroHeight)
            .padding(.horizontal, -7)   // 페이지 여백만큼 TabView를 넓혀 카드 본체 폭 유지
            .sensoryFeedback(.selection, trigger: selection.wrappedValue)

            weekDots(count: bundle.fortunes.count, todayIndex: todayIndex, selected: selection.wrappedValue)
                .popoverTip(weeklyTip)
        }
    }

    /// 7개 점 — 오늘 요일은 다른 색, 현재 보는 페이지는 길쭉한 캡슐로 표시
    private func weekDots(count: Int, todayIndex: Int, selected: Int) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                let isToday = (i == todayIndex)
                let isSelected = (i == selected)
                Capsule()
                    .fill(isSelected
                          ? (isToday ? DT.accent : DT.inkSoft)
                          : (isToday ? DT.accent : DT.line))
                    .frame(width: isSelected ? 16 : 6, height: 6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selected)
            }
        }
    }

    // 카드 테두리 (코너 꺾쇠 장식은 제거됨)
    private var cornerFrame: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(DT.line, lineWidth: 1)
    }

    // MARK: - 행운 아이템 (5개 개별 카드 + 큰 일러스트)

    private func luckyItemsSection(_ bundle: DailyFortuneBundle, _ index: Int) -> some View {
        let lucky = bundle.fortunesLucky.indices.contains(index) ? bundle.fortunesLucky[index] : bundle.luckyItems
        let dayLabel = bundle.fortunes.indices.contains(index) && bundle.fortunes[index].date == bundle.today.date
            ? "오늘" : (bundle.fortunes.indices.contains(index) ? weekdayKo(bundle.fortunes[index].date) : "오늘")
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "clover.fill").font(.system(size: 14)).foregroundStyle(Color(hex: 0x8FB996))
                Text("오늘의 행운 아이템")
                    .font(DT.serif(17, .bold))
                    .foregroundStyle(DT.ink)
                Button { withAnimation { showYongsinInfo.toggle() } } label: {
                    Image(systemName: "info.circle").font(.system(size: 12)).foregroundStyle(DT.inkSoft)
                }
                Spacer()
                Button { showLuckyItemsDetail = true } label: {
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(DT.inkSoft)
                }
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
                luckyCard("컬러", lucky.color,
                          LuckyAssets.colorOrb(lucky.color)
                          ?? LuckyAssets.colorAsset(lucky.color), "paintpalette.fill")
                luckyCard("음료", lucky.drink,
                          LuckyAssets.drinkAsset(lucky.drink), "cup.and.saucer.fill")
                luckyCard("장소", lucky.place,
                          LuckyAssets.placeAsset(lucky.place), "mappin.and.ellipse")
                luckyCard("향기", lucky.scent,
                          LuckyAssets.scentAsset(lucky.scent), "leaf.fill")
                luckyCard("아이템", lucky.item,
                          LuckyAssets.luckyItemAsset(lucky.item), "gift.fill")
            }
        }
        .sheet(isPresented: $showLuckyItemsDetail) {
            LuckyItemsDetailView(lucky: lucky, yongsin: bundle.yongsin, dayLabel: dayLabel)
        }
    }

    private func luckyCard(_ label: String, _ value: String, _ asset: String?, _ fallback: String) -> some View {
        // 시안 측정: 카드 폭 67pt · 높이 74pt · 일러스트 큼
        VStack(spacing: 11) {
            Text(label)
                .font(DT.sans(12.5, .semibold))
                .foregroundStyle(DT.ink)
            LuckyIconView(assetName: asset, fallbackSymbol: fallback, size: 50)
            Text(value)
                .font(DT.sans(10, .medium))
                .foregroundStyle(DT.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .background(DT.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DT.line, lineWidth: 1))
    }

    // MARK: - 운세 컨디션 (5개 카드)

    private func conditionSection(_ bundle: DailyFortuneBundle, _ index: Int) -> some View {
        let day = bundle.fortunes.indices.contains(index) ? bundle.fortunes[index] : bundle.today
        let dayLabel = day.date == bundle.today.date ? "오늘" : weekdayKo(day.date)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "clover.fill").font(.system(size: 14)).foregroundStyle(Color(hex: 0xB39DC9))
                Text("오늘의 운세 컨디션")
                    .font(DT.serif(17, .bold))
                    .foregroundStyle(DT.ink)
                Spacer()
                Button { showConditionsDetail = true } label: {
                    Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(DT.inkSoft)
                }
            }
            HStack(spacing: 8) {
                ForEach(HomeConditions.from(cards: day.cards), id: \.title) { item in
                    ConditionCard(item: item)
                }
            }
        }
        .sheet(isPresented: $showConditionsDetail) {
            ConditionsDetailView(items: HomeConditions.from(cards: day.cards), dayLabel: dayLabel)
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
                HStack(alignment: .bottom, spacing: 10) {
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
                    // "자세히 보기" 버튼과 동일 사이즈/모양 (색은 어두운 배너 가독성 위해 흰 글씨+핑크 유지)
                    HStack(spacing: 3) {
                        Text("오늘의 부적 보기")
                        Image(systemName: "chevron.right").font(.system(size: 9, weight: .bold))
                    }
                    .font(DT.sans(11, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
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

    // MARK: - 떠 있는 CTA 배너 (탭바 위 레이어 + X 닫기)

    private func floatingCtaBanner(_ bundle: DailyFortuneBundle) -> some View {
        ctaBanner(bundle)
            // ctaBanner 내부 별 배경 GeometryReader가 전체 높이로 늘어나는 것 방지 → 원래 콘텐츠 높이 유지
            .fixedSize(horizontal: false, vertical: true)
            .overlay(alignment: .topTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showCtaBanner = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(7)
                        .background(.white.opacity(0.18), in: Circle())
                }
                .padding(6)
                .accessibilityLabel("배너 닫기")
            }
            .shadow(color: .black.opacity(0.22), radius: 12, y: 4)
            .padding(.horizontal, DT.pagePadding)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
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
    private func weekdayKo(_ d: String) -> String {
        let p = d.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return "" }
        let jdn = jdnOf(p[0], p[1], p[2])
        let names = ["일", "월", "화", "수", "목", "금", "토"]
        return names[((jdn + 1) % 7 + 7) % 7] + "요일"
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
    private func trendText(_ bundle: DailyFortuneBundle, _ index: Int) -> String {
        guard index > 0, index < bundle.fortunes.count else { return "" }
        let diff = bundle.fortunes[index].overallScore - bundle.fortunes[index - 1].overallScore
        if diff > 0 { return "어제보다 +\(diff)" }
        if diff < 0 { return "어제보다 \(diff)" }
        return "어제와 같아요"
    }
}

// MARK: - 행운지수 자세히 보기 (배너에서 분리)

struct LuckyIndexDetailView: View {
    let bundle: DailyFortuneBundle
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var aiText = ""
    @State private var aiLoading = true
    @State private var aiErr: String?
    @State private var aiTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 오늘의 운세 — 정확한 일진 기반 AI 해석(분야별)
                    CraftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionTitle(text: "오늘의 운세")
                            let t = bundle.today
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(t.overallScore)").font(DT.sans(28, .bold)).foregroundStyle(DT.accent)
                                Text("점 · \(t.overallGrade)").font(DT.sans(13)).foregroundStyle(DT.inkSoft)
                            }
                            Divider().background(DT.line).padding(.vertical, 2)
                            if aiLoading && aiText.isEmpty {
                                AISkeleton()
                            } else if let e = aiErr, aiText.isEmpty {
                                VStack(spacing: 8) {
                                    Text("해석을 불러오지 못했어요").font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                                    Button("다시 시도") { load() }
                                        .font(DT.sans(12, .semibold)).foregroundStyle(DT.accent)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 6)
                                .accessibilityLabel(e)
                            } else {
                                FormattedAIText(text: aiText)
                            }
                        }
                    }
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
            .navigationTitle("오늘의 운세")
            .navigationBarTitleDisplayMode(.inline)
            .dtCloseToolbar { dismiss() }
        }
        .task { if aiText.isEmpty { load() } }
        .onDisappear { aiTask?.cancel() }
    }

    private func load() {
        guard let p = appState.profile, let r = appState.ensureSaju() else { aiLoading = false; return }
        aiTask?.cancel()
        aiText = ""; aiErr = nil; aiLoading = true
        aiTask = Task {
            do {
                for try await chunk in AIProxy.content(
                    id: "daily-fortune", tone: "warm",
                    gender: p.gender, birthYear: p.year, birthMonth: p.month, birthDay: p.day,
                    birthHour: p.hour, birthMinute: p.minute,
                    sajuResult: r, region: p.region, daily: appState.todayDailyPayload(),
                    isLunar: p.calendar == "lunar", isLeapMonth: p.isLeapMonth,
                    useTrueSolarTime: p.useTrueSolarTime) {
                    aiText += chunk
                }
            } catch {
                if !Task.isCancelled { aiErr = "\(error)" }
            }
            aiLoading = false
        }
    }

    private func shortDate(_ d: String) -> String {
        let p = d.split(separator: "-")
        guard p.count == 3 else { return d }
        return "\(Int(p[1]) ?? 0)/\(Int(p[2]) ?? 0)"
    }
}

// MARK: - 행운 아이템 상세 (항목별 오행 기반 설명)

struct LuckyItemsDetailView: View {
    let lucky: LuckyItems
    let yongsin: YongsinSummary
    let dayLabel: String
    @Environment(\.dismiss) private var dismiss

    private var rows: [(label: String, value: String, asset: String?, cat: LuckyItemReason.Category, fallback: String)] {
        [
            ("컬러", lucky.color, LuckyAssets.colorOrb(lucky.color) ?? LuckyAssets.colorAsset(lucky.color), .color, "paintpalette.fill"),
            ("음료", lucky.drink, LuckyAssets.drinkAsset(lucky.drink), .drink, "cup.and.saucer.fill"),
            ("장소", lucky.place, LuckyAssets.placeAsset(lucky.place), .place, "mappin.and.ellipse"),
            ("향기", lucky.scent, LuckyAssets.scentAsset(lucky.scent), .scent, "leaf.fill"),
            ("아이템", lucky.item, LuckyAssets.luckyItemAsset(lucky.item), .item, "gift.fill"),
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    CraftCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(yongsin.strengthLabel) · 용신 \(yongsin.elementKo)")
                                .font(DT.sans(13, .bold)).foregroundStyle(DT.accent)
                            Text(yongsin.description)
                                .font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(rows, id: \.label) { r in
                        CraftCard {
                            HStack(spacing: 12) {
                                LuckyIconView(assetName: r.asset, fallbackSymbol: r.fallback, size: 46)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(r.label).font(DT.sans(11, .semibold)).foregroundStyle(DT.inkSoft)
                                        Text(r.value).font(DT.sans(14, .bold)).foregroundStyle(DT.ink)
                                    }
                                    Text(LuckyItemReason.text(element: lucky.element, r.cat))
                                        .font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(DT.pagePadding)
            }
            .background(DT.bg)
            .navigationTitle("\(dayLabel)의 행운 아이템")
            .navigationBarTitleDisplayMode(.inline)
            .dtCloseToolbar { dismiss() }
        }
    }
}

// MARK: - 운세 컨디션 상세 (엔진 카드 설명)

struct ConditionsDetailView: View {
    let items: [ConditionItem]
    let dayLabel: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(items, id: \.title) { it in
                        CraftCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    LuckyIconView(assetName: it.asset, fallbackSymbol: "sparkles", size: 42)
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(it.title).font(DT.sans(14, .bold)).foregroundStyle(DT.ink)
                                            if !it.grade.isEmpty {
                                                Text(it.grade).font(DT.sans(10, .semibold)).foregroundStyle(DT.accent)
                                            }
                                        }
                                        StarRatingView(value: HomeConditions.stars(it.score), size: 9)
                                    }
                                    Spacer(minLength: 0)
                                    Text("\(it.score)").font(DT.sans(15, .bold)).foregroundStyle(DT.inkSoft)
                                }
                                if !it.desc.isEmpty {
                                    Text(it.desc).font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                }
                .padding(DT.pagePadding)
            }
            .background(DT.bg)
            .navigationTitle("\(dayLabel)의 운세 컨디션")
            .navigationBarTitleDisplayMode(.inline)
            .dtCloseToolbar { dismiss() }
        }
    }
}

// MARK: - AI 심층 편지 시트 (탭 시 온디맨드 스트리밍 — 매 스와이프 호출 아님)

struct AILetterSheet: View {
    let day: DailyFortuneResult
    let dayLabel: String
    let weekday: String
    let natalDayStem: String
    let natalDayBranch: String
    let gender: String
    let birthYear: Int
    var region: String = "서울"
    @Environment(\.dismiss) private var dismiss

    private var sinsals: [String] {
        HoshinSinSal.transitSinSals(transitBranch: day.dayBranchKorean,
                                    natalDayStem: natalDayStem, natalDayBranch: natalDayBranch)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CraftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(day.dayStemKorean)\(day.dayBranchKorean)일 · \(day.tenGodOfDay) · \(day.twelveStageOfDay)")
                                .font(DT.sans(13, .bold)).foregroundStyle(DT.ink)
                            if !sinsals.isEmpty {
                                Text("신살: \(sinsals.joined(separator: ", "))")
                                    .font(DT.sans(12)).foregroundStyle(DT.accent)
                            }
                            Text("행운지수 \(day.overallScore)점 (\(day.overallGrade))")
                                .font(DT.sans(12)).foregroundStyle(DT.inkSoft)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }
                    AIInterpretationView(title: "\(dayLabel)의 심층 편지") {
                        AIProxy.interpretDaily(day: day, weekday: weekday, sinsals: sinsals,
                                               gender: gender, birthYear: birthYear, region: region)
                    }
                }
                .padding(DT.pagePadding)
            }
            .background(DT.bg)
            .navigationTitle("심층 편지")
            .navigationBarTitleDisplayMode(.inline)
            .dtCloseToolbar { dismiss() }
        }
    }
}
