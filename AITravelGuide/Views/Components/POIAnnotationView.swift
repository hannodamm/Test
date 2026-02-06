import SwiftUI
import MapKit

struct POIAnnotationView: View {
    let poi: PointOfInterest
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedContent
                    .transition(.scale.combined(with: .opacity))
            }

            markerIcon
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
        }
    }

    private var markerIcon: some View {
        Image(systemName: poi.category.systemImage)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(8)
            .background(colorForCategory, in: Circle())
            .shadow(radius: 2)
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(poi.name)
                .font(.caption.bold())
                .lineLimit(1)
            Text(poi.category.rawValue)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let distance = poi.formattedDistance {
                Text(distance)
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(8)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(.bottom, 4)
    }

    private var colorForCategory: Color {
        switch poi.category {
        case .landmark: return .orange
        case .restaurant: return .red
        case .museum: return .purple
        case .park: return .green
        case .shopping: return .pink
        case .entertainment: return .yellow
        case .transit: return .blue
        case .hotel: return .indigo
        case .historical: return .brown
        case .viewpoint: return .teal
        }
    }
}
