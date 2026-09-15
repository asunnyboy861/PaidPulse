import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var purchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    featureList
                    lifetimeCard
                    subscriptionCards
                    packSection
                    restoreButton
                    legalLinks
                    autoRenewalDisclosure
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PaidPulse Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                if purchaseManager.products.isEmpty {
                    await purchaseManager.refresh()
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)
            Text("Unlock the full chase")
                .font(.title.bold())
            Text("Unlimited invoices, all 6 escalation levels, interest tracking, demand-letter PDFs, and widgets.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 10) {
            featureRow("infinity", "Unlimited active invoices")
            featureRow("arrow.up.forward.circle.fill", "All 6 escalation letters (L0–L5)")
            featureRow("percent", "Late interest calculator")
            featureRow("doc.richtext.fill", "Formal Demand Letter PDF")
            featureRow("square.grid.2x2.fill", "Home screen + lock screen widgets")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func featureRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(.green)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    private var lifetimeCard: some View {
        VStack(spacing: 10) {
            Text("BEST VALUE — PAY ONCE")
                .font(.caption2.bold())
                .foregroundStyle(.green)
            Button {
                purchase(purchaseManager.lifetimeProduct)
            } label: {
                VStack(spacing: 3) {
                    Text("PaidPulse Pro Lifetime")
                        .font(.headline)
                    Text(priceLabel(for: purchaseManager.lifetimeProduct, fallback: "$14.99 once"))
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchaseManager.lifetimeProduct == nil && purchaseManager.products.isEmpty)
            Text("No renewals. Ever.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var subscriptionCards: some View {
        VStack(spacing: 10) {
            if let yearly = purchaseManager.yearlyProduct {
                Button {
                    purchase(yearly)
                } label: {
                    VStack(spacing: 3) {
                        Text("Annual — \(yearly.displayPrice)/year")
                            .font(.subheadline.bold())
                        Text("7-day free trial included")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            if let monthly = purchaseManager.monthlyProduct {
                Button {
                    purchase(monthly)
                } label: {
                    Text("Monthly — \(monthly.displayPrice)/month")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            if purchaseManager.products.isEmpty {
                VStack(spacing: 8) {
                    if purchaseManager.isLoading {
                        ProgressView()
                    } else {
                        Text(purchaseManager.loadError ?? "Purchase options are loading…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task { await purchaseManager.refresh() }
                        }
                        .font(.footnote.bold())
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    private var packSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INDUSTRY VOICE PACKS — $2.99 EACH")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            ForEach(PackLibrary.packs, id: \.id) { pack in
                packRow(pack)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func packRow(_ pack: PackLibrary.Pack) -> some View {
        HStack(spacing: 10) {
            Image(systemName: pack.symbol)
                .foregroundStyle(.green)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(pack.name)
                    .font(.subheadline)
                Text("30+ letters · \(pack.description.lowercased())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if purchaseManager.ownedPacks.contains(pack.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("\(pack.name) owned")
            } else if let product = purchaseManager.packProducts.first(where: { $0.id == pack.id }) {
                Button {
                    purchase(product)
                } label: {
                    Text(product.displayPrice)
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .tint(.green)
            } else {
                Text("$2.99")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await purchaseManager.restorePurchases() }
        }
        .font(.footnote)
    }

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Privacy Policy", destination: URL(string: "https://asunnyboy861.github.io/PaidPulse/privacy.html")!)
            Link("Terms of Use", destination: URL(string: "https://asunnyboy861.github.io/PaidPulse/terms.html")!)
        }
        .font(.caption2)
        .padding(.top, 4)
    }

    private var autoRenewalDisclosure: some View {
        Text("Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
    }

    private func priceLabel(for product: Product?, fallback: String) -> String {
        product.map { "\($0.displayPrice) once" } ?? fallback
    }

    private func purchase(_ product: Product?) {
        guard let product else { return }
        purchasing = true
        errorMessage = nil
        Task {
            let success = await purchaseManager.purchase(product)
            purchasing = false
            if success {
                dismiss()
            } else if let error = purchaseManager.loadError {
                errorMessage = error
            }
        }
    }
}
