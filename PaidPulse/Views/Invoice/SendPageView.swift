import SwiftUI
import SwiftData
import MessageUI

struct SendPageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let invoice: Invoice
    @Binding var showPaywall: Bool
    var onSent: (() -> Void)?

    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var level: Int = 0
    @State private var subject = ""
    @State private var bodyText = ""
    @State private var selectedPackID: String?
    @State private var showMail = false
    @State private var showSMS = false
    @State private var showSentConfirmation = false

    private var gate: EntitlementGate { EntitlementGate(isPro: purchaseManager.isPro) }
    private var currentLevel: EscalationLevel { EscalationLevel(rawValue: level) ?? .dueToday }
    private var toneColor: Color {
        switch currentLevel.toneColorName {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        default: return .red
        }
    }
    private var ownedPacks: [PackLibrary.Pack] {
        PackLibrary.packs.filter { purchaseManager.ownedPacks.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    levelPicker
                    toneChip
                    letterEditor
                    packPicker
                    sendButtons
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Send Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear(perform: renderLetter)
            .onChange(of: level) { _, _ in renderLetter() }
            .onChange(of: selectedPackID) { _, _ in renderLetter() }
            .sheet(isPresented: $showMail) {
                MailComposer(to: invoice.client?.email ?? "", subject: subject, body: bodyText) { result in
                    if result == .sent || result == .saved {
                        record(.mail)
                    }
                }
            }
            .sheet(isPresented: $showSMS) {
                SMSComposer(to: invoice.client?.phone ?? "", body: bodyText) { result in
                    if result == .sent {
                        record(.sms)
                    }
                }
            }
            .alert("Sent & filed", isPresented: $showSentConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This letter is saved in the evidence chain, and your next follow-up is scheduled.")
            }
        }
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Escalation level")
                .font(.footnote.bold())
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EscalationLevel.allCases) { lvl in
                        Button {
                            if gate.canUseLevel(lvl) {
                                level = lvl.rawValue
                            } else {
                                showPaywall = true
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Text(lvl.title)
                                    .font(.caption.bold())
                                Text(lvl.triggerDay == 0 ? "due today" : "+\(lvl.triggerDay)d")
                                    .font(.system(size: 9))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(level == lvl.rawValue ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                            .foregroundStyle(level == lvl.rawValue ? Color.white : Color.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(gate.canUseLevel(lvl) ? Color.clear : Color(.systemFill), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(lvl.title), level \(lvl.rawValue + 1) of 6")
                    }
                }
            }
        }
    }

    private var toneChip: some View {
        Label("\(currentLevel.tone) tone", systemImage: "waveform.path")
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(toneColor.opacity(0.15))
            .foregroundStyle(toneColor)
            .clipShape(Capsule())
    }

    private var letterEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Subject", text: $subject)
                .font(.headline)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            TextEditor(text: $bodyText)
                .font(.body)
                .frame(minHeight: 220)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel("Letter body, editable")
        }
    }

    @ViewBuilder
    private var packPicker: some View {
        if !ownedPacks.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Industry voice")
                    .font(.footnote.bold())
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        packChip(name: "Standard", symbol: "text.bubble", id: nil)
                        ForEach(ownedPacks, id: \.id) { pack in
                            packChip(name: pack.name, symbol: pack.symbol, id: pack.id)
                        }
                    }
                }
            }
        }
    }

    private func packChip(name: String, symbol: String, id: String?) -> some View {
        Button {
            selectedPackID = id
        } label: {
            Label(name, systemImage: symbol)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedPackID == id ? Color.accentColor.opacity(0.2) : Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var sendButtons: some View {
        VStack(spacing: 10) {
            sendButton(.mail, symbol: "envelope.fill", label: "Send via Email",
                       enabled: invoice.client?.email.isEmpty == false && (MailComposer.canSend || invoice.client?.email.isEmpty == false))
            sendButton(.sms, symbol: "message.fill", label: "Send via Text",
                       enabled: invoice.client?.phone.isEmpty == false)
            sendButton(.whatsapp, symbol: "phone.circle.fill", label: "Send via WhatsApp",
                       enabled: invoice.client?.phone.isEmpty == false)
            sendButton(.copy, symbol: "doc.on.doc.fill", label: "Copy Letter",
                       enabled: true)
        }
    }

    private func sendButton(_ channel: SendChannel, symbol: String, label: String, enabled: Bool) -> some View {
        Button {
            send(channel)
        } label: {
            Label(label, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .disabled(!enabled)
        .accessibilityHint(enabled ? "" : "Add a phone number or email to this client first")
    }

    private func renderLetter() {
        let letter = SendService.render(invoice: invoice, level: currentLevel,
                                        settings: AppSettings.shared(modelContext),
                                        packID: selectedPackID)
        subject = letter.subject
        bodyText = letter.body
    }

    private func send(_ channel: SendChannel) {
        switch channel {
        case .mail:
            if MailComposer.canSend {
                showMail = true
            } else if let url = SendService.mailtoURL(to: invoice.client?.email ?? "",
                                                      subject: subject, body: bodyText) {
                SendService.open(url)
                record(channel)
            }
        case .sms:
            if SMSComposer.canSend {
                showSMS = true
            } else if let url = URL(string: "sms:\(invoice.client?.phone ?? "")?body=\(bodyText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                SendService.open(url)
                record(channel)
            }
        case .whatsapp:
            if let url = SendService.whatsappURL(phone: invoice.client?.phone ?? "", body: bodyText) {
                SendService.open(url)
                record(channel)
            }
        case .copy:
            UIPasteboard.general.string = "Subject: \(subject)\n\n\(bodyText)"
            record(channel)
        }
    }

    private func record(_ channel: SendChannel) {
        let letter = RenderedLetter(level: currentLevel, subject: subject, body: bodyText)
        SendService.record(invoice: invoice, level: currentLevel, channel: channel,
                           letter: letter, modelContext: modelContext)
        showSentConfirmation = true
        onSent?()
    }
}
