import Foundation
import SwiftData

@Model
final class Invoice {
    enum Status: String, Codable {
        case draft, sent, partial, paid, writtenOff
    }

    var id: UUID
    var number: String
    var client: Client?
    var amount: Decimal
    var dueDate: Date
    var issueDate: Date
    var statusRaw: String = Status.sent.rawValue
    var currentStage: Int = 0
    var lateFeePercent: Decimal = 0
    var annualInterestRate: Decimal = 0
    var paidDate: Date?
    var paidAmount: Decimal = 0
    var projectNote: String = ""

    init(client: Client, amount: Decimal, dueDate: Date, issueDate: Date = .now,
         annualInterestRate: Decimal = 0, lateFeePercent: Decimal = 0, note: String = "") {
        self.id = UUID()
        self.number = "INV-0000"
        self.client = client
        self.amount = amount
        self.dueDate = dueDate
        self.issueDate = issueDate
        self.annualInterestRate = annualInterestRate
        self.lateFeePercent = lateFeePercent
        self.projectNote = note
    }

    var status: Status {
        get { Status(rawValue: statusRaw) ?? .sent }
        set { statusRaw = newValue.rawValue }
    }

    var isActive: Bool { status != .paid && status != .writtenOff }

    var daysOverdue: Int {
        guard status != .paid else { return 0 }
        let cal = Calendar.current
        let due = cal.startOfDay(for: dueDate)
        let today = cal.startOfDay(for: .now)
        return cal.dateComponents([.day], from: due, to: today).day ?? 0
    }

    var isOverdue: Bool { status == .paid ? false : daysOverdue > 0 }

    var delayDaysAtPayment: Int {
        guard let paid = paidDate else { return 0 }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: dueDate),
                                  to: cal.startOfDay(for: paid)).day ?? 0
    }

    var outstanding: Decimal {
        max(0, amount - paidAmount)
    }

    var accruedInterest: Decimal {
        guard daysOverdue > 0 else { return 0 }
        var interest: Decimal = 0
        if annualInterestRate > 0 {
            interest += outstanding * annualInterestRate / 100 / 365 * Decimal(daysOverdue)
        }
        if lateFeePercent > 0 && daysOverdue >= 30 {
            interest += outstanding * lateFeePercent / 100
        }
        var rounded = Decimal()
        NSDecimalRound(&rounded, &interest, 2, .bankers)
        return rounded
    }

    var hasLateFee: Bool {
        lateFeePercent > 0 && daysOverdue >= 30
    }

    var totalDue: Decimal {
        outstanding + accruedInterest
    }

    var bucket: String {
        let days = daysOverdue
        if status == .paid { return "Paid" }
        if days <= 0 { return "Upcoming" }
        if days <= 7 { return "1-7 days" }
        if days <= 14 { return "8-14 days" }
        if days <= 30 { return "15-30 days" }
        return "30+ days"
    }

    static let bucketOrder = ["Upcoming", "Due Today", "1-7 days", "8-14 days", "15-30 days", "30+ days"]
}
