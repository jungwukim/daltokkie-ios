// 메인 탭 셸 — iOS 표준 TabView. 중앙 운세 탭도 일반 탭 아이템(토끼 아이콘).

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

            FortuneMenuView()
                .tabItem { Label("운세", image: "tab-rabbit") }
                .tag(AppState.Tab.fortune)

            TarotView()
                .tabItem { Label("타로", systemImage: "rectangle.portrait.on.rectangle.portrait.fill") }
                .tag(AppState.Tab.tarot)

            MyView()
                .tabItem { Label("마이", systemImage: "cat") }
                .tag(AppState.Tab.my)
        }
        .tint(DT.accent)
    }
}
