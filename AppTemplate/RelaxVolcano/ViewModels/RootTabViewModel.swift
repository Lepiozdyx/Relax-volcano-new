import SwiftUI
import Combine

final class RootTabViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .volcano
    @Published var isBottomBarHidden = false
}
