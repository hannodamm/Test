import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var nearbyPOIs: [PointOfInterest] = []
    @Published var selectedPOI: PointOfInterest?
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedCategories: Set<POICategory> = [.landmark, .museum, .restaurant, .park]
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @Published var searchResultRegion: MKCoordinateRegion?
    @Published var searchedCoordinate: CLLocationCoordinate2D?
    @Published var searchedLocationName: String?
    @Published var searchHadNoResults: Bool = false

    private let mapSearchService = MapSearchService()
    private var lastSearchCoordinate: CLLocationCoordinate2D?

    func updateRegion(for location: CLLocation) {
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
    }

    func loadNearbyPOIs(coordinate: CLLocationCoordinate2D) async {
        // Avoid redundant searches for nearby coordinates
        if let last = lastSearchCoordinate {
            let distance = CLLocation(latitude: last.latitude, longitude: last.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            if distance < 100 && !nearbyPOIs.isEmpty { return }
        }

        isLoading = true
        lastSearchCoordinate = coordinate

        let categories = Array(selectedCategories)
        let results = await mapSearchService.searchNearbyMultiCategory(
            coordinate: coordinate,
            categories: categories,
            radius: 1500,
            maxPerCategory: 5
        )

        nearbyPOIs = results
        isLoading = false
    }

    func search(near coordinate: CLLocationCoordinate2D) async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResultRegion = nil
            searchedCoordinate = nil
            searchedLocationName = nil
            await loadNearbyPOIs(coordinate: coordinate)
            return
        }

        isLoading = true

        // First try geocoding the query as a place name (city, address, etc.)
        let geocodedCoordinate = await geocodeLocation(query) ?? coordinate
        let didGeocode = geocodedCoordinate.latitude != coordinate.latitude
            || geocodedCoordinate.longitude != coordinate.longitude
        let searchRadius: CLLocationDistance = didGeocode ? 5000 : 2000

        // Store the searched location for tour generation
        if didGeocode {
            searchedCoordinate = geocodedCoordinate
            searchedLocationName = query.capitalized
        } else {
            searchedCoordinate = nil
            searchedLocationName = nil
        }

        let results = await mapSearchService.searchForQuery(
            query,
            coordinate: geocodedCoordinate,
            radius: searchRadius
        )
        nearbyPOIs = results
        searchHadNoResults = results.isEmpty

        // Move the camera to show search results
        if !results.isEmpty {
            searchResultRegion = regionEnclosing(pois: results)
        } else if geocodedCoordinate.latitude != coordinate.latitude
            || geocodedCoordinate.longitude != coordinate.longitude {
            // No POI results but geocoding succeeded — move camera to the geocoded location
            searchResultRegion = MKCoordinateRegion(
                center: geocodedCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        isLoading = false
    }

    private func geocodeLocation(_ query: String) async -> CLLocationCoordinate2D? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            return placemarks.first?.location?.coordinate
        } catch {
            return nil
        }
    }

    private func regionEnclosing(pois: [PointOfInterest]) -> MKCoordinateRegion {
        guard !pois.isEmpty else {
            return mapRegion
        }

        var minLat = pois[0].latitude
        var maxLat = pois[0].latitude
        var minLon = pois[0].longitude
        var maxLon = pois[0].longitude

        for poi in pois {
            minLat = min(minLat, poi.latitude)
            maxLat = max(maxLat, poi.latitude)
            minLon = min(minLon, poi.longitude)
            maxLon = max(maxLon, poi.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    func refreshPOIs(coordinate: CLLocationCoordinate2D) async {
        lastSearchCoordinate = nil
        await loadNearbyPOIs(coordinate: coordinate)
    }

    func toggleCategory(_ category: POICategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    var filteredPOIs: [PointOfInterest] {
        nearbyPOIs.filter { selectedCategories.contains($0.category) }
    }
}
