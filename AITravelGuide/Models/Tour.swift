import Foundation
import CoreLocation

struct GuidePersona: Codable, Hashable {
    var name: String
    var tagline: String
    var voiceStyle: String
    var greeting: String
    var signoff: String
}

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
    var rating: Int?
    var narrativeThread: String?
    var guidePersona: GuidePersona?
    var templateId: String?

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
        rating: Int? = nil,
        narrativeThread: String? = nil,
        guidePersona: GuidePersona? = nil,
        templateId: String? = nil
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
        self.narrativeThread = narrativeThread
        self.guidePersona = guidePersona
        self.templateId = templateId
    }

    // Custom decoding for backwards compatibility with tours saved before
    // locationName, rating, narrativeThread, guidePersona, templateId fields were added
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
        narrativeThread = try container.decodeIfPresent(String.self, forKey: .narrativeThread)
        guidePersona = try container.decodeIfPresent(GuidePersona.self, forKey: .guidePersona)
        templateId = try container.decodeIfPresent(String.self, forKey: .templateId)
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
    // Milan curated
    case milanLastSupper = "Last Supper & Highlights"
    case milanBrera = "Brera Food Tour"
    case milanNavigli = "Navigli Evening"
    case milanFashion = "Fashion & Vintage"
    case milanCoffee = "Coffee Culture"
    case milanHidden = "Hidden Courtyards"
    // Munich curated
    case munichOldTown = "Old Town Highlights"
    case munichBeer = "Beer & Brewery Tour"
    case munichFood = "Bavarian Food Trail"
    case munichEnglishGarden = "English Garden Walk"
    case munichRoyal = "Royal Munich"
    case munichHidden = "Hidden Munich"

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
        case .milanLastSupper: return "star.fill"
        case .milanBrera: return "fork.knife.circle.fill"
        case .milanNavigli: return "water.waves"
        case .milanFashion: return "tshirt.fill"
        case .milanCoffee: return "cup.and.saucer.fill"
        case .milanHidden: return "door.left.hand.open"
        case .munichOldTown: return "building.columns.fill"
        case .munichBeer: return "mug.fill"
        case .munichFood: return "fork.knife.circle.fill"
        case .munichEnglishGarden: return "leaf.fill"
        case .munichRoyal: return "crown.fill"
        case .munichHidden: return "eye.fill"
        }
    }

    var isCurated: Bool {
        switch self {
        case .milanLastSupper, .milanBrera, .milanNavigli,
             .milanFashion, .milanCoffee, .milanHidden,
             .munichOldTown, .munichBeer, .munichFood,
             .munichEnglishGarden, .munichRoyal, .munichHidden:
            return true
        default:
            return false
        }
    }

    var curatedCity: String? {
        switch self {
        case .milanLastSupper, .milanBrera, .milanNavigli,
             .milanFashion, .milanCoffee, .milanHidden:
            return "Milan"
        case .munichOldTown, .munichBeer, .munichFood,
             .munichEnglishGarden, .munichRoyal, .munichHidden:
            return "Munich"
        default:
            return nil
        }
    }

    /// Generic categories available for any city
    static var genericCategories: [TourCategory] {
        [.historical, .cultural, .food, .nature, .architecture, .art, .nightlife, .general]
    }

    /// Milan curated categories
    static var milanCategories: [TourCategory] {
        [.milanLastSupper, .milanBrera, .milanNavigli, .milanFashion, .milanCoffee, .milanHidden]
    }

    /// Munich curated categories
    static var munichCategories: [TourCategory] {
        [.munichOldTown, .munichBeer, .munichFood, .munichEnglishGarden, .munichRoyal, .munichHidden]
    }

    /// Returns curated + generic categories based on coordinate proximity to known cities
    static func categories(for coordinate: CLLocationCoordinate2D?) -> (curated: [TourCategory], generic: [TourCategory]) {
        guard let coord = coordinate else {
            return (curated: [], generic: genericCategories)
        }
        let threshold: CLLocationDistance = 30_000 // 30km
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)

        let milanCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
        if loc.distance(from: milanCenter) < threshold {
            return (curated: milanCategories, generic: genericCategories)
        }

        let munichCenter = CLLocation(latitude: 48.1351, longitude: 11.5820)
        if loc.distance(from: munichCenter) < threshold {
            return (curated: munichCategories, generic: genericCategories)
        }

        return (curated: [], generic: genericCategories)
    }

    /// Returns curated + generic categories for a given city name (fallback)
    static func categories(for cityName: String?) -> (curated: [TourCategory], generic: [TourCategory]) {
        guard let city = cityName?.lowercased() else {
            return (curated: [], generic: genericCategories)
        }
        if city.contains("milan") || city.contains("milano") {
            return (curated: milanCategories, generic: genericCategories)
        }
        if city.contains("munich") || city.contains("münchen") || city.contains("munchen") {
            return (curated: munichCategories, generic: genericCategories)
        }
        return (curated: [], generic: genericCategories)
    }
}
