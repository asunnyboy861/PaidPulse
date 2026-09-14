import Foundation
import SwiftUI
import MessageUI
import UIKit
import SwiftData

enum SendChannel: String, CaseIterable, Identifiable {
    case mail, sms, whatsapp, copy
    var id: String { rawValue }
    var label: String {
        ["Email", "Text", "WhatsApp", "Copy"][["mail", "sms", "whatsapp", "copy"].firstIndex(of: rawValue)!]
    }
    var symbol: String {
        ["envelope.fill", "message.fill", "phone.circle.fill", "doc.on.doc.fill"][["mail", "sms", "whatsapp", "copy"].firstIndex(of: rawValue)!]
    }
}

struct RenderedLetter {
    let level: EscalationLevel
    let subject: String
    let body: String
}

enum SendService {
    static func whatsappURL(phone: String, body: String) -> URL? {
        let digits = phone.filter { $0.isNumber }
        guard let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL(string: "https://wa.me/\(digits)?text=\(encoded)")
    }

    static func mailtoURL(to: String, subject: String, body: String) -> URL? {
        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = to
        comps.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return comps.url
    }

    static func render(invoice: Invoice, level: EscalationLevel, settings: AppSettings,
                       packID: String? = nil, variantIndex: Int = 0) -> RenderedLetter {
        if let packID, let pack = PackLibrary.pack(id: packID) {
            let templates = PackLibrary.templates(for: pack, invoice: invoice, settings: settings)
            let matching = templates.filter { $0.level == level }
            if !matching.isEmpty {
                let template = matching[variantIndex % matching.count]
                return RenderedLetter(level: level, subject: template.subject, body: template.body)
            }
        }
        guard let base = TemplateLibrary.templates[level] else {
            return RenderedLetter(level: level, subject: "", body: "")
        }
        let rendered = TemplateLibrary.render(base, for: invoice, settings: settings)
        return RenderedLetter(level: level, subject: rendered.subject, body: rendered.body)
    }

    @MainActor
    static func record(invoice: Invoice, level: EscalationLevel, channel: SendChannel,
                       letter: RenderedLetter, modelContext: ModelContext) {
        let event = ReminderEvent(invoiceId: invoice.id, level: level.rawValue,
                                  channel: channel.rawValue, letterSnapshot: letter.body)
        modelContext.insert(event)
        try? modelContext.save()
        NotificationScheduler.rebuild(for: invoice)
    }

    @MainActor
    static func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}

struct MailComposer: UIViewControllerRepresentable {
    let to: String
    let subject: String
    let body: String
    let onResult: (MFMailComposeResult) -> Void

    static var canSend: Bool { MFMailComposeViewController.canSendMail() }

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([to])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onResult: @MainActor (MFMailComposeResult) -> Void
        init(onResult: @escaping @MainActor (MFMailComposeResult) -> Void) { self.onResult = onResult }
        nonisolated func mailComposeController(_ controller: MFMailComposeViewController,
                                               didFinishWith result: MFMailComposeResult, error: Error?) {
            Task { @MainActor in
                controller.dismiss(animated: true)
                self.onResult(result)
            }
        }
    }
}

struct SMSComposer: UIViewControllerRepresentable {
    let to: String
    let body: String
    let onResult: (MessageComposeResult) -> Void

    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.recipients = [to]
        vc.body = body
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onResult: @MainActor (MessageComposeResult) -> Void
        init(onResult: @escaping @MainActor (MessageComposeResult) -> Void) { self.onResult = onResult }
        nonisolated func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                                      didFinishWith result: MessageComposeResult) {
            Task { @MainActor in
                controller.dismiss(animated: true)
                self.onResult(result)
            }
        }
    }
}
