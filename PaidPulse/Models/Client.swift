import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Invoice.client)
    var invoices: [Invoice] = []

    var paidInvoices: [Invoice] {
        invoices.filter { $0.status == .paid && $0.paidDate != nil }
    }

    var avgDelayDays: Int {
        let paid = paidInvoices
        guard !paid.isEmpty else { return 0 }
        let total = paid.reduce(0) { $0 + max(0, $1.delayDaysAtPayment) }
        return total / paid.count
    }

    var onTimeRate: Int {
        let paid = paidInvoices
        guard !paid.isEmpty else { return 100 }
        let onTime = paid.filter { $0.delayDaysAtPayment <= 0 }.count
        return Int((Double(onTime) / Double(paid.count) * 100).rounded())
    }

    var payScore: Int {
        let paid = paidInvoices
        guard !paid.isEmpty else { return 70 }
        let onTime = paid.filter { $0.delayDaysAtPayment <= 0 }.count
        let base = Double(onTime) / Double(paid.count) * 100
        return Int(max(0, min(100, base - Double(avgDelayDays) * 1.5)))
    }

    var payGrade: String {
        switch payScore {
        case 90...: return "A"
        case 75..<90: return "B"
        case 60..<75: return "C"
        case 40..<60: return "D"
        default: return "F"
        }
    }

    init(name: String, email: String = "", phone: String = "") {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.createdAt = .now
    }
}
