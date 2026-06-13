// 메인 탭 셸 — 하단 5탭 (홈/부적함/달토끼·운세/타로/마이), 중앙 로고 돌출
// 웹 bottom-tab-bar.tsx 대응

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            DT.bg.ignoresSafeArea()
            Group {
                switch appState.selectedTab {
                case .home: HomeView()
                case .talisman: TalismanView()
                case .fortune: FortuneMenuView()
                case .tarot: TarotView()
                case .my: MyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // 탭바를 safe area 하단에 고정 — 표준 방식, 홈 인디케이터까지 배경 채움
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar()
        }
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

    private let barHeight: CGFloat = 58
    private let badgeSize: CGFloat = 64

    var body: some View {
        // 탭바 본체(고정 높이) 위에 ZStack으로 배지를 얹음 — 배지가 위로 절반 돌출
        ZStack(alignment: .top) {
            // 탭바 본체
            HStack(spacing: 0) {
                ForEach(leftItems, id: \.tab) { tabButton($0) }
                Color.clear.frame(maxWidth: .infinity)   // 중앙 자리 (배지가 들어옴)
                ForEach(rightItems, id: \.tab) { tabButton($0) }
            }
            .frame(height: barHeight)
            .frame(maxWidth: .infinity)
            .background(
                // 배경을 safe area 아래(홈 인디케이터)까지 확장 — 탭바가 바닥에 딱 붙음
                UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                    .fill(DT.card)
                    .overlay(
                        UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22)
                            .stroke(DT.line, lineWidth: 1)
                    )
                    .ignoresSafeArea(edges: .bottom),
                alignment: .top
            )

            // 중앙 달토끼 배지 — 탭바 상단선에 걸쳐 위로 절반 돌출
            Button {
                appState.selectedTab = .fortune
            } label: {
                ZStack {
                    Circle()
                        .fill(DT.card)
                        .frame(width: badgeSize + 8, height: badgeSize + 8)
                        .overlay(Circle().stroke(DT.strokeBrown.opacity(0.5), lineWidth: 1.5))
                    Circle()
                        .fill(DT.night)
                        .frame(width: badgeSize, height: badgeSize)
                        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
                    Image("dal-tokkie-icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: badgeSize * 0.7)
                }
            }
            .offset(y: -(badgeSize + 8) / 2 + 10)   // 배지 절반이 탭바 위로
        }
        .frame(height: barHeight)   // 탭바가 차지하는 레이아웃 높이는 본체 높이만 (배지 돌출분은 영역 밖 그림)
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
