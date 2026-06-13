// 메인 탭 셸 — 표준 TabView + 중앙 달토끼 돌출 배지(라벨 없음, 크게)

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    init() {
        // 탭바 외형을 크래프트지 톤으로 (UITabBarAppearance)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DT.card)
        appearance.shadowColor = UIColor(DT.line)

        let normal = UIColor(Color(hex: 0x9C8E7A))
        let selected = UIColor(DT.accent)
        for item in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            item.normal.iconColor = normal
            item.normal.titleTextAttributes = [.foregroundColor: normal]
            item.selected.iconColor = selected
            item.selected.titleTextAttributes = [.foregroundColor: selected]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(AppState.Tab.home)

            TalismanView()
                .tabItem { Label("부적함", systemImage: "archivebox.fill") }
                .tag(AppState.Tab.talisman)

            // 중앙: 운세 — 탭 아이템은 빈 자리, 실제 표시는 아래 돌출 배지
            FortuneMenuView()
                .tabItem { Label(" ", image: "tab-empty") }
                .tag(AppState.Tab.fortune)

            TarotView()
                .tabItem { Label("타로", systemImage: "rectangle.portrait.on.rectangle.portrait.fill") }
                .tag(AppState.Tab.tarot)

            MyView()
                .tabItem { Label("마이", systemImage: "cat") }
                .tag(AppState.Tab.my)
        }
        .tint(DT.accent)
        // 중앙 달토끼 돌출 배지 (라벨 없음, 다른 탭보다 큼) — 탭바 위 중앙에 겹쳐 표시
        .overlay(alignment: .bottom) {
            CenterBadge()
                .environmentObject(appState)
        }
    }
}

/// 중앙 달토끼 돌출 배지 — 시안: 라벨 없이 네이비 원 배지가 탭바 위로 돌출
private struct CenterBadge: View {
    @EnvironmentObject var appState: AppState
    // 시안 측정: 네이비 원 48pt, 베이지 링 포함 58pt, 토끼 ~70%
    private let badgeSize: CGFloat = 48
    private let ringWidth: CGFloat = 5

    var body: some View {
        Button {
            appState.selectedTab = .fortune
        } label: {
            ZStack {
                Circle()
                    .fill(DT.card)
                    .frame(width: badgeSize + ringWidth * 2, height: badgeSize + ringWidth * 2)
                    .overlay(Circle().stroke(DT.strokeBrown.opacity(0.5), lineWidth: 1.5))
                Circle()
                    .fill(DT.night)
                    .frame(width: badgeSize, height: badgeSize)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                Image("dal-tokkie-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: badgeSize * 0.7)
            }
        }
        // 탭바 상단선에 배지가 걸쳐 위쪽 절반 돌출
        .offset(y: -20)
    }
}
