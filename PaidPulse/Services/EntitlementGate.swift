import Foundation

struct EntitlementGate {
    let isPro: Bool

    static let freeActiveInvoiceLimit = 3
    static let freeMaxLevel = 2

    init(isPro: Bool) { self.isPro = isPro }

    func canAddInvoice(activeCount: Int) -> Bool {
        isPro || activeCount < Self.freeActiveInvoiceLimit
    }

    func canUseLevel(_ level: EscalationLevel) -> Bool {
        isPro || level.rawValue <= Self.freeMaxLevel
    }

    func canExportPDF() -> Bool { isPro }

    func canUseWidgets() -> Bool { isPro }

    var upsellMessage: String {
        isPro ? "" : "Upgrade to Pro to unlock unlimited invoices and all 6 escalation levels."
    }
}
