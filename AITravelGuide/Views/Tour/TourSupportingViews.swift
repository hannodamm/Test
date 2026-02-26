import SwiftUI

struct TourCategoryCard: View {
    let category: TourCategory
    let isSelected: Bool
    var isCurated: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                if isCurated {
                    Text("Curated")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.orange.opacity(0.2))
                        .foregroundStyle(isSelected ? .white : .orange)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TourHistoryRow: View {
    let tour: Tour

    var body: some View {
        HStack {
            Image(systemName: tour.category.systemImage)
                .foregroundStyle(.accent)
                .frame(width: 32)
            VStack(alignment: .leading) {
                Text(tour.name)
                    .font(.subheadline.bold())
                HStack(spacing: 4) {
                    Text("\(tour.stops.count) stops")
                    Text("-")
                    Text(tour.formattedDistance)
                    if let rating = tour.rating {
                        Text("-")
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(tour.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
