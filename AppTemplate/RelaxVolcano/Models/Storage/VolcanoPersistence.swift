import Foundation

enum VolcanoStorageKey {
    static let workDayStartMinutes = "workDayStartMinutes"
    static let workDayEndMinutes = "workDayEndMinutes"
    static let dayMarksJSON = "volcanoDayMarksJSON"
    static let daySwipeCountsJSON = "volcanoDaySwipeCountsJSON"
    static let timerSound = "volcanoTimerSound"
}

enum VolcanoDayMark: String, Codable {
    case done
    case breakTime
    case missed
}

enum VolcanoDayMarksStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func dateKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func decode(_ raw: String) -> [String: VolcanoDayMark] {
        guard let data = raw.data(using: .utf8) else { return [:] }
        return (try? decoder.decode([String: VolcanoDayMark].self, from: data)) ?? [:]
    }

    static func encode(_ marks: [String: VolcanoDayMark]) -> String {
        guard let data = try? encoder.encode(marks),
              let raw = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return raw
    }
}

enum VolcanoDaySwipeCountsStore {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func decode(_ raw: String) -> [String: Int] {
        guard let data = raw.data(using: .utf8) else { return [:] }
        return (try? decoder.decode([String: Int].self, from: data)) ?? [:]
    }

    static func encode(_ counts: [String: Int]) -> String {
        guard let data = try? encoder.encode(counts),
              let raw = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return raw
    }
}
