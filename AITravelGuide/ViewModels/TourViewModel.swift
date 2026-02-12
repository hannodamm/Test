import Foundation
import CoreLocation
import MapKit
import Combine

struct WalkingDirectionStep: Identifiable {
    let id = UUID()
    let instructions: String
    let distance: CLLocationDistance

    var formattedDistance: String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        }
        return String(format: "%.1f km", distance / 1000)
    }
}

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

    // Walking directions between stops
    @Published var walkingRouteSegments: [[CLLocationCoordinate2D]] = []
    @Published var walkingETAs: [TimeInterval] = []
    @Published var walkingSteps: [[WalkingDirectionStep]] = []
    @Published var walkingDistances: [CLLocationDistance] = []
    @Published var isCalculatingRoutes: Bool = false

    private let tourGuideService = TourGuideService()

    // Track last generation parameters for regeneration
    private var lastCoordinate: CLLocationCoordinate2D?
    private var lastPlacemark: CLPlacemark?

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

    /// Formatted walking ETA to next stop
    var walkingETAToNextStop: String? {
        guard currentStopIndex < walkingETAs.count else { return nil }
        let seconds = walkingETAs[currentStopIndex]
        guard seconds > 0 else { return nil }
        let minutes = Int(seconds / 60)
        return minutes <= 1 ? "1 min walk" : "\(minutes) min walk"
    }

    /// Steps for the current segment (current stop -> next stop)
    var currentSegmentSteps: [WalkingDirectionStep] {
        guard currentStopIndex < walkingSteps.count else { return [] }
        return walkingSteps[currentStopIndex]
    }

    /// Route coordinates for the current segment
    var currentSegmentRoute: [CLLocationCoordinate2D] {
        guard currentStopIndex < walkingRouteSegments.count else { return [] }
        return walkingRouteSegments[currentStopIndex]
    }

    /// Distance for the current segment
    var currentSegmentDistance: CLLocationDistance? {
        guard currentStopIndex < walkingDistances.count else { return nil }
        let d = walkingDistances[currentStopIndex]
        return d > 0 ? d : nil
    }

    // MARK: - Tour Generation

    func generateTour(
        coordinate: CLLocationCoordinate2D,
        placemark: CLPlacemark?
    ) async {
        isGenerating = true
        lastCoordinate = coordinate
        lastPlacemark = placemark

        let tour = await tourGuideService.generateTour(
            near: coordinate,
            placemark: placemark,
            category: selectedCategory
        )

        if let tour {
            currentTour = tour
            currentStopIndex = 0
            await calculateWalkingRoutes()
        }
        isGenerating = false
    }

    /// Generate a different tour with the same location and category
    func regenerateTour() async {
        guard let coord = lastCoordinate else { return }
        await generateTour(coordinate: coord, placemark: lastPlacemark)
    }

    // MARK: - Tour Lifecycle

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
        walkingRouteSegments = []
        walkingETAs = []
        walkingSteps = []
        walkingDistances = []
    }

    func advanceToNextStop() {
        guard let tour = currentTour else { return }
        if currentStopIndex + 1 < tour.stops.count {
            currentStopIndex += 1
            arrivedAtStop = false
        } else {
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

    // MARK: - Rating

    func rateTour(_ stars: Int) {
        guard stars >= 1, stars <= 5 else { return }
        currentTour?.rating = stars
        // Also update in history
        if let tour = currentTour,
           let idx = tourHistory.firstIndex(where: { $0.id == tour.id }) {
            tourHistory[idx].rating = stars
        }
    }

    // MARK: - Proximity

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

    // MARK: - Walking Directions

    func calculateWalkingRoutes() async {
        guard let tour = currentTour, tour.stops.count >= 2 else {
            walkingRouteSegments = []
            walkingETAs = []
            walkingSteps = []
            walkingDistances = []
            return
        }

        isCalculatingRoutes = true
        var segments: [[CLLocationCoordinate2D]] = []
        var etas: [TimeInterval] = []
        var allSteps: [[WalkingDirectionStep]] = []
        var distances: [CLLocationDistance] = []

        for i in 0..<(tour.stops.count - 1) {
            let source = tour.stops[i]
            let destination = tour.stops[i + 1]

            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
            request.transportType = .walking

            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    let count = route.polyline.pointCount
                    var coords = [CLLocationCoordinate2D](
                        repeating: CLLocationCoordinate2D(),
                        count: count
                    )
                    route.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
                    segments.append(coords)
                    etas.append(route.expectedTravelTime)
                    distances.append(route.distance)

                    let steps = route.steps
                        .filter { !$0.instructions.isEmpty }
                        .map { WalkingDirectionStep(instructions: $0.instructions, distance: $0.distance) }
                    allSteps.append(steps)
                } else {
                    segments.append([source.coordinate, destination.coordinate])
                    etas.append(0)
                    allSteps.append([])
                    distances.append(0)
                }
            } catch {
                // Fallback to straight line
                segments.append([source.coordinate, destination.coordinate])
                etas.append(0)
                allSteps.append([])
                distances.append(0)
            }
        }

        walkingRouteSegments = segments
        walkingETAs = etas
        walkingSteps = allSteps
        walkingDistances = distances
        isCalculatingRoutes = false
    }
}
