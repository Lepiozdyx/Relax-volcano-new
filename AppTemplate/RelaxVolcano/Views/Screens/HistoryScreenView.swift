import SwiftUI
import Combine

struct HistoryScreenView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @AppStorage(VolcanoStorageKey.dayMarksJSON) private var dayMarksJSON: String = "{}"

    private let cardColor = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    private let subtitleColor = Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)
    private let warningColor = Color(red: 1.0, green: 59 / 255, blue: 48 / 255)

    private var weekSymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let firstWeekdayIndex = max(0, min(calendar.firstWeekday - 1, symbols.count - 1))
        return Array(symbols[firstWeekdayIndex...] + symbols[..<firstWeekdayIndex])
    }
    @State private var selectedDay = Calendar.current.component(.day, from: Date())

    private var isCompactPhone: Bool {
        let bounds = UIScreen.main.bounds
        let shortSide = min(bounds.width, bounds.height)
        let longSide = max(bounds.width, bounds.height)
        return shortSide <= 350 || longSide <= 700
    }

    private var calendar: Calendar { .current }

    private var days: [CalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: viewModel.displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.displayedMonth)) else {
            return []
        }
        let marks = VolcanoDayMarksStore.decode(dayMarksJSON)
        return range.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) else {
                return nil
            }
            let key = VolcanoDayMarksStore.dateKey(for: date, calendar: calendar)
            let status: DayStatus
            switch marks[key] {
            case .done: status = .done
            case .breakTime: status = .breakTime
            case .missed: status = .missed
            case .none: status = .none
            }
            return .init(number: day, status: status)
        }
    }

    private var dayGrid: [CalendarGridCell] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.displayedMonth)) else {
            return days.map { .day($0) }
        }
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmptyCount = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let leading = Array(repeating: CalendarGridCell.empty, count: leadingEmptyCount)
        return leading + days.map { .day($0) }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: viewModel.displayedMonth)
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = scaleForScreen(size: geometry.size)
            let topContentPadding = max(24, geometry.safeAreaInsets.top + 12)

            
            VStack(alignment: .leading, spacing: 6) {
                    Text("Break Timer")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding()
                    legendCard
                    tapHint
                    monthHeader
                    calendarCard
                    if selectedDayStatus != .none {
                        selectedDayCard
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top)
                .padding(.bottom, 103)
                .frame(maxWidth: 390, alignment: .topLeading)
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .scaleEffect(scale, anchor: .top)
            .background(Color.black.opacity(0.6).ignoresSafeArea())
        }
    }

    private var legendCard: some View {
        HStack(spacing: 26) {
            legendItem(color: DayStatus.done.color, title: "done")
            legendItem(color: DayStatus.breakTime.color, title: "breakTime")
            legendItem(color: DayStatus.missed.color, title: "missed")
            legendItem(color: DayStatus.none.color, title: "none")
        }
        .padding(.horizontal, 16)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(warningColor.opacity(0.5), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func legendItem(color: Color, title: String) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white)
        }
    }

    private var tapHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 16, weight: .regular))
            Text("Tap a day to see details")
                .font(.system(size: 15, weight: .regular))
        }
        .foregroundStyle(warningColor)
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 70, style: .continuous)
                .stroke(warningColor.opacity(0.8), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 70, style: .continuous))
        .shadow(color: warningColor.opacity(0.5), radius: 7.2)
    }

    private var monthHeader: some View {
        HStack {
            monthArrow(systemName: "chevron.left") {
                viewModel.moveMonth(by: -1)
                clampSelectedDayToDisplayedMonth()
            }
            Spacer()
            Text(monthName)
                .font(.system(size: 42 * 0.6, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            monthArrow(systemName: "chevron.right") {
                viewModel.moveMonth(by: 1)
                clampSelectedDayToDisplayedMonth()
            }
        }
    }

    private func monthArrow(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.playButtonSound()
            action()
        } label: {
            Circle()
                .fill(cardColor)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: systemName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
        .buttonStyle(.plain)
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                ForEach(Array(weekSymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 7), spacing: 8) {
                ForEach(Array(dayGrid.enumerated()), id: \.offset) { _, cell in
                    switch cell {
                    case .empty:
                        Color.clear
                            .frame(height: 38)
                    case .day(let day):
                        dayCell(day)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        Button {
            SoundManager.shared.playButtonSound()
            selectedDay = day.number
        } label: {
            VStack(spacing: 2) {
                if day.hasDot {
                    Circle()
                        .fill(.white)
                        .frame(width: 5, height: 5)
                } else {
                    Spacer().frame(height: 5)
                }

                Text("\(day.number)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(height: 38)
            .frame(maxWidth: .infinity)
            .background(day.status.color)
            .overlay {
                if selectedDay == day.number {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var selectedDayCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(selectedDayStatus.color)
                .frame(width: 16, height: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedDayTitle)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)

                Text(selectedDaySubtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(subtitleColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(cardColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(selectedDayStatus.color.opacity(0.5), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: selectedDayStatus.color.opacity(0.5), radius: 11.2)
    }

    private func scaleForScreen(size: CGSize) -> CGFloat {
        if !isCompactPhone {
            return 1.0
        }

        let requiredHeight: CGFloat = 780
        let topPadding: CGFloat = 80
        let bottomPadding: CGFloat = 24
        let availableHeight = size.height - topPadding - bottomPadding
        let heightScale = min(1.0, availableHeight / requiredHeight)

        let widthScale = min(1.0, (size.width - 24) / 390)
        return max(0.95, min(heightScale, widthScale))
    }

    private var selectedDayStatus: DayStatus {
        days.first(where: { $0.number == selectedDay })?.status ?? .none
    }

    private var selectedDayTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        guard let date = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: viewModel.displayedMonth),
            month: calendar.component(.month, from: viewModel.displayedMonth),
            day: selectedDay
        )) else {
            return "Day \(selectedDay)"
        }
        return formatter.string(from: date)
    }

    private var selectedDaySubtitle: String {
        switch selectedDayStatus {
        case .done:
            return "Volcano extinguished before end of day"
        case .breakTime:
            return "Break timer was used (15/30/60 min)"
        case .missed:
            return "Volcano destroyed (did not open before end of day)"
        case .none:
            return ""
        }
    }

    private func clampSelectedDayToDisplayedMonth() {
        let maxDay = days.map(\.number).max() ?? selectedDay
        selectedDay = max(1, min(selectedDay, maxDay))
    }
}

private struct CalendarDay: Identifiable {
    let id = UUID()
    let number: Int
    let status: DayStatus
    var hasDot: Bool = false
}

private enum CalendarGridCell {
    case empty
    case day(CalendarDay)
}

private enum DayStatus {
    case done
    case breakTime
    case missed
    case none

    var color: Color {
        switch self {
        case .done:
            return Color(red: 0 / 255, green: 201 / 255, blue: 80 / 255)
        case .breakTime:
            return Color(red: 1.0, green: 215 / 255, blue: 0)
        case .missed:
            return Color(red: 1.0, green: 59 / 255, blue: 48 / 255)
        case .none:
            return Color(red: 106 / 255, green: 114 / 255, blue: 130 / 255)
        }
    }
}

#Preview {
    HistoryScreenView()
}

final class HistoryViewModel: ObservableObject {
    @Published var displayedMonth: Date = Date()

    private let calendar = Calendar.current

    func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }
}
