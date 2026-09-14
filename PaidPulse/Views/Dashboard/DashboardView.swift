import SwiftUI
import SwiftData
import StoreKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Query(filter: #Predicate<Invoice> { !$0.statusRaw.contains("paid") }, sort: \Invoice.dueDate)
    private var activeInvoices: [Invoice]
    @Query(sort: \Invoice.paidDate, order: .reverse) private var paidInvoices: [Invoice]
    @Query private var clients: [Client]
    @StateObject private var purchaseManager = PurchaseManager.shared

    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @State private var showAddInvoice = false
    @State private var showChaseAll = false
    @State private var showPaywall = false
    @State private var celebrateInvoice: Invoice?
    @State private var deepLinkInvoice: Invoice?

    private var gate: EntitlementGate { EntitlementGate(isPro: purchaseManager.isPro) }

    private var outstandingTotal: Decimal {
        activeInvoices.reduce(0) { $0 + $1.outstanding }
    }
    private var overdueCount: Int {
        activeInvoices.filter { $0.isOverdue }.count
    }
    private var recoveredTotal: Decimal {
        AppSettings.shared(modelContext).recoveredTotal
    }

    private var buckets: [(String, [Invoice])] {
        let groups = Dictionary(grouping: activeInvoices) { $0.bucket }
        let order = ["Upcoming", "Due Today", "1-7 days", "8-14 days", "15-30 days", "30+ days"]
        return order.compactMap { key in
            guard let items = groups[key], !items.isEmpty else { return nil }
            return (key, items.sorted { $0.daysOverdue > $1.daysOverdue })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statsRow
                    chaseAllButton
                    bucketList
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PaidPulse")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddInvoice = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Add invoice")
                }
            }
            .sheet(isPresented: $showAddInvoice, onDismiss: { syncWidget() }) {
                AddInvoiceView(showPaywall: $showPaywall)
            }
            .sheet(isPresented: $showChaseAll) {
                ChaseAllSheet(showPaywall: $showPaywall)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $deepLinkInvoice) { invoice in
                SendPageView(invoice: invoice, showPaywall: $showPaywall)
            }
            .overlay {
                if let invoice = celebrateInvoice {
                    CelebrationView(invoice: invoice, recoveredTotal: recoveredTotal) {
                        celebrateInvoice = nil
                        syncWidget()
                        if AppSettings.shared(modelContext).paidCount == 3 {
                            requestReview()
                        }
                    }
                    .zIndex(10)
                }
            }
            .onOpenURL { url in
                guard url.scheme == "paidpulse", url.host == "invoice",
                      let idString = url.pathComponents.last,
                      let id = UUID(uuidString: idString) else { return }
                let descriptor = FetchDescriptor<Invoice>(predicate: #Predicate { $0.id == id })
                deepLinkInvoice = try? modelContext.fetch(descriptor).first
            }
            .onAppear { syncWidget() }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(title: "Outstanding", value: Currency.format(outstandingTotal), color: .primary)
            StatCard(title: "Overdue", value: "\(overdueCount)", color: overdueCount > 0 ? .red : .primary)
            StatCard(title: "Recovered", value: Currency.format(recoveredTotal), color: .green)
        }
    }

    private var chaseAllButton: some View {
        Button {
            let actionable = activeInvoices.filter { $0.daysOverdue >= 0 }
            if actionable.allSatisfy({ gate.canUseLevel(EscalationLevel.stage(forDaysOverdue: $0.daysOverdue)) }) {
                showChaseAll = true
            } else {
                showPaywall = true
            }
        } label: {
            Label("Chase All", systemImage: "paperplane.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(activeInvoices.filter { $0.daysOverdue >= 0 }.isEmpty)
        .accessibilityLabel("Send reminders for all actionable invoices")
    }

    private var bucketList: some View {
        VStack(spacing: 16) {
            if buckets.isEmpty && paidInvoices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("No invoices yet")
                        .font(.title3.bold())
                    Text("Add your first invoice and let PaidPulse handle the awkward part.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Add First Invoice") { showAddInvoice = true }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top, 60)
            }
            ForEach(buckets, id: \.0) { bucket, invoices in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(bucket)
                            .font(.footnote.bold())
                            .textCase(.uppercase)
                            .foregroundStyle(bucketColor(bucket))
                        Spacer()
                        Text(Currency.format(invoices.reduce(0) { $0 + $1.outstanding }))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 0) {
                        ForEach(invoices) { invoice in
                            InvoiceRowView(invoice: invoice, showPaywall: $showPaywall,
                                           celebrateInvoice: $celebrateInvoice)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func bucketColor(_ bucket: String) -> Color {
        switch bucket {
        case "Upcoming": return .orange
        case "Due Today", "1-7 days": return .red.opacity(0.8)
        case "8-14 days", "15-30 days": return .red
        case "30+ days": return .purple
        default: return .secondary
        }
    }

    private func syncWidget() {
        let chased = activeInvoices.filter { invoice in
            let invoiceID = invoice.id
            let descriptor = FetchDescriptor<ReminderEvent>(predicate: #Predicate { $0.invoiceId == invoiceID })
            return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
        }.count
        WidgetBridge.update(outstanding: outstandingTotal, overdueCount: overdueCount,
                            chasedCount: chased, isPro: purchaseManager.isPro)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color == .primary ? Color.primary : color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
