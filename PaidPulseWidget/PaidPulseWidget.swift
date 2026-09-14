import WidgetKit
import SwiftUI

struct WidgetSummary {
    var outstanding: Double = 0
    var overdueCount: Int = 0
    var chasedCount: Int = 0
    var isPro: Bool = false

    static func load() -> WidgetSummary {
        guard let defaults = UserDefaults(suiteName: "group.com.zzoutuo.PaidPulse") else { return WidgetSummary() }
        return WidgetSummary(
            outstanding: defaults.double(forKey: "outstanding"),
            overdueCount: defaults.integer(forKey: "overdueCount"),
            chasedCount: defaults.integer(forKey: "chasedCount"),
            isPro: defaults.bool(forKey: "isPro")
        )
    }

    var outstandingText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: outstanding)) ?? "$0"
    }
}

struct SummaryEntry: TimelineEntry {
    let date: Date
    let summary: WidgetSummary
}

struct SummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SummaryEntry {
        SummaryEntry(date: .now, summary: WidgetSummary())
    }

    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> Void) {
        completion(SummaryEntry(date: .now, summary: WidgetSummary.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> Void) {
        let entry = SummaryEntry(date: .now, summary: WidgetSummary.load())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct OutstandingWidgetView: View {
    let entry: SummaryEntry

    var body: some View {
        if entry.summary.isPro {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("Outstanding")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                Text(entry.summary.outstandingText)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.6)
                HStack(spacing: 10) {
                    Label("\(entry.summary.overdueCount) overdue", systemImage: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(entry.summary.overdueCount > 0 ? .red : .secondary)
                    Label("\(entry.summary.chasedCount) chased", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(4)
            .widgetBackground()
        } else {
            VStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                Text("PaidPulse Pro")
                    .font(.caption.bold())
                Text("Unlock widgets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .widgetBackground()
        }
    }
}

struct InlineWidgetView: View {
    let entry: SummaryEntry

    var body: some View {
        if entry.summary.isPro {
            Text("\(entry.summary.overdueCount) overdue · \(entry.summary.outstandingText)")
                .widgetBackground()
        } else {
            Text("PaidPulse Pro locked")
                .widgetBackground()
        }
    }
}

struct OutstandingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PaidPulseOutstanding", provider: SummaryProvider()) { entry in
            OutstandingWidgetView(entry: entry)
        }
        .configurationDisplayName("Outstanding Balance")
        .description("Keep a pulse on every dollar owed to you.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { Color.clear }
        } else {
            self
        }
    }
}

@main
struct PaidPulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        OutstandingWidget()
    }
}
