import Foundation
import UserNotifications

enum NotificationScheduler {
    static func rebuild(for invoice: Invoice) {
        let center = UNUserNotificationCenter.current()
        let ids = EscalationLevel.allCases.map { "\(invoice.id.uuidString)-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard invoice.isActive else { return }

        let cal = Calendar.current
        for level in EscalationLevel.allCases where level.rawValue > invoice.currentStage {
            guard let fireDate = cal.date(byAdding: .day, value: level.triggerDay,
                                          to: cal.startOfDay(for: invoice.dueDate)),
                  let fireTime = cal.date(bySettingHour: 9, minute: 0, second: 0, of: fireDate),
                  fireTime > .now else { continue }
            guard fireTime.timeIntervalSinceNow < 14 * 86400 else { break }

            let content = UNMutableNotificationContent()
            content.title = "Chase invoice \(invoice.number)?"
            content.body = "\(invoice.client?.name ?? "Client") is \(level.triggerDay) day(s) past due — \(level.title) letter is ready to send."
            content.sound = .default
            content.userInfo = ["invoiceId": invoice.id.uuidString]

            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(identifier: "\(invoice.id.uuidString)-\(level.rawValue)",
                                            content: content, trigger: trigger)
            center.add(req)
        }
    }

    static func cancelAll(for invoice: Invoice) {
        let center = UNUserNotificationCenter.current()
        let ids = EscalationLevel.allCases.map { "\(invoice.id.uuidString)-\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}
