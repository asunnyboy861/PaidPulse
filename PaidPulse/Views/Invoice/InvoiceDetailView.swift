import SwiftUI
import SwiftData

struct InvoiceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let invoice: Invoice
    @Binding var showPaywall: Bool
    @Binding var celebrateInvoice: Invoice?

    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showSendPage = false
    @State private var showMarkPaid = false
    @State private var showEdit = false
    @State private var pdfData: Data?

    private var gate: EntitlementGate { EntitlementGate(isPro: purchaseManager.isPro) }
    private var currentLevel: EscalationLevel { EscalationEngine.targetLevel(for: invoice) }

    private var events: [ReminderEvent] {
        let invoiceID = invoice.id
        let descriptor = FetchDescriptor<ReminderEvent>(
            predicate: #Predicate { $0.invoiceId == invoiceID },
            sortBy: [SortDescriptor(\.sentAt, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(Currency.format(invoice.outstanding))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Spacer()
                        if invoice.daysOverdue > 0 {
                            Text("\(invoice.daysOverdue) days overdue")
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                        }
                    }
                    Text("\(invoice.number) · \(invoice.client?.name ?? "Client") · due \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if invoice.daysOverdue > 0 && (invoice.annualInterestRate > 0 || invoice.hasLateFee) {
                        Label(invoice.hasLateFee
                              ? "\(Currency.format(invoice.accruedInterest)) interest & late fee accrued — includes \(invoice.lateFeePercent)% late payment fee at 30 days"
                              : "\(Currency.format(invoice.accruedInterest)) interest accrued — \(invoice.annualInterestRate)% APR × \(invoice.daysOverdue) days",
                              systemImage: "percent")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            }
            Section("Escalation ladder") {
                StageProgressBar(currentStage: invoice.currentStage, targetStage: currentLevel.rawValue)
                if currentLevel.rawValue > invoice.currentStage {
                    Text("\(currentLevel.title) letter is ready — send it now or wait for the scheduled day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                Button {
                    if gate.canUseLevel(currentLevel) {
                        showSendPage = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Send \(currentLevel.title) Letter", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
                if !gate.canUseLevel(currentLevel) {
                    Text("L3+ letters are part of Pro.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                Button {
                    exportPDF()
                } label: {
                    Label("Export Formal Demand PDF", systemImage: "doc.richtext.fill")
                }
                if !gate.canExportPDF() {
                    Text("PDF export is part of Pro.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Payment") {
                Button {
                    showMarkPaid = true
                } label: {
                    Label("Mark Paid", systemImage: "dollarsign.circle.fill")
                        .foregroundStyle(.green)
                }
                if let client = invoice.client {
                    NavigationLink {
                        ClientProfileView(client: client)
                    } label: {
                        Label("Client: \(client.name)", systemImage: "person.crop.circle")
                    }
                }
            }
            if !events.isEmpty {
                Section("Evidence chain") {
                    ForEach(events) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(EscalationLevel(rawValue: event.level)?.title ?? "Level \(event.level)")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text(event.channel.uppercased())
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .background(Color(.tertiarySystemFill))
                                    .clipShape(Capsule())
                            }
                            Text("Sent \(event.sentAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Invoice Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit invoice")
            }
        }
        .sheet(isPresented: $showEdit) {
            EditInvoiceView(invoice: invoice)
        }
        .onAppear {
            if let advanced = EscalationEngine.advance(invoice) {
                NotificationScheduler.rebuild(for: invoice)
                _ = advanced
            }
        }
        .sheet(isPresented: $showSendPage) {
            SendPageView(invoice: invoice, showPaywall: $showPaywall)
        }
        .sheet(isPresented: $showMarkPaid) {
            MarkPaidSheet(invoice: invoice) {
                celebrateInvoice = invoice
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: Binding(get: { pdfData != nil }, set: { if !$0 { pdfData = nil } })) {
            if let data = pdfData {
                ActivityShareSheet(items: [data])
            }
        }
    }

    private func exportPDF() {
        guard gate.canExportPDF() else {
            showPaywall = true
            return
        }
        pdfData = DemandLetterPDF.generate(invoice: invoice, settings: AppSettings.shared(modelContext))
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
