// 달토끼 — 사주·점성술·자미두수 온디바이스 운세 앱

import SwiftUI
import TipKit

@main
struct DalTokkieApp: App {
    @StateObject private var appState = AppState()

    init() {
        DTFonts.register()
        try? Tips.configure([.datastoreLocation(.applicationDefault),
                             .displayFrequency(.immediate)])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)   // 과도한 확대로 레이아웃 붕괴 방지
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.profile == nil {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}
