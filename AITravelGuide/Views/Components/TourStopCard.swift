import SwiftUI

struct TourStopCard: View {
    let stop: TourStop
    let index: Int
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step indicator
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 32, height: 32)
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }
                }
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(stop.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                    Spacer()
                    Label(stop.formattedDuration, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(stop.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(isActive ? nil : 2)

                if isActive {
                    if let note = stop.historicalNote {
                        Label(note, systemImage: "book.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .lineLimit(2)
                    }

                    if let tip = stop.tips {
                        Label(tip, systemImage: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .opacity(isCompleted ? 0.6 : 1.0)
    }

    private var circleColor: Color {
        if isCompleted { return .green }
        if isActive { return .blue }
        return .gray
    }
}
