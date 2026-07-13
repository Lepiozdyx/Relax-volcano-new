import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let foregroundDelegate = ForegroundNotificationDelegate()

    private init() {}

    func requestPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.delegate = foregroundDelegate
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDailyVolcanoNotifications(startMinutes: Int, endMinutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["volcano.morning", "volcano.evening"])

        let morning = UNMutableNotificationContent()
        morning.title = "Relax Volcano"
        morning.body = "Volcano wakes up"
        morning.sound = .default

        var morningComponents = DateComponents()
        morningComponents.hour = max(0, min(23, startMinutes / 60))
        morningComponents.minute = max(0, min(59, startMinutes % 60))

        let morningTrigger = UNCalendarNotificationTrigger(dateMatching: morningComponents, repeats: true)
        let morningRequest = UNNotificationRequest(identifier: "volcano.morning", content: morning, trigger: morningTrigger)

        let evening = UNMutableNotificationContent()
        evening.title = "Relax Volcano"
        evening.body = "Time to extinguish"
        evening.sound = .default

        let eveningTotal = max(0, endMinutes - 30)
        var eveningComponents = DateComponents()
        eveningComponents.hour = max(0, min(23, eveningTotal / 60))
        eveningComponents.minute = max(0, min(59, eveningTotal % 60))

        let eveningTrigger = UNCalendarNotificationTrigger(dateMatching: eveningComponents, repeats: true)
        let eveningRequest = UNNotificationRequest(identifier: "volcano.evening", content: evening, trigger: eveningTrigger)

        center.add(morningRequest)
        center.add(eveningRequest)
    }

    func sendTestNotificationNow() {
        let center = UNUserNotificationCenter.current()
        center.delegate = foregroundDelegate
        let content = UNMutableNotificationContent()
        content.title = "Relax Volcano"
        content.body = "Test notification"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "volcano.test.now", content: content, trigger: trigger)
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                center.add(request)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        center.add(request)
                    }
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }
}

private final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
