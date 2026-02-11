import Foundation
import CoreLocation
import MapKit

@MainActor
final class TourGuideService: ObservableObject {
    @Published var isGeneratingTour: Bool = false
    @Published var currentTour: Tour?

    private let mapSearchService = MapSearchService()
    private let claudeAPI = ClaudeAPIService()

    // MARK: - Tour Generation

    func generateTour(
        near coordinate: CLLocationCoordinate2D,
        placemark: CLPlacemark?,
        category: TourCategory = .general,
        numberOfStops: Int = 5
    ) async -> Tour? {
        isGeneratingTour = true
        defer { isGeneratingTour = false }

        // Use targeted search queries per tour type for distinct results
        let searchQueries = searchQueriesForTour(category)
        var allPOIs: [PointOfInterest] = []

        for query in searchQueries {
            let results = await mapSearchService.searchForQuery(
                query,
                coordinate: coordinate,
                radius: 2000
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

        let locationName = placemark?.locality ?? reverseGeocodeSync(coordinate) ?? "the area"

        // Try AI-powered tour generation first, fall back to templates
        let stops: [TourStop]
        var tourName: String
        var tourDescription: String

        if APIKeyManager.shared.hasAPIKey {
            let aiContent = await generateAITourContent(
                stops: selected,
                category: category,
                locationName: locationName,
                coordinate: coordinate
            )
            stops = selected.enumerated().map { index, poi in
                let content = aiContent?.stops[safe: index]
                return TourStop(
                    name: poi.name,
                    description: content?.description ?? generateStopDescription(poi: poi, locationName: locationName),
                    coordinate: poi.coordinate,
                    orderIndex: index,
                    durationMinutes: content?.durationMinutes ?? estimateStopDuration(poi),
                    historicalNote: content?.historicalNote,
                    tips: content?.tip,
                    imageSystemName: poi.category.systemImage
                )
            }
            tourName = aiContent?.tourName ?? generateTourName(category: category, location: locationName)
            tourDescription = aiContent?.tourDescription ?? generateTourDescription(category: category, location: locationName, stopCount: stops.count)
        } else {
            stops = selected.enumerated().map { index, poi in
                TourStop(
                    name: poi.name,
                    description: generateStopDescription(poi: poi, locationName: locationName),
                    coordinate: poi.coordinate,
                    orderIndex: index,
                    durationMinutes: estimateStopDuration(poi),
                    historicalNote: generateHistoricalNote(poi: poi, locationName: locationName),
                    tips: generateTip(poi: poi),
                    imageSystemName: poi.category.systemImage
                )
            }
            tourName = generateTourName(category: category, location: locationName)
            tourDescription = generateTourDescription(category: category, location: locationName, stopCount: stops.count)
        }

        let totalDistance = calculateRouteDistance(stops: stops, from: coordinate)
        let walkingMinutes = Int(totalDistance / 80.0)
        let stopMinutes = stops.reduce(0) { $0 + $1.durationMinutes }

        let tour = Tour(
            name: tourName,
            description: tourDescription,
            stops: stops,
            estimatedDurationMinutes: walkingMinutes + stopMinutes,
            distanceMeters: totalDistance,
            category: category,
            centerCoordinate: coordinate
        )

        self.currentTour = tour
        return tour
    }

    // MARK: - AI Tour Content Generation

    private struct AITourContent {
        let tourName: String
        let tourDescription: String
        let stops: [AIStopContent]
    }

    private struct AIStopContent {
        let description: String
        let historicalNote: String?
        let tip: String?
        let durationMinutes: Int
    }

    private func generateAITourContent(
        stops: [PointOfInterest],
        category: TourCategory,
        locationName: String,
        coordinate: CLLocationCoordinate2D
    ) async -> AITourContent? {
        guard let apiKey = APIKeyManager.shared.claudeAPIKey, !apiKey.isEmpty else {
            return nil
        }

        let stopList = stops.enumerated().map { index, poi in
            "Stop \(index + 1): \"\(poi.name)\" (Category: \(poi.category.rawValue), Address: \(poi.address ?? "N/A"))"
        }.joined(separator: "\n")

        let prompt = """
        Create a \(category.rawValue) walking tour in \(locationName) (coordinates: \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))).

        The tour visits these \(stops.count) stops in order:
        \(stopList)

        Respond in this EXACT JSON format (no markdown, no code fences, just raw JSON):
        {
          "tourName": "A creative, catchy tour name",
          "tourDescription": "A compelling 1-2 sentence tour description that makes people want to take this tour",
          "stops": [
            {
              "description": "A vivid 2-3 sentence description of this specific place. Include what makes it special, what visitors will see, and why it matters. Be specific to THIS place, not generic.",
              "historicalNote": "An interesting historical fact or story about this place, or null if not applicable",
              "tip": "A practical insider tip for visiting this specific place",
              "durationMinutes": 15
            }
          ]
        }

        Important:
        - Make each stop description unique and specific to that actual place
        - Include real, accurate information about the places
        - The tour name should be creative and evocative, not just "Historical Walk"
        - Tips should be practical and specific (best time to visit, what to look for, where to stand for best view, etc.)
        - Duration should reflect how long someone would actually spend there (5-30 min)
        - If you're unsure about a place, focus on what category it is and what visitors typically experience there
        """

        let system = "You are an expert travel guide who creates engaging walking tours. Respond only with valid JSON, no markdown formatting."
        let messages = [APIMessage(role: "user", content: prompt)]

        do {
            let responseText = try await callClaudeAPI(apiKey: apiKey, system: system, messages: messages)
            return parseAITourContent(responseText)
        } catch {
            return nil
        }
    }

    private func callClaudeAPI(
        apiKey: String,
        system: String,
        messages: [APIMessage]
    ) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        struct APIRequest: Encodable {
            let model: String
            let max_tokens: Int
            let system: String
            let messages: [APIMessage]
        }

        let body = APIRequest(
            model: "claude-sonnet-4-5-20250929",
            max_tokens: 2048,
            system: system,
            messages: messages
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct APIResponse: Decodable {
            let content: [ContentBlock]
            struct ContentBlock: Decodable {
                let type: String
                let text: String?
            }
        }

        let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
        return apiResponse.content.first(where: { $0.type == "text" })?.text ?? ""
    }

    private func parseAITourContent(_ json: String) -> AITourContent? {
        // Strip markdown code fences if present
        var cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = cleaned.data(using: .utf8) else { return nil }

        struct TourJSON: Decodable {
            let tourName: String
            let tourDescription: String
            let stops: [StopJSON]
        }

        struct StopJSON: Decodable {
            let description: String
            let historicalNote: String?
            let tip: String?
            let durationMinutes: Int?
        }

        do {
            let parsed = try JSONDecoder().decode(TourJSON.self, from: data)
            let stops = parsed.stops.map { stop in
                AIStopContent(
                    description: stop.description,
                    historicalNote: stop.historicalNote,
                    tip: stop.tip,
                    durationMinutes: stop.durationMinutes ?? 10
                )
            }
            return AITourContent(
                tourName: parsed.tourName,
                tourDescription: parsed.tourDescription,
                stops: stops
            )
        } catch {
            return nil
        }
    }

    private func reverseGeocodeSync(_ coordinate: CLLocationCoordinate2D) -> String? {
        // This is a best-effort helper; the caller provides placemark when available
        return nil
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

    private func searchQueriesForTour(_ category: TourCategory) -> [String] {
        switch category {
        case .historical:
            return ["historic site", "monument", "memorial", "castle", "ruins"]
        case .cultural:
            return ["theater", "cultural center", "temple", "church", "synagogue", "mosque", "library"]
        case .food:
            return ["restaurant", "bakery", "cafe", "food market", "brewery"]
        case .nature:
            return ["park", "garden", "botanical", "lake", "trail"]
        case .architecture:
            return ["cathedral", "palace", "tower", "bridge", "opera house", "city hall"]
        case .art:
            return ["art gallery", "art museum", "street art", "sculpture", "design museum"]
        case .nightlife:
            return ["bar", "cocktail bar", "nightclub", "live music", "rooftop bar"]
        case .general:
            return ["landmark", "museum", "park", "tourist attraction", "famous"]
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

    // MARK: - Template Fallbacks (used when no API key)

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

    private func generateStopDescription(poi: PointOfInterest, locationName: String) -> String {
        switch poi.category {
        case .landmark:
            return "\(poi.name) is a notable landmark in \(locationName). Take a moment to appreciate its significance and capture some photos."
        case .restaurant:
            return "A popular dining spot in \(locationName). \(poi.name) offers a taste of local flavors and cuisine."
        case .museum:
            return "\(poi.name) showcases the cultural heritage and stories of \(locationName). A must-visit for curious travelers."
        case .park:
            return "\(poi.name) provides a refreshing green space in \(locationName). Perfect for a peaceful break during your tour."
        case .historical:
            return "Step back in time at \(poi.name), a place rich with the history of \(locationName)."
        case .viewpoint:
            return "Enjoy panoramic views from \(poi.name). One of the best vantage points in \(locationName)."
        case .entertainment:
            return "\(poi.name) is a hub of entertainment and activity in \(locationName)."
        default:
            return "Visit \(poi.name), one of the interesting spots in \(locationName)."
        }
    }

    private func generateHistoricalNote(poi: PointOfInterest, locationName: String) -> String? {
        switch poi.category {
        case .historical, .museum, .landmark:
            return "This location has been an important part of \(locationName)'s heritage. Ask your AI guide for more details about its history."
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

        if lowered.contains("eat") || lowered.contains("food") || lowered.contains("restaurant")
            || lowered.contains("hungry") || lowered.contains("lunch") || lowered.contains("dinner")
            || lowered.contains("breakfast") || lowered.contains("cafe") {
            let foodPOIs = context.nearbyPOINames.isEmpty
                ? "various local restaurants"
                : context.nearbyPOINames.prefix(3).joined(separator: ", ")
            return """
                Great question! \(location) has wonderful dining options. Near you, I'd suggest checking out \(foodPOIs). \
                For an authentic experience, look for places where locals are dining — that's usually a good sign.
                """
        }

        if lowered.contains("history") || lowered.contains("historical") || lowered.contains("old")
            || lowered.contains("ancient") || lowered.contains("heritage") {
            return """
                \(location) has a rich history worth exploring. The area around you has been shaped by centuries \
                of cultural exchange and development. I'd recommend visiting local museums and historical landmarks \
                to dive deeper.
                """
        }

        if lowered.contains("safe") || lowered.contains("safety") || lowered.contains("dangerous")
            || lowered.contains("crime") {
            return """
                Like any destination, \(location) is generally safe for tourists who take standard precautions. \
                Stay aware of your surroundings, keep valuables secure, and stick to well-lit areas at night.
                """
        }

        if lowered.contains("transport") || lowered.contains("bus") || lowered.contains("train")
            || lowered.contains("metro") || lowered.contains("taxi") || lowered.contains("get around")
            || lowered.contains("uber") {
            return """
                Getting around \(location) is part of the adventure! Most cities offer a mix of public transit, \
                ride-sharing, and walking options. Check the Maps app for real-time transit directions.
                """
        }

        if lowered.contains("weather") || lowered.contains("rain") || lowered.contains("temperature")
            || lowered.contains("hot") || lowered.contains("cold") {
            return """
                For current weather conditions in \(location), check your weather app for real-time data. \
                When planning outdoor tours, early morning or late afternoon usually offers the most comfortable conditions.
                """
        }

        if lowered.contains("tour") || lowered.contains("walk") || lowered.contains("explore")
            || lowered.contains("see") || lowered.contains("visit") || lowered.contains("suggest") {
            if let tourName = context.currentTourName {
                return "You're currently on \"\(tourName)\". Follow the stops in order for the best experience."
            }
            return """
                I'd love to create a personalized tour for you in \(location)! I can generate tours focused \
                on history, food, culture, nature, architecture, or art.
                """
        }

        if lowered.contains("hello") || lowered.contains("hi") || lowered.contains("hey")
            || lowered.hasPrefix("yo") {
            return "Hello! Welcome to \(location). I'm your AI travel guide. What would you like to know?"
        }

        let nearbyContext = context.nearbyPOINames.isEmpty
            ? ""
            : " Nearby, you'll find places like \(context.nearbyPOINames.prefix(3).joined(separator: ", "))."
        return """
            That's a great question about \(location)!\(nearbyContext) \
            Try asking me about restaurants, historical sites, safety tips, or let me create a themed tour for you!
            """
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
