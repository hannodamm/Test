import Foundation
import MapKit

@MainActor
final class MapSearchService: ObservableObject {
    @Published var searchResults: [PointOfInterest] = []
    @Published var isSearching: Bool = false

    func searchNearby(
        coordinate: CLLocationCoordinate2D,
        category: POICategory,
        radius: CLLocationDistance = 1000
    ) async -> [PointOfInterest] {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = category.rawValue
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            let pois = response.mapItems.compactMap { item -> PointOfInterest? in
                var poi = PointOfInterest(mapItem: item, category: category)
                let itemLocation = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
                poi.distanceFromUser = userLocation.distance(from: itemLocation)
                return poi
            }.sorted { ($0.distanceFromUser ?? .infinity) < ($1.distanceFromUser ?? .infinity) }

            self.searchResults = pois
            return pois
        } catch {
            self.searchResults = []
            return []
        }
    }

    func searchNearbyMultiCategory(
        coordinate: CLLocationCoordinate2D,
        categories: [POICategory],
        radius: CLLocationDistance = 1000,
        maxPerCategory: Int = 5
    ) async -> [PointOfInterest] {
        var allPOIs: [PointOfInterest] = []

        await withTaskGroup(of: [PointOfInterest].self) { group in
            for category in categories {
                group.addTask {
                    await self.searchNearby(coordinate: coordinate, category: category, radius: radius)
                }
            }

            for await results in group {
                allPOIs.append(contentsOf: Array(results.prefix(maxPerCategory)))
            }
        }

        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let sorted = allPOIs.sorted { poi1, poi2 in
            let d1 = poi1.distanceFromUser ?? userLocation.distance(
                from: CLLocation(latitude: poi1.latitude, longitude: poi1.longitude)
            )
            let d2 = poi2.distanceFromUser ?? userLocation.distance(
                from: CLLocation(latitude: poi2.latitude, longitude: poi2.longitude)
            )
            return d1 < d2
        }

        self.searchResults = sorted
        return sorted
    }

    func searchForQuery(
        _ query: String,
        coordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance = 2000
    ) async -> [PointOfInterest] {
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

            let pois = response.mapItems.compactMap { item -> PointOfInterest? in
                var poi = PointOfInterest(mapItem: item)
                let itemLocation = CLLocation(latitude: poi.latitude, longitude: poi.longitude)
                poi.distanceFromUser = userLocation.distance(from: itemLocation)
                return poi
            }.sorted { ($0.distanceFromUser ?? .infinity) < ($1.distanceFromUser ?? .infinity) }

            self.searchResults = pois
            return pois
        } catch {
            return []
        }
    }
}
