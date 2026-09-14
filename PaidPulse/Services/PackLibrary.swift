import Foundation

struct PackTemplate {
    let level: EscalationLevel
    let subject: String
    let body: String
}

enum PackLibrary {
    struct Pack {
        let id: String
        let name: String
        let description: String
        let symbol: String
        let openingVariants: [String]
        let closingVariants: [String]
    }

    static let packs: [Pack] = [
        Pack(
            id: "com.zzoutuo.PaidPulse.pack.design",
            name: "Design Studio",
            description: "Reminder letters tuned for design clients",
            symbol: "paintbrush.pointed.fill",
            openingVariants: [
                "Hi {client}, the final files for {number} wrapped up a while back, and the invoice (${amount}) is still open — now {days} days past its {dueDate} due date.",
                "Hi {client}, hope the new brand assets are landing well. One admin note: invoice {number} (${amount}) is {days} days overdue.",
                "Hi {client}, I wrapped the design work for {number} some time ago, and the ${amount} invoice is still unpaid — {days} days past due.",
                "Hi {client}, circling back on invoice {number} (${amount}) for the design work — {days} days past the {dueDate} due date now.",
                "Hi {client}, the {number} deliverables are in your hands and live in production — invoice (${amount}) is {days} days overdue."
            ],
            closingVariants: [
                "Happy to send over the source files once the balance clears.",
                "If you'd like a consolidated invoice for the project, just say the word.",
                "Ready for the next round whenever the balance is settled.",
                "Happy to provide the final handoff package after payment.",
                "Source files and usage rights transfer on payment, per our agreement."
            ]
        ),
        Pack(
            id: "com.zzoutuo.PaidPulse.pack.dev",
            name: "Dev & Agency",
            description: "Reminder letters for development and agency work",
            symbol: "chevron.left.forwardslash.chevron.right",
            openingVariants: [
                "Hi {client}, the shipped build for {number} has been in production since well before the {dueDate} due date — the invoice (${amount}) is now {days} days overdue.",
                "Hi {client}, sprint work on {number} is delivered and deployed. The ${amount} invoice is {days} days past due.",
                "Hi {client}, following up on invoice {number} (${amount}) for the development engagement — {days} days overdue now.",
                "Hi {client}, the milestone for {number} was signed off and handed over, but the ${amount} invoice remains unpaid, {days} days past due.",
                "Hi {client}, quick accounting note: invoice {number} (${amount}) for the shipped work is {days} days overdue."
            ],
            closingVariants: [
                "Happy to hop on a quick call if procurement needs anything from me.",
                "Maintenance and support hours resume once the balance is current.",
                "Deployment credentials and admin access are tied to the settled invoice.",
                "I can re-issue the invoice to a different PO or billing contact if that helps.",
                "Next milestone scheduling opens up once this one clears."
            ]
        ),
        Pack(
            id: "com.zzoutuo.PaidPulse.pack.photo",
            name: "Photography",
            description: "Reminder letters for photography clients",
            symbol: "camera.fill",
            openingVariants: [
                "Hi {client}, the full edited gallery for {number} was delivered before {dueDate}, and the invoice (${amount}) is now {days} days overdue.",
                "Hi {client}, hope you're enjoying the photos from the shoot. Invoice {number} (${amount}) is {days} days past due.",
                "Hi {client}, following up on the {number} invoice (${amount}) — {days} days past the {dueDate} due date.",
                "Hi {client}, the retouched images from {number} were handed over weeks ago; the ${amount} invoice is still open, {days} days overdue.",
                "Hi {client}, a quick note that invoice {number} (${amount}) for the shoot remains unpaid — {days} days past due."
            ],
            closingVariants: [
                "High-resolution originals and print releases follow cleared payment.",
                "Usage licensing per our agreement activates on payment.",
                "Happy to provide a few extra favorites once the balance settles.",
                "The gallery link stays live for 30 more days — payment secures archival backup.",
                "Booking for your next date opens up once this invoice is settled."
            ]
        ),
        Pack(
            id: "com.zzoutuo.PaidPulse.pack.construction",
            name: "Construction",
            description: "Reminder letters for contracting and trade work",
            symbol: "hammer.fill",
            openingVariants: [
                "Hi {client}, the work on {number} passed final inspection well before the {dueDate} due date — invoice (${amount}) is now {days} days overdue.",
                "Hi {client}, following up on invoice {number} (${amount}) for the completed work — {days} days past due.",
                "Hi {client}, all punch-list items for {number} were closed out; the ${amount} invoice remains unpaid, {days} days overdue.",
                "Hi {client}, per our contract terms, invoice {number} (${amount}) is {days} days past its {dueDate} due date.",
                "Hi {client}, materials and labor for {number} were delivered and signed off — the ${amount} invoice is {days} days overdue."
            ],
            closingVariants: [
                "Per our agreement, mechanic's lien rights may apply after 60 days past due.",
                "Warranty coverage on the completed work stays active with a current balance.",
                "I can provide lien waivers and final documentation on payment.",
                "Scheduling for the remaining project phases depends on a current account.",
                "Happy to coordinate with your lender or draw process if that's the holdup."
            ]
        )
    ]

    static func pack(id: String) -> Pack? {
        packs.first { $0.id == id }
    }

    static func templates(for pack: Pack, invoice: Invoice, settings: AppSettings) -> [PackTemplate] {
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
        var result: [PackTemplate] = []
        for level in EscalationLevel.allCases {
            let context = levelContext(level)
            for (index, opening) in pack.openingVariants.enumerated() {
                let closing = pack.closingVariants[index % pack.closingVariants.count]
                let body = [fill(opening), fill(context), fill(closing), "", fill(settings.paymentInstructions), fill(settings.businessName)].joined(separator: "\n")
                let subject = "Invoice {number} — {days} days overdue".replacingOccurrences(of: "{number}", with: invoice.number).replacingOccurrences(of: "{days}", with: "\(max(0, invoice.daysOverdue))")
                result.append(PackTemplate(level: level, subject: subject, body: body))
            }
        }
        return result
    }

    private static func levelContext(_ level: EscalationLevel) -> String {
        switch level {
        case .dueToday:
            return "The invoice is due today — a payment today keeps everything on track."
        case .politeNudge:
            return "If it's already scheduled, no worries — feel free to ignore this."
        case .friendlyFollowup:
            return "Could you confirm when payment is scheduled? Happy to help if anything is stuck."
        case .firmReminder:
            return "Please arrange payment this week. Late interest of {interest} has accrued per our agreed terms."
        case .formalDemand:
            return "This is a formal request for payment within 7 days. Interest continues to accrue daily, bringing the total to {total}."
        case .finalNotice:
            return "This is a final request. If payment isn't received within 10 business days, the balance proceeds to collections or small claims court."
        }
    }

    static var totalTemplateCount: Int {
        packs.reduce(0) { $0 + $1.openingVariants.count * EscalationLevel.allCases.count }
    }
}
