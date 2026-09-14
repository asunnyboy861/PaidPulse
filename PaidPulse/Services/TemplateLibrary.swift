import Foundation

enum Currency {
    static func format(_ value: Decimal) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

struct LetterTemplate {
    let level: EscalationLevel
    let subjectTemplate: String
    let bodyTemplate: String
}

enum TemplateLibrary {
    static let templates: [EscalationLevel: LetterTemplate] = [
        .dueToday: LetterTemplate(
            level: .dueToday,
            subjectTemplate: "Invoice {number} is due today",
            bodyTemplate: """
            Hi {client},

            Quick heads-up that invoice {number} (${amount}) is due today.

            If it's already scheduled, feel free to ignore this note.

            {paymentInstructions}
            {senderName}
            """
        ),
        .politeNudge: LetterTemplate(
            level: .politeNudge,
            subjectTemplate: "Invoice {number} — just a quick nudge",
            bodyTemplate: """
            Hi {client},

            Just floating invoice {number} (${amount}) to the top of your inbox — it was due on {dueDate}.

            If it's already scheduled, no worries, feel free to ignore this. Otherwise, a payment this week would be a huge help.

            {paymentInstructions}
            {senderName}
            """
        ),
        .friendlyFollowup: LetterTemplate(
            level: .friendlyFollowup,
            subjectTemplate: "Following up on invoice {number}",
            bodyTemplate: """
            Hi {client},

            Following up on invoice {number} for ${amount}, which was due on {dueDate} — one week past due now.

            Could you let me know when payment is scheduled? If anything is holding it up on your end, happy to work with you.

            {paymentInstructions}
            {senderName}
            """
        ),
        .firmReminder: LetterTemplate(
            level: .firmReminder,
            subjectTemplate: "Invoice {number} is {days} days overdue",
            bodyTemplate: """
            Hi {client},

            Invoice {number} for ${amount} is now {days} days past its {dueDate} due date. Accrued late interest to date: {interest} (per our agreed terms).

            Please confirm the payment date this week, or let me know if there's an issue on your side I should know about.

            {paymentInstructions}
            {senderName}
            """
        ),
        .formalDemand: LetterTemplate(
            level: .formalDemand,
            subjectTemplate: "Formal demand for payment — invoice {number}",
            bodyTemplate: """
            {client},

            Invoice {number} (${amount}) is now {days} days past due. Accrued interest of {interest} brings the total outstanding to {total}.

            This is a formal request for payment within 7 days. Per our terms, interest continues to accrue daily until the balance is settled.

            {paymentInstructions}
            {senderName}
            """
        ),
        .finalNotice: LetterTemplate(
            level: .finalNotice,
            subjectTemplate: "FINAL NOTICE — Invoice {number}",
            bodyTemplate: """
            {client},

            Despite previous reminders, invoice {number} (${amount} plus {interest} in accrued interest, total {total}) remains unpaid {days} days past due.

            This is a final request for payment within 10 business days. After that date, the balance will be handed to collections or pursued via small claims court, and this letter + delivery record will serve as documentation.

            {paymentInstructions}
            {senderName}
            """
        )
    ]

    static func render(_ template: LetterTemplate, for invoice: Invoice, settings: AppSettings) -> (subject: String, body: String) {
        let vars: [String: String] = [
            "client": invoice.client?.name.isEmpty == false ? invoice.client!.name : "there",
            "number": invoice.number,
            "amount": Currency.format(invoice.outstanding),
            "days": "\(max(0, invoice.daysOverdue))",
            "dueDate": invoice.dueDate.formatted(date: .abbreviated, time: .omitted),
            "interest": Currency.format(invoice.accruedInterest),
            "total": Currency.format(invoice.totalDue),
            "senderName": settings.businessName,
            "paymentInstructions": settings.paymentInstructions
        ]
        func fill(_ s: String) -> String {
            vars.reduce(s) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
        }
        return (fill(template.subjectTemplate), fill(template.bodyTemplate))
    }
}
