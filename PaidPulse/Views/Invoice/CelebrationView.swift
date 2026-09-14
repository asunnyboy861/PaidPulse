import SwiftUI
import SwiftData
import AudioToolbox
import UIKit

struct CelebrationView: View {
    @Environment(\.modelContext) private var modelContext
    let invoice: Invoice
    let recoveredTotal: Decimal
    let onFinish: () -> Void

    @State private var particles: [ConfettiParticle] = []
    @State private var appear = false
    @State private var showShareCard = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.green.opacity(0.9), .green.opacity(0.7), .teal.opacity(0.6)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    for particle in particles {
                        let date = timeline.date.timeIntervalSinceReferenceDate
                        let p = particle.position(at: date, in: size)
                        let rect = CGRect(x: p.x, y: p.y, width: particle.size, height: particle.size * 0.6)
                        context.opacity = particle.opacity(at: date)
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    }
                }
            }
            .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.white)
                Text("Cha-ching!")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(Currency.format(invoice.paidAmount)) recovered")
                    .font(.title2.bold())
                    .foregroundStyle(.white.opacity(0.95))
                Text("Total recovered: \(Currency.format(recoveredTotal))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                HStack(spacing: 12) {
                    Button {
                        showShareCard = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    Button {
                        onFinish()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(.white)
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12)
            }
            .scaleEffect(appear ? 1 : 0.6)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appear = true }
            particles = ConfettiParticle.generate(count: 80)
            AudioServicesPlaySystemSound(1021)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .sheet(isPresented: $showShareCard) {
            RecoveryShareCard(recoveredTotal: recoveredTotal)
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let velocity: Double
    let angle: Double
    let spin: Double
    let size: CGFloat
    let color: Color
    let start: Double

    static let palette: [Color] = [.green, .yellow, .orange, .white, .mint, .teal]

    static func generate(count: Int) -> [ConfettiParticle] {
        (0..<count).map { _ in
            ConfettiParticle(
                origin: CGPoint(x: .random(in: 0...1), y: 0.2),
                velocity: .random(in: 0.25...0.55),
                angle: .random(in: -0.4...0.4),
                spin: .random(in: 1...3),
                size: .random(in: 6...12),
                color: palette.randomElement() ?? .green,
                start: Date.timeIntervalSinceReferenceDate
            )
        }
    }

    func position(at date: TimeInterval, in size: CGSize) -> CGPoint {
        let t = date - start
        let x = origin.x * size.width + sin(t * spin + angle) * 30 * CGFloat(angle.sign == .plus ? 1 : -1)
        let y = origin.y * size.height + CGFloat(t * velocity * 400)
        return CGPoint(x: x, y: y)
    }

    func opacity(at date: TimeInterval) -> Double {
        let t = date - start
        return max(0, min(1, 2.2 - t * 0.55))
    }
}

struct RecoveryShareCard: View {
    let recoveredTotal: Decimal

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("PaidPulse helped me recover")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(Currency.format(recoveredTotal))
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(.green)
            Text("Stop chasing. Start getting paid.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            ShareLink(item: "PaidPulse helped me recover \(Currency.format(recoveredTotal)) in overdue invoices. Stop chasing. Start getting paid.") {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
