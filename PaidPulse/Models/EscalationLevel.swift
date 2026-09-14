import Foundation

enum EscalationLevel: Int, CaseIterable, Codable, Identifiable {
    case dueToday = 0
    case politeNudge
    case friendlyFollowup
    case firmReminder
    case formalDemand
    case finalNotice

    var id: Int { rawValue }

    var triggerDay: Int { [0, 3, 7, 14, 30, 45][rawValue] }

    var title: String {
        ["Due Today", "Polite Nudge", "Friendly Follow-up", "Firm Reminder", "Formal Demand", "Final Notice"][rawValue]
    }

    var tone: String {
        ["Friendly", "Friendly", "Professional", "Firm", "Formal", "Final"][rawValue]
    }

    var toneColorName: String {
        ["green", "green", "blue", "orange", "orange", "red"][rawValue]
    }

    static func stage(forDaysOverdue days: Int) -> EscalationLevel {
        allCases.reversed().first { days >= $0.triggerDay } ?? .dueToday
    }
}

struct EscalationEngine {
    static func targetLevel(for invoice: Invoice) -> EscalationLevel {
        EscalationLevel.stage(forDaysOverdue: invoice.daysOverdue)
    }

    static func advance(_ invoice: Invoice) -> EscalationLevel? {
        let target = targetLevel(for: invoice)
        guard target.rawValue > invoice.currentStage else { return nil }
        invoice.currentStage = target.rawValue
        return target
    }
}
