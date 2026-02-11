import Foundation
import CoreLocation
import Combine

@MainActor
final class TourViewModel: ObservableObject {
    @Published var currentTour: Tour?
    @Published var currentStopIndex: Int = 0
    @Published var isOnTour: Bool = false
    @Published var isGenerating: Bool = false
    @Published var selectedCategory: TourCategory = .general
    @Published var tourHistory: [Tour] = []
    @Published var showStopDetail: Bool = false
    @Published var arrivedAtStop: Bool = false
    @Published var customTourLocation: CLLocationCoordinate2D?
    @Published var customTourLocationName: String?

    private let tourGuideService = TourGuideService()

    var currentStop: TourStop? {
        guard let tour = currentTour,
              currentStopIndex >= 0,
              currentStopIndex < tour.stops.count else { return nil }
        return tour.stops[currentStopIndex]
    }

    var nextStop: TourStop? {
        guard let tour = currentTour,
              currentStopIndex + 1 < tour.stops.count else { return nil }
        return tour.stops[currentStopIndex + 1]
    }

    var progress: Double {
        guard let tour = currentTour, !tour.stops.isEmpty else { return 0 }
        return Double(currentStopIndex + 1) / Double(tour.stops.count)
    }

    var stopsRemaining: Int {
        guard let tour = currentTour else { return 0 }
        return max(0, tour.stops.count - currentStopIndex - 1)
    }

    func generateTour(
        coordinate: CLLocationCoordinate2D,
        placemark: CLPlacemark?
    ) async {
        isGenerating = true

        let tour = await tourGuideService.generateTour(
            near: coordinate,
            placemark: placemark,
            category: selectedCategory
        )

        if let tour {
            currentTour = tour
            currentStopIndex = 0
        }
        isGenerating = false
    }

    func startTour() {
        guard currentTour != nil else { return }
        isOnTour = true
        currentStopIndex = 0
        arrivedAtStop = false
    }

    func endTour() {
        if let tour = currentTour {
            tourHistory.append(tour)
        }
        isOnTour = false
        currentTour = nil
        currentStopIndex = 0
        arrivedAtStop = false
    }

    func advanceToNextStop() {
        guard let tour = currentTour else { return }
        if currentStopIndex + 1 < tour.stops.count {
            currentStopIndex += 1
            arrivedAtStop = false
        } else {
            // Tour complete
            endTour()
        }
    }

    func goToPreviousStop() {
        if currentStopIndex > 0 {
            currentStopIndex -= 1
            arrivedAtStop = false
        }
    }

    func goToStop(at index: Int) {
        guard let tour = currentTour,
              index >= 0, index < tour.stops.count else { return }
        currentStopIndex = index
        arrivedAtStop = false
        showStopDetail = true
    }

    func checkProximityToCurrentStop(userLocation: CLLocation, threshold: CLLocationDistance = 50) {
        guard let stop = currentStop else { return }
        let distance = stop.distance(from: userLocation)
        if distance <= threshold && !arrivedAtStop {
            arrivedAtStop = true
        }
    }

    func handleRegionEntry(regionId: String) {
        guard let tour = currentTour else { return }
        if let stopIndex = tour.stops.firstIndex(where: { $0.id.uuidString == regionId }) {
            if stopIndex == currentStopIndex {
                arrivedAtStop = true
            }
        }
    }

    func distanceToCurrentStop(from location: CLLocation) -> String? {
        guard let stop = currentStop else { return nil }
        let distance = stop.distance(from: location)
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        }
        return String(format: "%.1f km away", distance / 1000)
    }
}
