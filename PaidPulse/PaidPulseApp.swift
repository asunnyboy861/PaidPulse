import SwiftUI
import SwiftData

@main
struct PaidPulseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Client.self, Invoice.self, ReminderEvent.self, AppSettings.self])
    }
}
