import SwiftUI

struct HighlightCard: View {
    let poi: PointOfInterest
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon header
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryGradient)
                        .frame(height: 100)

                    Image(systemName: poi.category.systemImage)
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(poi.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(poi.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let distance = poi.formattedDistance {
                        HStack(spacing: 2) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(distance)
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }

                    if let address = poi.address, !address.isEmpty {
                        Text(address)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .frame(width: 160)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var categoryGradient: LinearGradient {
        let color = poi.category.swiftUIColor
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
