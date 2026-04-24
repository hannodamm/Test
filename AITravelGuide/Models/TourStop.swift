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

enum FactCategory: String, Codable, CaseIterable, Hashable {
    case general
    case architecture
    case culture
    case event
    case famous
    case legend
    case art
    case nature

    var displayName: String {
        switch self {
        case .general:      return "General"
        case .architecture: return "Architecture"
        case .culture:      return "Culture"
        case .event:        return "Event"
        case .famous:       return "Famous"
        case .legend:       return "Legend"
        case .art:          return "Art"
        case .nature:       return "Nature"
        }
    }

    var iconSystemName: String {
        switch self {
        case .general:      return "book.fill"
        case .architecture: return "building.columns.fill"
        case .culture:      return "theatermasks.fill"
        case .event:        return "calendar"
        case .famous:       return "star.fill"
        case .legend:       return "sparkles"
        case .art:          return "paintpalette.fill"
        case .nature:       return "leaf.fill"
        }
    }
}

struct HistoricalFact: Identifiable, Codable, Hashable {
    let id: UUID
    var year: String?
    var title: String
    var content: String
    var category: FactCategory

    init(
        id: UUID = UUID(),
        year: String? = nil,
        title: String,
        content: String,
        category: FactCategory = .general
    ) {
        self.id = id
        self.year = year
        self.title = title
        self.content = content
        self.category = category
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
    var historicalFacts: [HistoricalFact]?
    var tips: String?
    var imageSystemName: String
    var walkingNarration: String?
    var discoveryPoints: [DiscoveryPoint]?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Unified fact list for UI and narration. When a tour carries structured
    /// historicalFacts, those are returned verbatim. Otherwise, if a legacy
    /// historicalNote string exists, it's surfaced as a single .general fact
    /// so old saved tours and curated templates still render in the new UI.
    var effectiveFacts: [HistoricalFact] {
        if let facts = historicalFacts, !facts.isEmpty {
            return facts
        }
        if let note = historicalNote, !note.isEmpty {
            return [HistoricalFact(title: "Historical Note", content: note, category: .general)]
        }
        return []
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        orderIndex: Int,
        durationMinutes: Int = 10,
        historicalNote: String? = nil,
        historicalFacts: [HistoricalFact]? = nil,
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
        self.historicalFacts = historicalFacts
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
        historicalFacts = try container.decodeIfPresent([HistoricalFact].self, forKey: .historicalFacts)
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
