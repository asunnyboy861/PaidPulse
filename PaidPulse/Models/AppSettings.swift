import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var businessName: String = ""
    var paymentInstructions: String = "Payment details: bank transfer or check. Reply to this email for invoice details."
    var defaultInterestRate: Decimal = 0
    var lateFeeEnabled: Bool = false
    var lateFeePercent: Decimal = 5
    var nextInvoiceNumber: Int = 1
    var recoveredTotal: Decimal = 0
    var paidCount: Int = 0

    init() {
        self.id = UUID()
    }

    @discardableResult
    static func shared(_ context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        return settings
    }
}
