import Foundation
import CoreLocation
import MapKit

@MainActor
final class TourGuideService: ObservableObject {
    @Published var isGeneratingTour: Bool = false
    @Published var currentTour: Tour?

    private let mapSearchService = MapSearchService()

    // MARK: - Tour Generation

    func generateTour(
        near coordinate: CLLocationCoordinate2D,
        placemark: CLPlacemark?,
        category: TourCategory = .general,
        numberOfStops: Int = 5
    ) async -> Tour? {
        isGeneratingTour = true
        defer { isGeneratingTour = false }

        let categories = poiCategoriesForTour(category)
        var allPOIs: [PointOfInterest] = []

        for cat in categories {
            let results = await mapSearchService.searchNearby(
                coordinate: coordinate,
                category: cat,
                radius: 1500
            )
            allPOIs.append(contentsOf: results)
        }

        guard !allPOIs.isEmpty else { return nil }

        // Deduplicate by proximity (within 50m)
        var uniquePOIs: [PointOfInterest] = []
        for poi in allPOIs {
            let isDuplicate = uniquePOIs.contains { existing in
                let d = CLLocation(latitude: existing.latitude, longitude: existing.longitude)
                    .distance(from: CLLocation(latitude: poi.latitude, longitude: poi.longitude))
                return d < 50
            }
            if !isDuplicate {
                uniquePOIs.append(poi)
            }
        }

        // Select stops, optimizing for a walkable route
        let selected = selectOptimalStops(
            from: uniquePOIs,
            startCoordinate: coordinate,
            count: min(numberOfStops, uniquePOIs.count)
        )

        let stops = selected.enumerated().map { index, poi in
            TourStop(
                name: poi.name,
                description: generateStopDescription(poi: poi, placemark: placemark),
                coordinate: poi.coordinate,
                orderIndex: index,
                durationMinutes: estimateStopDuration(poi),
                historicalNote: generateHistoricalNote(poi: poi, placemark: placemark),
                tips: generateTip(poi: poi),
                imageSystemName: poi.category.systemImage
            )
        }

        let totalDistance = calculateRouteDistance(stops: stops, from: coordinate)
        let walkingMinutes = Int(totalDistance / 80.0) // ~80m/min walking pace
        let stopMinutes = stops.reduce(0) { $0 + $1.durationMinutes }

        let locationName = placemark?.locality ?? placemark?.name ?? "Your Area"

        let tour = Tour(
            name: generateTourName(category: category, location: locationName),
            description: generateTourDescription(
                category: category,
                location: locationName,
                stopCount: stops.count
            ),
            stops: stops,
            estimatedDurationMinutes: walkingMinutes + stopMinutes,
            distanceMeters: totalDistance,
            category: category,
            centerCoordinate: coordinate
        )

        self.currentTour = tour
        return tour
    }

    // MARK: - Offline Fallback Response (used when no API key is set)

    func generateFallbackResponse(
        to question: String,
        location: CLLocation?,
        placemark: CLPlacemark?,
        nearbyPOIs: [PointOfInterest],
        currentTour: Tour?
    ) -> String {
        let context = buildLocationContext(
            location: location,
            placemark: placemark,
            nearbyPOIs: nearbyPOIs,
            currentTour: currentTour
        )
        return generateContextualResponse(question: question, context: context)
    }

    // MARK: - Build Location Context (shared with ClaudeAPIService)

    func buildLocationContext(
        location: CLLocation?,
        placemark: CLPlacemark?,
        nearbyPOIs: [PointOfInterest],
        currentTour: Tour?
    ) -> LocationContext {
        LocationContext(
            city: placemark?.locality,
            country: placemark?.country,
            neighborhood: placemark?.subLocality,
            coordinate: location?.coordinate,
            nearbyPOINames: nearbyPOIs.prefix(10).map { $0.name },
            nearbyPOICategories: Array(Set(nearbyPOIs.map { $0.category.rawValue })),
            currentTourName: currentTour?.name,
            currentTourCategory: currentTour?.category.rawValue
        )
    }

