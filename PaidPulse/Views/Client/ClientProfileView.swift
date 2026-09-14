import SwiftUI
import SwiftData

struct ClientProfileView: View {
    @Environment(\.modelContext) private var modelContext
    let client: Client

    private var gradeColor: Color {
        switch client.payGrade {
        case "A": return .green
        case "B": return .blue
        case "C": return .orange
        default: return .red
        }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    PayScoreRing(score: client.payScore, grade: client.payGrade, color: gradeColor)
                        .frame(width: 84, height: 84)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.title3.bold())
                        Text("Avg delay: \(client.avgDelayDays) days · On-time: \(client.onTimeRate)%")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if !client.email.isEmpty {
                            Text(client.email).font(.caption).foregroundStyle(.secondary)
                        }
                        if !client.phone.isEmpty {
                            Text(client.phone).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            if client.payGrade == "F" && !client.invoices.isEmpty {
                Section {
                    Label("This client consistently pays late — consider requesting 50% up front on the next job.", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    Button {
                        copyDepositScript()
                    } label: {
                        Label("Copy 50% deposit request", systemImage: "doc.on.doc")
                    }
                }
            }
            Section("Invoice history") {
                if client.invoices.isEmpty {
                    Text("No invoices yet").foregroundStyle(.secondary)
                }
                ForEach(client.invoices.sorted { $0.issueDate > $1.issueDate }) { invoice in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(invoice.number).font(.subheadline.bold())
                            Spacer()
                            Text(Currency.format(invoice.amount))
                                .font(.subheadline)
                        }
                        HStack {
                            Text(statusText(invoice))
                                .font(.caption)
                                .foregroundStyle(statusColor(invoice))
                            Spacer()
                            Text(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if invoice.status == .paid {
                                Text("· paid in \(max(0, invoice.delayDaysAtPayment))d")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Client")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statusText(_ invoice: Invoice) -> String {
        switch invoice.status {
        case .paid: return "Paid"
        case .partial: return "Partial"
        case .writtenOff: return "Written off"
        case .draft: return "Draft"
        case .sent: return invoice.isOverdue ? "Overdue" : "Sent"
        }
    }

    private func statusColor(_ invoice: Invoice) -> Color {
        switch invoice.status {
        case .paid: return .green
        case .partial: return .orange
        case .writtenOff: return .secondary
        case .draft: return .secondary
        case .sent: return invoice.isOverdue ? .red : .primary
        }
    }

    private func copyDepositScript() {
        let script = """
        Hi \(client.name),

        Before we kick off the next project, I'd like to set up a 50% deposit with the balance due on delivery. This keeps the schedule locked and everything moving smoothly on both sides.

        Happy to send the updated invoice with the deposit terms today.
        """
        UIPasteboard.general.string = script
    }
}

struct PayScoreRing: View {
    let score: Int
    let grade: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: 8)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(grade)
                    .font(.title.bold())
                    .foregroundStyle(color)
                Text("\(score)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Client pay score \(score), grade \(grade)")
    }
}
