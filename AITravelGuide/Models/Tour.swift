import Foundation
import CoreLocation

struct Tour: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var stops: [TourStop]
    var estimatedDurationMinutes: Int
    var distanceMeters: Double
    var category: TourCategory
    var createdAt: Date
    var centerLatitude: Double
    var centerLongitude: Double
    var locationName: String
    var rating: Int? // 1-5 stars, nil = unrated

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        stops: [TourStop],
        estimatedDurationMinutes: Int,
        distanceMeters: Double,
        category: TourCategory,
        centerCoordinate: CLLocationCoordinate2D,
        locationName: String = "the area",
        rating: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.stops = stops
        self.estimatedDurationMinutes = estimatedDurationMinutes
        self.distanceMeters = distanceMeters
        self.category = category
        self.createdAt = Date()
        self.centerLatitude = centerCoordinate.latitude
        self.centerLongitude = centerCoordinate.longitude
        self.locationName = locationName
        self.rating = rating
    }

    // Custom decoding for backwards compatibility with tours saved before
    // locationName and rating fields were added
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        stops = try container.decode([TourStop].self, forKey: .stops)
        estimatedDurationMinutes = try container.decode(Int.self, forKey: .estimatedDurationMinutes)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        category = try container.decode(TourCategory.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        centerLatitude = try container.decode(Double.self, forKey: .centerLatitude)
        centerLongitude = try container.decode(Double.self, forKey: .centerLongitude)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName) ?? "the area"
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
    }

    var formattedDuration: String {
        if estimatedDurationMinutes < 60 {
            return "\(estimatedDurationMinutes) min"
        }
        let hours = estimatedDurationMinutes / 60
        let mins = estimatedDurationMinutes % 60
        return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
    }

    var formattedDistance: String {
        if distanceMeters < 1000 {
            return String(format: "%.0f m", distanceMeters)
        }
        return String(format: "%.1f km", distanceMeters / 1000)
    }
}

enum TourCategory: String, Codable, CaseIterable {
    case historical = "Historical"
    case cultural = "Cultural"
    case food = "Food & Drink"
    case nature = "Nature"
    case architecture = "Architecture"
    case art = "Art"
    case nightlife = "Nightlife"
    case general = "General"

    var systemImage: String {
        switch self {
        case .historical: return "building.columns"
        case .cultural: return "theatermasks"
        case .food: return "fork.knife"
        case .nature: return "leaf"
        case .architecture: return "building.2"
        case .art: return "paintpalette"
        case .nightlife: return "moon.stars"
        case .general: return "map"
        }
    }
}
