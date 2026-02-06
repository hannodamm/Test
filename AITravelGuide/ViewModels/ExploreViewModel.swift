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
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            await loadNearbyPOIs(coordinate: coordinate)
            return
        }

        isLoading = true
        let results = await mapSearchService.searchForQuery(
            searchText,
            coordinate: coordinate,
            radius: 2000
        )
        nearbyPOIs = results
        isLoading = false
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
