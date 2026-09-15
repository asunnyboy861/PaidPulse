import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Binding var showPaywall: Bool
    @StateObject private var purchaseManager = PurchaseManager.shared

    @Query private var clients: [Client]
    @Query(filter: #Predicate<Invoice> { !$0.statusRaw.contains("paid") && !$0.statusRaw.contains("written") })
    private var activeInvoices: [Invoice]

    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var clientPhone = ""
    @State private var amountText = ""
    @State private var dueDate = Date.now.addingTimeInterval(30 * 86400)
    @State private var termsDays: Int = 30
    @State private var interestText = ""
    @State private var note = ""
    @State private var showPaywallInline = false
    @State private var defaultsLoaded = false

    private var gate: EntitlementGate { EntitlementGate(isPro: purchaseManager.isPro) }

    private var nameSuggestions: [String] {
        guard !clientName.isEmpty else { return [] }
        return clients.map { $0.name }.filter { $0.localizedCaseInsensitiveContains(clientName) && $0 != clientName }
    }

    private var canSave: Bool {
        !clientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !amountText.isEmpty && Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Client name", text: $clientName)
                        .accessibilityLabel("Client name")
                    if !nameSuggestions.isEmpty {
                        ForEach(nameSuggestions.prefix(3), id: \.self) { suggestion in
                            Button {
                                clientName = suggestion
                                if let existing = clients.first(where: { $0.name == suggestion }) {
                                    clientEmail = existing.email
                                    clientPhone = existing.phone
                                }
                            } label: {
                                Label(suggestion, systemImage: "person.crop.circle")
                                    .font(.subheadline)
                            }
                        }
                    }
                    TextField("Email (optional)", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone (optional)", text: $clientPhone)
                        .keyboardType(.phonePad)
                }
                Section("Invoice") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Terms", selection: $termsDays) {
                        Text("Net 15").tag(15)
                        Text("Net 30").tag(30)
                        Text("Net 45").tag(45)
                        Text("Custom").tag(0)
                    }
                    if termsDays == 0 {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    } else {
                        DatePicker("Due date", selection: Binding(
                            get: { dueDate },
                            set: { dueDate = $0 }
                        ), displayedComponents: .date)
                        .onChange(of: termsDays) { _, newValue in
                            dueDate = Calendar.current.date(byAdding: .day, value: newValue, to: Calendar.current.startOfDay(for: .now)) ?? dueDate
                        }
                    }
                    if purchaseManager.isPro {
                        TextField("Annual interest % (optional)", text: $interestText)
                            .keyboardType(.decimalPad)
                    } else {
                        Label("Annual interest % — Pro", systemImage: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    TextField("Note (optional)", text: $note)
                }
                Section {
                    Button {
                        save()
                    } label: {
                        Text("Add Invoice")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .listRowBackground(Color.clear)
                } footer: {
                    if !purchaseManager.isPro {
                        Text("Free plan: \(activeInvoices.count) of \(EntitlementGate.freeActiveInvoiceLimit) active invoices used.")
                    }
                }
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                guard !defaultsLoaded else { return }
                defaultsLoaded = true
                let settings = AppSettings.shared(modelContext)
                if settings.defaultInterestRate > 0 {
                    interestText = "\(NSDecimalNumber(decimal: settings.defaultInterestRate).doubleValue)"
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywallInline) { PaywallView() }
        }
    }

    private func save() {
        let trimmedName = clientName.trimmingCharacters(in: .whitespaces)
        guard canSave, let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else { return }

        if !gate.canAddInvoice(activeCount: activeInvoices.count) {
            showPaywallInline = true
            return
        }

        let settings = AppSettings.shared(modelContext)
        let client = clients.first { $0.name.lowercased() == trimmedName.lowercased() } ?? {
            let newClient = Client(name: trimmedName, email: clientEmail, phone: clientPhone)
            modelContext.insert(newClient)
            return newClient
        }()

        let interest = purchaseManager.isPro ? (Decimal(string: interestText.replacingOccurrences(of: ",", with: ".")) ?? 0) : 0
        let lateFee = settings.lateFeeEnabled ? settings.lateFeePercent : 0
        let invoice = Invoice(client: client, amount: amount, dueDate: dueDate,
                              annualInterestRate: interest, lateFeePercent: lateFee, note: note)
        invoice.number = String(format: "INV-%04d", settings.nextInvoiceNumber)
        settings.nextInvoiceNumber += 1
        modelContext.insert(invoice)
        try? modelContext.save()
        NotificationScheduler.rebuild(for: invoice)
        dismiss()
    }
}
