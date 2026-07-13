import Foundation
import SwiftUI
import Combine

final class StatsViewModel: ObservableObject {
    private let calendar = Calendar.current

    let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    func weekDates(reference: Date = Date()) -> [Date] {
        let weekday = calendar.component(.weekday, from: reference)
        let mondayOffset = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: calendar.startOfDay(for: reference)) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    func weeklyStatuses(dayMarksJSON: String) -> [WeekStatus] {
        let marks = VolcanoDayMarksStore.decode(dayMarksJSON)
        return weekDates().map { date in
            let key = VolcanoDayMarksStore.dateKey(for: date, calendar: calendar)
            switch marks[key] {
            case .done: return .done
            case .breakTime: return .breakTime
            case .missed: return .missed
            case .none: return .none
            }
        }
    }

    func tensionValues(daySwipeCountsJSON: String) -> [CGFloat] {
        let counts = VolcanoDaySwipeCountsStore.decode(daySwipeCountsJSON)
        return weekDates().map { date in
            let key = VolcanoDayMarksStore.dateKey(for: date, calendar: calendar)
            return CGFloat(counts[key] ?? 0)
        }
    }
}

enum WeekStatus: Equatable {
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
