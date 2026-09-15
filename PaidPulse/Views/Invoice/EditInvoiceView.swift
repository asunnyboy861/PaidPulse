import SwiftUI
import SwiftData

struct EditInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var purchaseManager = PurchaseManager.shared
    let invoice: Invoice

    @State private var amountText = ""
    @State private var dueDate = Date.now
    @State private var interestText = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Invoice") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    if purchaseManager.isPro {
                        TextField("Annual interest %", text: $interestText)
                            .keyboardType(.decimalPad)
                    } else {
                        Label("Annual interest % — Pro", systemImage: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Button {
                        save()
                    } label: {
                        Text("Save Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .disabled(!canSave)
                } footer: {
                    Text("Client contact details can be edited from the client profile. Reminders are rescheduled automatically.")
                }
            }
            .navigationTitle("Edit Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: load)
        }
    }

    private var canSave: Bool {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func load() {
        amountText = "\(NSDecimalNumber(decimal: invoice.amount).doubleValue)"
        dueDate = invoice.dueDate
        interestText = "\(NSDecimalNumber(decimal: invoice.annualInterestRate).doubleValue)"
        note = invoice.projectNote
    }

    private func save() {
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        invoice.amount = amount
        invoice.dueDate = dueDate
        if purchaseManager.isPro {
            invoice.annualInterestRate = Decimal(string: interestText.replacingOccurrences(of: ",", with: ".")) ?? 0
        }
        invoice.projectNote = note
        if invoice.paidAmount > amount {
            invoice.paidAmount = amount
        }
        try? modelContext.save()
        NotificationScheduler.rebuild(for: invoice)
        dismiss()
    }
}
