import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: AppTab

    private let barColor = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    private let activeColor = Color(red: 1.0, green: 215 / 255, blue: 0)
    private let inactiveColor = Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)
    private let barWidth: CGFloat = 390
    private let barHeight: CGFloat = 83
    private let tabCentersX: [CGFloat] = [57, 126, 195, 264, 334]

    var body: some View {
        ZStack {
            barColor
            ZStack {
                ForEach(Array(AppTab.allCases.enumerated()), id: \.element) { index, tab in
                    tabButton(tab: tab)
                        .position(x: tabCentersX[index], y: barHeight / 2)
                }
            }
            .frame(width: barWidth, height: barHeight)
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
    }

    @ViewBuilder
    private func tabButton(tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        Button {
            SoundManager.shared.playButtonSound()
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 24, weight: .regular))
                    .frame(width: 24, height: 24)
                Text(tab.title)
                    .font(.system(size: 10, weight: .regular))
                    .lineLimit(1)
                    .frame(height: 12)
            }
            .foregroundStyle(isSelected ? activeColor : inactiveColor)
            .frame(width: 69, height: 83, alignment: .top)
            .padding(.top, 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.black.ignoresSafeArea()
        BottomNavigationBar(selectedTab: .constant(.settings))
    }
}
