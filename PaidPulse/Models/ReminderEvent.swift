import Foundation
import SwiftData

@Model
final class ReminderEvent {
    var id: UUID
    var invoiceId: UUID
    var level: Int
    var channel: String
    var scheduledFor: Date?
    var sentAt: Date
    var letterSnapshot: String

    init(invoiceId: UUID, level: Int, channel: String, letterSnapshot: String, scheduledFor: Date? = nil) {
        self.id = UUID()
        self.invoiceId = invoiceId
        self.level = level
        self.channel = channel
        self.scheduledFor = scheduledFor
        self.sentAt = .now
        self.letterSnapshot = letterSnapshot
    }
}
