import SwiftUI
import SwiftData

struct ChaseAllSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Binding var showPaywall: Bool
    @Query(filter: #Predicate<Invoice> { !$0.statusRaw.contains("paid") && !$0.statusRaw.contains("written") }, sort: \Invoice.dueDate)
    private var activeInvoices: [Invoice]

    private var actionable: [Invoice] {
        activeInvoices.filter { $0.daysOverdue >= 0 }.sorted { $0.daysOverdue > $1.daysOverdue }
    }

    @State private var completed: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                if actionable.isEmpty {
                    Text("Nothing to chase — every overdue invoice has been handled.")
                        .foregroundStyle(.secondary)
                }
                ForEach(actionable) { invoice in
                    let level = EscalationLevel.stage(forDaysOverdue: invoice.daysOverdue)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(invoice.client?.name ?? "Client")
                                .font(.headline)
                            Text("\(invoice.number) · \(level.title)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if completed.contains(invoice.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            NavigationLink {
                                SendPageView(invoice: invoice, showPaywall: $showPaywall) {
                                    completed.insert(invoice.id)
                                }
                            } label: {
                                Text("Send")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                if completed.count == actionable.count && !actionable.isEmpty {
                    Label("All chased — next follow-up dates are scheduled.", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline.bold())
                }
            }
            .navigationTitle("Chase All")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