    // MARK: - Location Highlights

    func generateHighlights(
        for poi: PointOfInterest,
        placemark: CLPlacemark?
    ) -> [String] {
        var highlights: [String] = []

        let location = placemark?.locality ?? "this area"

        switch poi.category {
        case .landmark:
            highlights.append("A notable landmark in \(location) worth visiting")
            highlights.append("Great photo opportunity - bring your camera")
        case .restaurant:
            highlights.append("Popular dining spot among locals")
            if let address = poi.address {
                highlights.append("Located at \(address)")
            }
        case .museum:
            highlights.append("Cultural institution showcasing local heritage")
            highlights.append("Check opening hours before visiting")
        case .park:
            highlights.append("Green space perfect for a break during your tour")
            highlights.append("Ideal for relaxation and people-watching")
        case .historical:
            highlights.append("Historical significance to \(location)")
            highlights.append("Rich with stories from the past")
        case .viewpoint:
            highlights.append("Scenic viewpoint with panoramic views")
            highlights.append("Best visited during golden hour for photos")
        default:
            highlights.append("A notable spot in \(location)")
        }

        if let distance = poi.formattedDistance {
            highlights.append("\(distance) from your current location")
        }

        return highlights
    }

    // MARK: - Private Helpers

    private func poiCategoriesForTour(_ category: TourCategory) -> [POICategory] {
        switch category {
        case .historical:
            return [.historical, .museum, .landmark]
        case .cultural:
            return [.museum, .landmark, .entertainment]
        case .food:
            return [.restaurant]
        case .nature:
            return [.park, .viewpoint]
        case .architecture:
            return [.landmark, .historical]
        case .art:
            return [.museum, .entertainment, .landmark]
        case .nightlife:
            return [.entertainment, .restaurant]
        case .general:
            return [.landmark, .museum, .park, .restaurant, .historical]
        }
    }

    private func selectOptimalStops(
        from pois: [PointOfInterest],
        startCoordinate: CLLocationCoordinate2D,
        count: Int
    ) -> [PointOfInterest] {
        guard !pois.isEmpty else { return [] }

        // Nearest-neighbor greedy algorithm for a walkable route
        var remaining = pois
        var selected: [PointOfInterest] = []
        var currentCoord = startCoordinate

        while selected.count < count && !remaining.isEmpty {
            let currentLoc = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude)

            remaining.sort { poi1, poi2 in
                let d1 = CLLocation(latitude: poi1.latitude, longitude: poi1.longitude).distance(from: currentLoc)
                let d2 = CLLocation(latitude: poi2.latitude, longitude: poi2.longitude).distance(from: currentLoc)
                return d1 < d2
            }

            let next = remaining.removeFirst()
            selected.append(next)
            currentCoord = next.coordinate
        }

