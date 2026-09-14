import SwiftUI
import SwiftData

struct InvoiceRowView: View {
    @Environment(\.modelContext) private var modelContext
    let invoice: Invoice
    @Binding var showPaywall: Bool
    @Binding var celebrateInvoice: Invoice?

    @State private var showDetail = false
    @State private var showMarkPaid = false

    private var hasChased: Bool {
        let invoiceID = invoice.id
        let descriptor = FetchDescriptor<ReminderEvent>(predicate: #Predicate { $0.invoiceId == invoiceID })
        return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(invoice.client?.name ?? "Client")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if hasChased {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    Text("\(invoice.number) · due \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(Currency.format(invoice.outstanding))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    if invoice.daysOverdue > 0 {
                        Text("\(invoice.daysOverdue)d overdue")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    } else {
                        Text("Due \(invoice.daysOverdue == 0 ? "today" : "in \(-invoice.daysOverdue)d")")
                            .font(.caption2)
                            .foregroundStyle(invoice.daysOverdue == 0 ? .orange : .secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                showMarkPaid = true
            } label: {
                Label("Paid", systemImage: "dollarsign.circle.fill")
            }
            .tint(.green)
        }
        .contextMenu {
            Button {
                showMarkPaid = true
            } label: {
                Label("Mark Paid", systemImage: "dollarsign.circle.fill")
            }
            Button(role: .destructive) {
                deleteInvoice()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .navigationDestination(isPresented: $showDetail) {
            InvoiceDetailView(invoice: invoice, showPaywall: $showPaywall,
                              celebrateInvoice: $celebrateInvoice)
        }
        .sheet(isPresented: $showMarkPaid) {
            MarkPaidSheet(invoice: invoice) {
                celebrateInvoice = invoice
            }
            .presentationDetents([.medium])
        }
    }

    private func deleteInvoice() {
        NotificationScheduler.cancelAll(for: invoice)
        modelContext.delete(invoice)
        try? modelContext.save()
    }
}

struct MarkPaidSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let invoice: Invoice
    let onComplete: () -> Void

    @State private var paidAmountText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment received") {
                    TextField("Amount paid", text: $paidAmountText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Button {
                        markPaid()
                    } label: {
                        Text("Mark Paid")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                } footer: {
                    Text("This cancels all scheduled reminders for this invoice.")
                }
            }
            .navigationTitle("Mark Paid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                paidAmountText = "\(NSDecimalNumber(decimal: invoice.outstanding).doubleValue)"
            }
        }
    }

    private func markPaid() {
        let amount = Decimal(string: paidAmountText.replacingOccurrences(of: ",", with: ".")) ?? invoice.outstanding
        invoice.paidAmount = min(amount, invoice.amount)
        invoice.paidDate = .now
        invoice.status = invoice.paidAmount >= invoice.amount ? .paid : .partial
        let settings = AppSettings.shared(modelContext)
        settings.recoveredTotal += invoice.paidAmount
        settings.paidCount += 1
        NotificationScheduler.cancelAll(for: invoice)
        try? modelContext.save()
        onComplete()
        dismiss()
    }
}
