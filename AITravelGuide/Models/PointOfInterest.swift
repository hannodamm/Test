import Foundation
import CoreLocation
import MapKit

struct PointOfInterest: Identifiable {
    let id: UUID
    var name: String
    var category: POICategory
    var latitude: Double
    var longitude: Double
    var address: String?
    var phoneNumber: String?
    var url: URL?
    var description: String?
    var distanceFromUser: CLLocationDistance?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: POICategory,
        coordinate: CLLocationCoordinate2D,
        address: String? = nil,
        phoneNumber: String? = nil,
        url: URL? = nil,
        description: String? = nil,
        distanceFromUser: CLLocationDistance? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.address = address
        self.phoneNumber = phoneNumber
        self.url = url
        self.description = description
        self.distanceFromUser = distanceFromUser
    }

    init(mapItem: MKMapItem, category: POICategory = .landmark) {
        self.id = UUID()
        self.name = mapItem.name ?? "Unknown"
        self.category = category
        self.latitude = mapItem.placemark.coordinate.latitude
        self.longitude = mapItem.placemark.coordinate.longitude
        self.address = mapItem.placemark.formattedAddress
        self.phoneNumber = mapItem.phoneNumber
        self.url = mapItem.url
        self.description = nil
        self.distanceFromUser = nil
    }

    var formattedDistance: String? {
        guard let distance = distanceFromUser else { return nil }
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        }
        return String(format: "%.1f km", distance / 1000)
    }
}

enum POICategory: String, CaseIterable {
    case landmark = "Landmark"
    case restaurant = "Restaurant"
    case museum = "Museum"
    case park = "Park"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case transit = "Transit"
    case hotel = "Hotel"
    case historical = "Historical"
    case viewpoint = "Viewpoint"

    var systemImage: String {
        switch self {
        case .landmark: return "star.fill"
        case .restaurant: return "fork.knife"
        case .museum: return "building.columns.fill"
        case .park: return "leaf.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "ticket.fill"
        case .transit: return "bus.fill"
        case .hotel: return "bed.double.fill"
        case .historical: return "clock.fill"
        case .viewpoint: return "eye.fill"
        }
    }

    var color: String {
        switch self {
        case .landmark: return "orange"
        case .restaurant: return "red"
        case .museum: return "purple"
        case .park: return "green"
        case .shopping: return "pink"
        case .entertainment: return "yellow"
        case .transit: return "blue"
        case .hotel: return "indigo"
        case .historical: return "brown"
        case .viewpoint: return "teal"
        }
    }

    var mapKitCategory: MKPointOfInterestCategory {
        switch self {
        case .landmark: return .park
        case .restaurant: return .restaurant
        case .museum: return .museum
        case .park: return .nationalPark
        case .shopping: return .store
        case .entertainment: return .theater
        case .transit: return .publicTransport
        case .hotel: return .hotel
        case .historical: return .museum
        case .viewpoint: return .park
        }
    }
}

extension MKPlacemark {
    var formattedAddress: String {
        let components = [subThoroughfare, thoroughfare, locality, administrativeArea, postalCode]
        return components.compactMap { $0 }.joined(separator: " ")
    }
}
