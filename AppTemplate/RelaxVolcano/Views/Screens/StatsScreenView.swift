import SwiftUI

struct StatsScreenView: View {
    @StateObject private var viewModel = StatsViewModel()
    @AppStorage(VolcanoStorageKey.dayMarksJSON) private var dayMarksJSON: String = "{}"
    @AppStorage(VolcanoStorageKey.daySwipeCountsJSON) private var daySwipeCountsJSON: String = "{}"

    private let cardColor = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    private let borderColor = Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)
    private let subtitleColor = Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)

    private var isCompactPhone: Bool {
        let bounds = UIScreen.main.bounds
        let shortSide = min(bounds.width, bounds.height)
        let longSide = max(bounds.width, bounds.height)
        return shortSide <= 350 || longSide <= 700
    }

    private var weeklyStatuses: [WeekStatus] {
        viewModel.weeklyStatuses(dayMarksJSON: dayMarksJSON)
    }

    private var weeklyBalanceColors: [Color] {
        weeklyStatuses.map(\.color)
    }

    private var tensionValues: [CGFloat] {
        viewModel.tensionValues(daySwipeCountsJSON: daySwipeCountsJSON)
    }

    private var hasStatsData: Bool {
        weeklyStatuses.contains { $0 != .none } || tensionValues.contains { $0 > 0 }
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = scaleForScreen(size: geometry.size)
            let topContentPadding = max(24, geometry.safeAreaInsets.top + 12)
            let contentWidth: CGFloat = isCompactPhone ? min(342, geometry.size.width - 48) : 342

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, topContentPadding)

                if hasStatsData {
                    filledState(contentWidth: contentWidth)
                        .padding(.top, 24)
                } else {
                    Spacer()
                    emptyState
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 120)
            .frame(maxWidth: 390, maxHeight: .infinity, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scaleEffect(x: 1.0, y: scale, anchor: .top)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Statistics")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text("Review Your Relaxation Patterns")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(subtitleColor)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text("No data available")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)

            Text("Statistics will appear after the first active day")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(subtitleColor)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func filledState(contentWidth: CGFloat) -> some View {
        VStack(spacing: 24) {
            weeklyBalanceCard(contentWidth: contentWidth)
            tensionCard(contentWidth: contentWidth)
        }
        .frame(width: contentWidth, alignment: .leading)
    }

    private func weeklyBalanceCard(contentWidth: CGFloat) -> some View {
        let cardHeight = contentWidth * (206.0 / 342.0)
        let barWidth = max(28, contentWidth * (36.0 / 342.0))
        let barHeight = max(84, contentWidth * (106.0 / 342.0))
        let barSpacing = max(6, contentWidth * (10.0 / 342.0))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Balance")
                .font(.system(size: 34 * 0.47, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                VStack(spacing: 25) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255))
                            .frame(height: 1)
                            .overlay {
                                Color.clear
                            }
                    }
                }
                .overlay(alignment: .bottom) {
                    HStack(alignment: .bottom, spacing: barSpacing) {
                        ForEach(0..<7, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(weeklyBalanceColors[index])
                                .frame(width: barWidth, height: barHeight)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .frame(height: barHeight + 6, alignment: .bottom)

                HStack(spacing: 0) {
                    ForEach(viewModel.weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(subtitleColor)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 6)

            Text("Total Breaks Vs Missed Days This Week.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(subtitleColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: contentWidth, height: cardHeight)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor.opacity(0.8), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func tensionCard(contentWidth: CGFloat) -> some View {
        let cardHeight = contentWidth * (309.0 / 342.0)
        let chartHeight = max(150, contentWidth * (190.0 / 342.0))

        return VStack(alignment: .leading, spacing: 12) {
            Text("Tension / Swipes")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                GeometryReader { proxy in
                    let chartWidth = proxy.size.width
                    let chartHeight = proxy.size.height
                    let maxValue = max(10, (tensionValues.max() ?? 0))
                    let stepX = chartWidth / CGFloat(max(viewModel.weekDays.count, 1))

                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(0..<5, id: \.self) { idx in
                                if idx > 0 {
                                    Spacer()
                                }
                                Rectangle()
                                    .fill(Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255))
                                    .frame(height: 1)
                            }
                        }

                        Path { path in
                            let points: [CGPoint] = tensionValues.indices.map { index in
                                CGPoint(
                                    x: stepX * (CGFloat(index) + 0.5),
                                    y: chartHeight * (1 - (tensionValues[index] / maxValue))
                                )
                            }

                            guard let first = points.first else { return }
                            path.move(to: first)

                            guard points.count > 2 else {
                                if let second = points.last {
                                    path.addLine(to: second)
                                }
                                return
                            }

                            for index in 1..<points.count {
                                let p1 = points[index - 1]
                                let p2 = points[index]
                                let dx = p2.x - p1.x
                                let controlOffset = dx * 0.35

                                let control1 = CGPoint(
                                    x: p1.x + controlOffset,
                                    y: p1.y
                                )
                                let control2 = CGPoint(
                                    x: p2.x - controlOffset,
                                    y: p2.y
                                )

                                path.addCurve(to: p2, control1: control1, control2: control2)
                            }
                        }
                        .stroke(Color(red: 1.0, green: 59 / 255, blue: 48 / 255), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

                        ForEach(tensionValues.indices, id: \.self) { index in
                            let x = stepX * (CGFloat(index) + 0.5)
                            let y = chartHeight * (1 - (tensionValues[index] / maxValue))
                            Circle()
                                .fill(Color.black)
                                .frame(width: 10, height: 10)
                                .overlay {
                                    Circle()
                                        .stroke(Color(red: 1.0, green: 59 / 255, blue: 48 / 255), lineWidth: 3)
                                }
                                .position(x: x, y: y)
                        }
                    }
                }
                .frame(height: chartHeight)

                HStack(spacing: 0) {
                    ForEach(viewModel.weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(subtitleColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 10)
            }

            Text("Higher line means more swipes were needed to cool the volcano.")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(subtitleColor)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: contentWidth, height: cardHeight)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor.opacity(0.8), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        if !isCompactPhone {
            return 1.0
        }

        let requiredHeight: CGFloat = hasStatsData ? 860 : 760
        let topPadding: CGFloat = 80
        let bottomPadding: CGFloat = 120
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)

        let scale = heightScale
        return max(0.85, scale)
    }
}

#Preview {
    RootTabContainerView()
}
