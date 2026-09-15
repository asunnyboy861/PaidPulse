import Foundation
import UIKit
import PDFKit

enum DemandLetterPDF {
    static func generate(invoice: Invoice, settings: AppSettings) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let letter = SendService.render(invoice: invoice, level: .finalNotice, settings: settings)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 56
            func draw(_ text: String, font: UIFont, color: UIColor = .black) {
                let attr: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let rect = CGRect(x: 56, y: y, width: 500, height: 400)
                let size = (text as NSString).boundingRect(
                    with: CGSize(width: 500, height: 400),
                    options: [.usesLineFragmentOrigin],
                    attributes: attr, context: nil)
                (text as NSString).draw(in: rect, withAttributes: attr)
                y += size.height + 6
            }
            draw("FORMAL DEMAND FOR PAYMENT", font: .boldSystemFont(ofSize: 18))
            y += 10
            draw("Date: \(Date.now.formatted(date: .long, time: .omitted))", font: .systemFont(ofSize: 11))
            draw("From: \(settings.businessName.isEmpty ? "Independent Contractor" : settings.businessName)", font: .systemFont(ofSize: 11))
            draw("To: \(invoice.client?.name ?? "")", font: .systemFont(ofSize: 11))
            y += 14
            draw("RE: Invoice \(invoice.number) — Outstanding balance \(Currency.format(invoice.outstanding))",
                 font: .boldSystemFont(ofSize: 12))
            y += 10
            draw("Original amount: \(Currency.format(invoice.amount))   Due date: \(invoice.dueDate.formatted(date: .long, time: .omitted))",
                 font: .systemFont(ofSize: 11))
            draw("Days past due: \(max(0, invoice.daysOverdue))   Accrued interest: \(Currency.format(invoice.accruedInterest))   Total due: \(Currency.format(invoice.totalDue))",
                 font: .systemFont(ofSize: 11))
            y += 12
            for line in letter.body.components(separatedBy: "\n") {
                if y > 720 {
                    ctx.beginPage()
                    y = 56
                }
                draw(line, font: .systemFont(ofSize: 12))
            }
            if y > 660 {
                ctx.beginPage()
                y = 56
            }
            y += 24
            if invoice.hasLateFee {
                draw("Interest & fees: \(Currency.format(invoice.outstanding)) principal × \(invoice.annualInterestRate)% annual × \(max(0, invoice.daysOverdue)) days ÷ 365, plus a \(invoice.lateFeePercent)% late payment fee applied at 30 days past due.",
                     font: .systemFont(ofSize: 10), color: .darkGray)
            } else {
                draw("Interest calculation: \(Currency.format(invoice.outstanding)) principal × \(invoice.annualInterestRate)% annual rate × \(max(0, invoice.daysOverdue)) days ÷ 365",
                     font: .systemFont(ofSize: 10), color: .darkGray)
            }
            draw("This document and its delivery record may be used as evidence of demand for payment.",
                 font: .systemFont(ofSize: 10), color: .darkGray)
        }
    }
}
