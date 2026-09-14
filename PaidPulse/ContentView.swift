import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @StateObject private var purchaseManager = PurchaseManager.shared

    var body: some View {
        if onboardingComplete {
            DashboardView()
        } else {
            OnboardingView()
        }
    }
}
