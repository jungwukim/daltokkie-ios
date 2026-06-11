// 메인 탭 셸 — 하단 5탭 (홈/부적함/달토끼·운세/타로/마이), 중앙 로고 돌출
// 웹 bottom-tab-bar.tsx 대응

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                DT.bg.ignoresSafeArea()
                switch appState.selectedTab {
                case .home: HomeView()
                case .talisman: TalismanView()
                case .fortune: FortuneMenuView()
                case .tarot: TarotView()
                case .my: MyView()
                }
            }
            .frame(maxHeight: .infinity)

            BottomTabBar()
        }
        .background(DT.bg.ignoresSafeArea())
    }
}

struct BottomTabBar: View {
    @EnvironmentObject var appState: AppState

    private struct Item {
        let tab: AppState.Tab
        let icon: String
        let label: String
    }

    private let leftItems: [Item] = [
        Item(tab: .home, icon: "house.fill", label: "홈"),
        Item(tab: .talisman, icon: "seal.fill", label: "부적함"),
    ]
    private let rightItems: [Item] = [
        Item(tab: .tarot, icon: "rectangle.portrait.on.rectangle.portrait.angled.fill", label: "타로"),
        Item(tab: .my, icon: "person.fill", label: "마이"),
    ]

    var body: some View {
        HStack(alignment: .bottom) {
            ForEach(leftItems, id: \.tab) { tabButton($0) }

            // 중앙: 달토끼 로고 (운세 탭) — 위로 돌출
            Button {
                appState.selectedTab = .fortune
            } label: {
                ZStack {
                    Circle()
                        .fill(DT.night)
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                    Image("dal-tokkie-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38)
                }
                .offset(y: -18)
            }
            .frame(maxWidth: .infinity)

            ForEach(rightItems, id: \.tab) { tabButton($0) }
        }
        .padding(.top, 10)
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
        .background(
            DT.card
                .overlay(Rectangle().fill(DT.line).frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(_ item: Item) -> some View {
        Button {
            appState.selectedTab = item.tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                Text(item.label)
                    .font(DT.sans(10, .medium))
            }
            .foregroundStyle(appState.selectedTab == item.tab ? DT.accent : Color(hex: 0xB0A08A))
            .frame(maxWidth: .infinity)
        }
    }
}
