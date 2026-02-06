import Foundation
import CoreLocation

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
        imageSystemName: String = "mappin.circle.fill"
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
    }

    func distance(from location: CLLocation) -> CLLocationDistance {
        let stopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: stopLocation)
    }

    var formattedDuration: String {
        "\(durationMinutes) min"
    }
}
