import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false

    @State private var businessName = ""
    @State private var paymentInstructions = ""
    @State private var interestText = ""
    @State private var lateFeeEnabled = false
    @State private var lateFeeText = ""

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        Form {
            businessSection
            proSection
            packSection
            supportSection
            aboutSection
        }
        .navigationTitle("Settings")
        .onAppear(perform: loadSettings)
        .onChange(of: businessName) { _, _ in saveSettings() }
        .onChange(of: paymentInstructions) { _, _ in saveSettings() }
        .onChange(of: interestText) { _, _ in saveSettings() }
        .onChange(of: lateFeeEnabled) { _, _ in saveSettings() }
        .onChange(of: lateFeeText) { _, _ in saveSettings() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var businessSection: some View {
        Section {
            TextField("Your name / business", text: $businessName)
            TextField("Payment instructions (added to every letter)", text: $paymentInstructions, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Letter signature")
        } footer: {
            Text("These appear in every reminder letter so clients know how to pay you.")
        }
    }

    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                Label("Pro is active — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "lock.open.fill")
                        .foregroundStyle(.green)
                }
            }
            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("PaidPulse Pro")
        } footer: {
            Text("Lifetime $14.99 · Annual $9.99 with 7-day trial · Monthly $1.99")
        }
    }

    @ViewBuilder
    private var packSection: some View {
        Section("Industry voice packs") {
            ForEach(PackLibrary.packs, id: \.id) { pack in
                HStack {
                    Label(pack.name, systemImage: pack.symbol)
                    Spacer()
                    if purchaseManager.ownedPacks.contains(pack.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("$2.99")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if !purchaseManager.isPro || purchaseManager.packProducts.count != purchaseManager.ownedPacks.count {
                Button("Browse packs") {
                    showPaywall = true
                }
                .font(.footnote)
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                ContactSupportView()
            } label: {
                Label("Contact Support", systemImage: "bubble.left.and.bubble.right.fill")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/PaidPulse/support.html")!) {
                Label("Help & FAQ", systemImage: "questionmark.circle")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/PaidPulse/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/PaidPulse/terms.html")!) {
                Label("Terms of Use", systemImage: "doc.text.fill")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Button {
                requestReview()
            } label: {
                Label("Rate PaidPulse", systemImage: "star.fill")
            }
        } footer: {
            Text(appVersion)
        }
    }

    private func loadSettings() {
        let settings = AppSettings.shared(modelContext)
        businessName = settings.businessName
        paymentInstructions = settings.paymentInstructions
        interestText = "\(NSDecimalNumber(decimal: settings.defaultInterestRate).doubleValue)"
        lateFeeEnabled = settings.lateFeeEnabled
        lateFeeText = "\(NSDecimalNumber(decimal: settings.lateFeePercent).doubleValue)"
    }

    private func saveSettings() {
        let settings = AppSettings.shared(modelContext)
        settings.businessName = businessName
        settings.paymentInstructions = paymentInstructions
        settings.defaultInterestRate = Decimal(string: interestText.replacingOccurrences(of: ",", with: ".")) ?? 0
        settings.lateFeeEnabled = lateFeeEnabled
        settings.lateFeePercent = Decimal(string: lateFeeText.replacingOccurrences(of: ",", with: ".")) ?? 0
        try? modelContext.save()
    }
}
