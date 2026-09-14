import Foundation

enum WidgetBridge {
    static let suiteName = "group.com.zzoutuo.PaidPulse"

    static func update(outstanding: Decimal, overdueCount: Int, chasedCount: Int, isPro: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set((outstanding as NSDecimalNumber).doubleValue, forKey: "outstanding")
        defaults.set(overdueCount, forKey: "overdueCount")
        defaults.set(chasedCount, forKey: "chasedCount")
        defaults.set(isPro, forKey: "isPro")
    }
}
