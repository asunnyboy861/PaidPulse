import SwiftUI

struct StageProgressBar: View {
    let currentStage: Int
    let targetStage: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                ForEach(EscalationLevel.allCases) { level in
                    Capsule()
                        .fill(color(for: level))
                        .frame(height: 8)
                        .accessibilityLabel("\(level.title): \(stageState(level))")
                }
            }
            HStack {
                ForEach(EscalationLevel.allCases) { level in
                    Text(level.triggerDay == 0 ? "0" : "+\(level.triggerDay)")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func color(for level: EscalationLevel) -> Color {
        if level.rawValue <= currentStage { return .green }
        if level.rawValue == targetStage && targetStage > currentStage { return .orange }
        return Color(.systemFill)
    }

    private func stageState(_ level: EscalationLevel) -> String {
        level.rawValue <= currentStage ? "sent or passed" : "upcoming"
    }
}
