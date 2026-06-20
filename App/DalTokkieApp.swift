// 달토끼 — 사주·점성술·자미두수 온디바이스 운세 앱

import SwiftUI

@main
struct DalTokkieApp: App {
    @StateObject private var appState = AppState()

    init() {
        DTFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
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
