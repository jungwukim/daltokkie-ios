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

    // 시안: 홈(집)/부적함(보물상자)/중앙 토끼/타로(카드)/마이(고양이)
    private let leftItems: [Item] = [
        Item(tab: .home, icon: "house.fill", label: "홈"),
        Item(tab: .talisman, icon: "archivebox.fill", label: "부적함"),
    ]
    private let rightItems: [Item] = [
        Item(tab: .tarot, icon: "rectangle.portrait.on.rectangle.portrait.fill", label: "타로"),
        Item(tab: .my, icon: "cat", label: "마이"),
    ]

    var body: some View {
        // 양옆 4개 아이콘은 같은 높이, 중앙은 빈 자리 — 배지는 overlay로 돌출
        HStack(spacing: 0) {
            ForEach(leftItems, id: \.tab) { tabButton($0) }
            Color.clear.frame(maxWidth: .infinity)   // 중앙 자리
            ForEach(rightItems, id: \.tab) { tabButton($0) }
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
        .padding(.horizontal, 6)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                .fill(DT.card)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                        .stroke(DT.line, lineWidth: 1)
                )
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            // 중앙 달토끼 배지 — 탭바 상단선에 걸쳐 위로 돌출
            Button {
                appState.selectedTab = .fortune
            } label: {
                ZStack {
                    Circle()
                        .fill(DT.card)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().stroke(DT.strokeBrown.opacity(0.5), lineWidth: 1.5))
                    Circle()
                        .fill(DT.night)
                        .frame(width: 78, height: 78)
                        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
                    Image("dal-tokkie-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56)
                }
            }
            .offset(y: -34)   // 배지 상단이 탭바 위로, 하단은 탭바에 걸침
        }
    }

    private func tabButton(_ item: Item) -> some View {
        let active = appState.selectedTab == item.tab
        return Button {
            appState.selectedTab = item.tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                Text(item.label)
                    .font(DT.sans(10, .medium))
            }
            .foregroundStyle(active ? DT.accent : Color(hex: 0x9C8E7A))
            .frame(maxWidth: .infinity)
        }
    }
}
