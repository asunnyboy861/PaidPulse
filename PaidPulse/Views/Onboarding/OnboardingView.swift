import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    @State private var step = 0
    @State private var clientName = ""
    @State private var amountText = ""
    @State private var dueDate = Date.now.addingTimeInterval(30 * 86400)

    var body: some View {
        VStack(spacing: 28) {
            switch step {
            case 0: welcomeStep
            case 1: formStep
            case 2: notificationStep
            default: doneStep
            }
        }
        .padding(24)
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("Get paid without the awkward.")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
            Text("PaidPulse writes the perfect follow-up at every stage of overdue — you just tap send.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                step = 1
            } label: {
                Text("Add First Invoice")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var formStep: some View {
        VStack(spacing: 20) {
            Text("Who owes you?")
                .font(.title.bold())
            VStack(spacing: 12) {
                TextField("Client name", text: $clientName)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                saveFirstInvoice()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(clientName.trimmingCharacters(in: .whitespaces).isEmpty ||
                      Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) == nil)
            Button("Skip for now") {
                step = 2
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var notificationStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("We'll remind you exactly when to follow up")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Notifications fire on each escalation day — day 0, 3, 7, 14, 30 and 45. Mark an invoice paid and they cancel automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                enableNotifications()
            } label: {
                Text("Enable Reminders")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            Button("Not now") {
                finish()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var doneStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "party.popper.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("You're set!")
                .font(.title.bold())
            Text("Your dashboard tracks every dollar owed and writes every letter for you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button {
                finish()
            } label: {
                Text("Go to Dashboard")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func saveFirstInvoice() {
        let settings = AppSettings.shared(modelContext)
        let client = Client(name: clientName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(client)
        guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        let invoice = Invoice(client: client, amount: amount, dueDate: dueDate)
        invoice.number = String(format: "INV-%04d", settings.nextInvoiceNumber)
        settings.nextInvoiceNumber += 1
        modelContext.insert(invoice)
        try? modelContext.save()
        NotificationScheduler.rebuild(for: invoice)
        step = 2
    }

    private func enableNotifications() {
        Task {
            _ = await NotificationScheduler.requestAuthorization()
            finish()
        }
    }

    private func finish() {
        onboardingComplete = true
    }
}
