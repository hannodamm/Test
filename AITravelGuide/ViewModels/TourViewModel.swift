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
    @Published var tourGenerationError: String?
    @Published var selectedCategory: TourCategory = .general
    @Published var showStopDetail: Bool = false
    @Published var arrivedAtStop: Bool = false
    @Published var hasDepartedCurrentStop: Bool = false

    // Discovery points
    @Published var nearbyDiscoveryPoint: DiscoveryPoint?
    private var discoveredPointIds: Set<UUID> = []

    // Approach detection
    @Published var approachingNextStop: Bool = false
    private var hasShownApproaching = false

    // Progress commentary
    @Published var progressCommentary: String?
    private var hasShownHalfway = false
    private var hasShownAlmostDone = false

    // Walking directions between stops
    @Published var walkingRouteSegments: [[CLLocationCoordinate2D]] = []
    @Published var walkingETAs: [TimeInterval] = []
    @Published var walkingSteps: [[WalkingDirectionStep]] = []
    @Published var walkingDistances: [CLLocationDistance] = []
    @Published var isCalculatingRoutes: Bool = false

    private let tourGuideService = TourGuideService()
    var storageService: TourStorageService?

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
        tourGenerationError = nil
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
        } else {
            tourGenerationError = "Couldn't generate a tour. Check your internet connection and API key, then try again."
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
        hasDepartedCurrentStop = false
        approachingNextStop = false
        hasShownApproaching = false
        discoveredPointIds = []
        nearbyDiscoveryPoint = nil
        progressCommentary = nil
        hasShownHalfway = false
        hasShownAlmostDone = false
    }

    func endTour() {
        if let tour = currentTour {
            storageService?.addToHistory(tour)
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
            hasDepartedCurrentStop = false
            approachingNextStop = false
            hasShownApproaching = false
        } else {
            endTour()
        }
    }

    func goToPreviousStop() {
        if currentStopIndex > 0 {
            currentStopIndex -= 1
            arrivedAtStop = false
            hasDepartedCurrentStop = false
        }
    }

    func goToStop(at index: Int) {
        guard let tour = currentTour,
              index >= 0, index < tour.stops.count else { return }
        currentStopIndex = index
        arrivedAtStop = false
        hasDepartedCurrentStop = false
        showStopDetail = true
    }

    // MARK: - Rating

    func rateTour(_ stars: Int) {
        guard stars >= 1, stars <= 5 else { return }
        currentTour?.rating = stars
        // Also update in persisted history
        if let tour = currentTour {
            storageService?.addToHistory(tour)
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

    func checkDepartureFromStop(userLocation: CLLocation) {
        guard let stop = currentStop, arrivedAtStop, !hasDepartedCurrentStop else { return }
        let distance = stop.distance(from: userLocation)
        if distance > 100 {
            hasDepartedCurrentStop = true
        }
    }

    func checkApproachToNextStop(userLocation: CLLocation) {
        guard let next = nextStop, !hasShownApproaching else { return }
        let distance = next.distance(from: userLocation)
        if distance <= 150 {
            hasShownApproaching = true
            approachingNextStop = true
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
        let segmentCount = tour.stops.count - 1
        let stops = tour.stops

        // Calculate all segments in parallel
        let results = await withTaskGroup(
            of: (Int, [CLLocationCoordinate2D], TimeInterval, [WalkingDirectionStep], CLLocationDistance).self
        ) { group in
            for i in 0..<segmentCount {
                let source = stops[i]
                let destination = stops[i + 1]
                group.addTask {
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

                            let steps = route.steps
                                .filter { !$0.instructions.isEmpty }
                                .map { WalkingDirectionStep(instructions: $0.instructions, distance: $0.distance) }
                            return (i, coords, route.expectedTravelTime, steps, route.distance)
                        }
                    } catch {}
                    // Fallback to straight line
                    return (i, [source.coordinate, destination.coordinate], TimeInterval(0), [WalkingDirectionStep](), CLLocationDistance(0))
                }
            }

            var collected = [(Int, [CLLocationCoordinate2D], TimeInterval, [WalkingDirectionStep], CLLocationDistance)]()
            for await result in group {
                collected.append(result)
            }
            return collected.sorted { $0.0 < $1.0 }
        }

        walkingRouteSegments = results.map { $0.1 }
        walkingETAs = results.map { $0.2 }
        walkingSteps = results.map { $0.3 }
        walkingDistances = results.map { $0.4 }
        isCalculatingRoutes = false
    }

    // MARK: - Discovery Points

    func checkProximityToDiscoveryPoints(userLocation: CLLocation) {
        guard let tour = currentTour else { return }

        // Gather discovery points from current and next stop
        var candidates: [DiscoveryPoint] = []
        if let current = currentStop {
            candidates.append(contentsOf: current.discoveryPoints ?? [])
        }
        if let next = nextStop {
            candidates.append(contentsOf: next.discoveryPoints ?? [])
        }

        for point in candidates {
            guard !discoveredPointIds.contains(point.id) else { continue }
            let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
            if userLocation.distance(from: pointLocation) <= point.triggerRadiusMeters {
                discoveredPointIds.insert(point.id)
                nearbyDiscoveryPoint = point
                return
            }
        }
    }

    // MARK: - Progress Commentary

    func checkProgressCommentary() {
        guard let tour = currentTour, tour.stops.count >= 3 else { return }

        let progress = Double(currentStopIndex) / Double(tour.stops.count)

        if !hasShownHalfway && progress >= 0.45 && progress < 0.75 {
            hasShownHalfway = true
            if let thread = tour.narrativeThread {
                progressCommentary = "We're halfway through! \(thread)"
            } else {
                progressCommentary = "We're halfway through the tour — doing great!"
            }
        } else if !hasShownAlmostDone && currentStopIndex == tour.stops.count - 2 {
            hasShownAlmostDone = true
            if let thread = tour.narrativeThread {
                progressCommentary = "Almost done! \(thread)"
            } else {
                progressCommentary = "Just one more stop to go — almost done!"
            }
        }
    }
}