        return selected
    }

    private func calculateRouteDistance(stops: [TourStop], from start: CLLocationCoordinate2D) -> Double {
        guard !stops.isEmpty else { return 0 }

        var totalDistance: Double = 0
        var previousLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)

        for stop in stops {
            let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
            totalDistance += previousLocation.distance(from: stopLocation)
            previousLocation = stopLocation
        }

        return totalDistance
    }

    private func estimateStopDuration(_ poi: PointOfInterest) -> Int {
        switch poi.category {
        case .museum: return 30
        case .restaurant: return 20
        case .park: return 15
        case .landmark: return 10
        case .historical: return 15
        case .viewpoint: return 10
        case .entertainment: return 20
        default: return 10
        }
    }

    private func generateTourName(category: TourCategory, location: String) -> String {
        switch category {
        case .historical: return "Historical \(location) Walk"
        case .cultural: return "Cultural Gems of \(location)"
        case .food: return "\(location) Food Trail"
        case .nature: return "Nature Escape in \(location)"
        case .architecture: return "Architectural Wonders of \(location)"
        case .art: return "\(location) Art Walk"
        case .nightlife: return "\(location) After Dark"
        case .general: return "Discover \(location)"
        }
    }

    private func generateTourDescription(category: TourCategory, location: String, stopCount: Int) -> String {
        let base = "Explore \(stopCount) curated stops in \(location)"
        switch category {
        case .historical:
            return "\(base), tracing the historical footprints and stories that shaped this area."
        case .cultural:
            return "\(base), immersing yourself in the local culture, arts, and traditions."
        case .food:
            return "\(base), sampling the best local cuisine and culinary traditions."
        case .nature:
            return "\(base), discovering green spaces, scenic views, and natural beauty."
        case .architecture:
            return "\(base), admiring remarkable buildings and architectural styles."
        case .art:
            return "\(base), experiencing galleries, public art, and creative spaces."
        case .nightlife:
            return "\(base), enjoying the vibrant evening scene and entertainment."
        case .general:
            return "\(base), taking in the best highlights this area has to offer."
        }
    }

    private func generateStopDescription(poi: PointOfInterest, placemark: CLPlacemark?) -> String {
        let location = placemark?.locality ?? "the area"
        switch poi.category {
        case .landmark:
            return "\(poi.name) is a notable landmark in \(location). Take a moment to appreciate its significance and capture some photos."
        case .restaurant:
            return "A popular dining spot in \(location). \(poi.name) offers a taste of local flavors and cuisine."
        case .museum:
            return "\(poi.name) showcases the cultural heritage and stories of \(location). A must-visit for curious travelers."
        case .park:
            return "\(poi.name) provides a refreshing green space in \(location). Perfect for a peaceful break during your tour."
        case .historical:
            return "Step back in time at \(poi.name), a place rich with the history of \(location)."
        case .viewpoint:
            return "Enjoy panoramic views from \(poi.name). One of the best vantage points in \(location)."
        case .entertainment:
            return "\(poi.name) is a hub of entertainment and activity in \(location)."
        default:
            return "Visit \(poi.name), one of the interesting spots in \(location)."
        }
    }

    private func generateHistoricalNote(poi: PointOfInterest, placemark: CLPlacemark?) -> String? {
        switch poi.category {
        case .historical, .museum, .landmark:
            let location = placemark?.locality ?? "this area"
            return "This location has been an important part of \(location)'s heritage. Ask your AI guide for more details about its history."
        default:
            return nil
        }
    }

    private func generateTip(poi: PointOfInterest) -> String? {
        switch poi.category {
        case .restaurant:
            return "Try asking locals for their favorite dish here."
        case .museum:
            return "Many museums offer free or discounted entry at certain times. Check before visiting."
        case .viewpoint:
            return "Visit during golden hour for the best photos."
        case .park:
            return "Great for a quick rest. Look for benches and shade."
        default:
            return nil
        }
    }

    private func generateContextualResponse(
        question: String,
        context: LocationContext
    ) -> String {
        let lowered = question.lowercased()
        let location = context.city ?? context.neighborhood ?? "your area"

        // Food & restaurant questions
        if lowered.contains("eat") || lowered.contains("food") || lowered.contains("restaurant")
            || lowered.contains("hungry") || lowered.contains("lunch") || lowered.contains("dinner")
            || lowered.contains("breakfast") || lowered.contains("cafe") {
            let foodPOIs = context.nearbyPOINames.isEmpty
                ? "various local restaurants"
                : context.nearbyPOINames.prefix(3).joined(separator: ", ")
            return """
                Great question! \(location) has wonderful dining options. Near you, I'd suggest checking out \(foodPOIs). \
                For an authentic experience, look for places where locals are dining — that's usually a good sign. \
                Would you like me to create a food tour or find a specific cuisine?
                """
        }

        // History questions
        if lowered.contains("history") || lowered.contains("historical") || lowered.contains("old")
            || lowered.contains("ancient") || lowered.contains("heritage") {
            return """
                \(location) has a rich history worth exploring. The area around you has been shaped by centuries \
                of cultural exchange and development. I'd recommend visiting local museums and historical landmarks \
                to dive deeper. Would you like me to generate a historical walking tour from your current location?
                """
        }

        // Safety questions
        if lowered.contains("safe") || lowered.contains("safety") || lowered.contains("dangerous")
            || lowered.contains("crime") {
            return """
                Like any destination, \(location) is generally safe for tourists who take standard precautions. \
                Stay aware of your surroundings, keep valuables secure, and stick to well-lit areas at night. \
                It's always a good idea to check recent travel advisories for the most current safety information. \
                Would you like tips on specific neighborhoods?
                """
        }

        // Transport questions
        if lowered.contains("transport") || lowered.contains("bus") || lowered.contains("train")
            || lowered.contains("metro") || lowered.contains("taxi") || lowered.contains("get around")
            || lowered.contains("uber") {
            return """
                Getting around \(location) is part of the adventure! Most cities offer a mix of public transit, \
                ride-sharing, and walking options. For the most authentic experience, I'd suggest combining walking \
                with local transit. Check the Maps app for real-time transit directions from your current location.
                """
        }

        // Weather questions
        if lowered.contains("weather") || lowered.contains("rain") || lowered.contains("temperature")
            || lowered.contains("hot") || lowered.contains("cold") {
            return """
                For current weather conditions in \(location), I'd recommend checking your weather app for \
                real-time data. When planning outdoor tours, early morning or late afternoon usually offers \
                the most comfortable conditions. Would you like me to plan an indoor-focused tour instead?
                """
        }

        // Tour questions
        if lowered.contains("tour") || lowered.contains("walk") || lowered.contains("explore")
            || lowered.contains("see") || lowered.contains("visit") || lowered.contains("suggest") {
            if let tourName = context.currentTourName {
                return """
                    You're currently on \"\(tourName)\". Follow the stops in order for the best experience. \
                    Each stop has interesting details — tap on them to learn more. If you'd like a different \
                    type of tour, just let me know and I'll create one based on your interests!
                    """
            }
            return """
                I'd love to create a personalized tour for you in \(location)! I can generate tours focused \
                on history, food, culture, nature, architecture, or art. Just tell me what interests you, \
                or I can create a general highlights tour. What sounds good?
                """
        }

        // Photo/Instagram questions
        if lowered.contains("photo") || lowered.contains("instagram") || lowered.contains("picture")
            || lowered.contains("camera") {
            return """
                \(location) has plenty of photogenic spots! Look for viewpoints, interesting architecture, \
                and vibrant street scenes. Golden hour (just after sunrise or before sunset) gives the best \
                lighting. The landmarks on your map are great starting points for photos. \
                Want me to create a tour focused on the most photogenic spots?
                """
        }

        // Greeting
        if lowered.contains("hello") || lowered.contains("hi") || lowered.contains("hey")
            || lowered.hasPrefix("yo") {
            return """
                Hello! Welcome to \(location). I'm your AI travel guide, here to help you explore and \
                discover amazing places. I can create walking tours, answer questions about the area, \
                and point out interesting spots nearby. What would you like to know?
                """
        }

        // Default contextual response
        let nearbyContext = context.nearbyPOINames.isEmpty
            ? ""
            : " Nearby, you'll find places like \(context.nearbyPOINames.prefix(3).joined(separator: ", "))."

        return """
            That's a great question about \(location)! While I work best with specific topics like food, history, \
            culture, and navigation, I can tell you that this area has plenty to offer.\(nearbyContext) \
            Try asking me about restaurants, historical sites, safety tips, or let me create a themed tour for you!
            """
    }
}
