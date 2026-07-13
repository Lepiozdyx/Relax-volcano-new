import SwiftUI

enum AppTab: CaseIterable {
    case volcano
    case breakMode
    case history
    case stats
    case settings

    var title: String {
        switch self {
        case .volcano: return "Volcano"
        case .breakMode: return "Break"
        case .history: return "History"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .volcano: return "house"
        case .breakMode: return "timer"
        case .history: return "calendar"
        case .stats: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

struct RootTabContainerView: View {
    @StateObject private var viewModel = RootTabViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.selectedTab) {
                VolcanoScreenView().tag(AppTab.volcano)
                BreakScreenView().tag(AppTab.breakMode)
                HistoryScreenView().tag(AppTab.history)
                StatsScreenView().tag(AppTab.stats)
                SettingsScreenView(isBottomBarHidden: $viewModel.isBottomBarHidden).tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())

            if !viewModel.isBottomBarHidden {
                BottomNavigationBar(selectedTab: $viewModel.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.isBottomBarHidden)
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            NotificationManager.shared.requestPermissionIfNeeded()
            let defaults = UserDefaults.standard
            let start = defaults.object(forKey: VolcanoStorageKey.workDayStartMinutes) as? Int ?? 8 * 60
            let end = defaults.object(forKey: VolcanoStorageKey.workDayEndMinutes) as? Int ?? 20 * 60
            NotificationManager.shared.scheduleDailyVolcanoNotifications(startMinutes: start, endMinutes: end)
        }
    }
}

#Preview {
    RootTabContainerView()
}
