import Foundation
import CoreLocation

struct DiscoveryPoint: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    var triggerRadiusMeters: Double
    var iconSystemName: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        triggerRadiusMeters: Double = 30,
        iconSystemName: String = "eye.fill"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.triggerRadiusMeters = triggerRadiusMeters
        self.iconSystemName = iconSystemName
    }
}

struct TourStop: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var latitude: Double
    var longitude: Double
    var orderIndex: Int
    var durationMinutes: Int
    var historicalNote: String?
    var tips: String?
    var imageSystemName: String
    var walkingNarration: String?
    var discoveryPoints: [DiscoveryPoint]?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        orderIndex: Int,
        durationMinutes: Int = 10,
        historicalNote: String? = nil,
        tips: String? = nil,
        imageSystemName: String = "mappin.circle.fill",
        walkingNarration: String? = nil,
        discoveryPoints: [DiscoveryPoint]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.orderIndex = orderIndex
        self.durationMinutes = durationMinutes
        self.historicalNote = historicalNote
        self.tips = tips
        self.imageSystemName = imageSystemName
        self.walkingNarration = walkingNarration
        self.discoveryPoints = discoveryPoints
    }

    // Custom decoding for backward compat with saved tours
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        orderIndex = try container.decode(Int.self, forKey: .orderIndex)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        historicalNote = try container.decodeIfPresent(String.self, forKey: .historicalNote)
        tips = try container.decodeIfPresent(String.self, forKey: .tips)
        imageSystemName = try container.decodeIfPresent(String.self, forKey: .imageSystemName) ?? "mappin.circle.fill"
        walkingNarration = try container.decodeIfPresent(String.self, forKey: .walkingNarration)
        discoveryPoints = try container.decodeIfPresent([DiscoveryPoint].self, forKey: .discoveryPoints)
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let stopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: stopLocation)
    }

    var formattedDuration: String {
        "\(durationMinutes) min"
    }
}
