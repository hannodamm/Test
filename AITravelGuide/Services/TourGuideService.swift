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
        numberOfStops: Int? = nil
    ) async -> Tour? {
        isGeneratingTour = true
        defer { isGeneratingTour = false }

        var locationName = placemark?.locality ?? "the area"
        if locationName == "the area" {
            if let geocoded = await reverseGeocode(coordinate) {
                locationName = geocoded
            }
        }

        // Route curated categories to template-based generation — they have fixed stops.
        if category.isCurated {
            if let tour = await generateCuratedTour(
                coordinate: coordinate,
                locationName: locationName,
                category: category
            ) {
                self.currentTour = tour
                return tour
            }
        }

        // Resolve stop count from user's duration preference when not explicitly specified.
        let duration = GuidePreferences.currentDuration
        let resolvedStopCount = numberOfStops ?? duration.stopCount.upperBound
        let radiusMeters = GuidePreferences.currentRadiusMeters

        // AI-first approach: Ask Claude to design the tour, then geocode the stops
        if APIKeyManager.shared.hasAPIKey {
            if let tour = await generateAIDesignedTour(
                coordinate: coordinate,
                locationName: locationName,
                category: category,
                numberOfStops: resolvedStopCount,
                durationMinutes: duration.rawValue,
                radiusMeters: radiusMeters
            ) {
                self.currentTour = tour
                return tour
            }
        }

        // Fallback: MapKit-based tour when no API key or AI fails
        return await generateMapKitFallbackTour(
            coordinate: coordinate,
            locationName: locationName,
            category: category,
            numberOfStops: resolvedStopCount
        )
    }

    // MARK: - Curated Tour Generation (Template-based)

    private func generateCuratedTour(
        coordinate: CLLocationCoordinate2D,
        locationName: String,
        category: TourCategory
    ) async -> Tour? {
        guard let template = MilanTourTemplates.template(for: category)
            ?? MunichTourTemplates.template(for: category) else { return nil }

        // Geocode all stops
        var tourStops: [TourStop] = []
        for (index, templateStop) in template.stops.enumerated() {
            let resolvedCoord = await geocodeStop(
                query: templateStop.searchQuery,
                near: coordinate
            ) ?? coordinate

            // Geocode discovery points
            var discoveryPoints: [DiscoveryPoint] = []
            for dp in templateStop.discoveryPoints {
                let dpCoord = await geocodeStop(
                    query: dp.searchQuery,
                    near: resolvedCoord
                ) ?? resolvedCoord

                discoveryPoints.append(DiscoveryPoint(
                    name: dp.name,
                    description: dp.description,
                    coordinate: dpCoord,
                    iconSystemName: dp.iconSystemName
                ))
            }

            tourStops.append(TourStop(
                name: templateStop.name,
                description: templateStop.description,
                coordinate: resolvedCoord,
                orderIndex: index,
                durationMinutes: templateStop.durationMinutes,
                historicalNote: templateStop.historicalNote,
                historicalFacts: templateStop.historicalFacts,
                tips: templateStop.tip,
                imageSystemName: iconForType(templateStop.iconType),
                walkingNarration: templateStop.walkingNarration,
                discoveryPoints: discoveryPoints.isEmpty ? nil : discoveryPoints
            ))
        }

        // Filter out stops that couldn't be geocoded (still at the start coordinate)
        let validStops = tourStops.filter { stop in
            let d = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
                .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
            return d > 10
        }

        guard !validStops.isEmpty else { return nil }

        // Optimize walking route order based on geocoded coordinates
        let reindexedStops = optimizeStopOrder(stops: validStops, from: coordinate)

        // Optionally enrich with Claude if API key available and template is a skeleton
        var finalStops = reindexedStops
        if template.isSkeleton, APIKeyManager.shared.hasAPIKey {
            if let enriched = await enrichStopsWithClaude(
                stops: reindexedStops,
                template: template,
                locationName: locationName
            ) {
                finalStops = enriched
            }
        }

        let totalDistance = calculateRouteDistance(stops: finalStops, from: coordinate)
        let walkingMinutes = Int(totalDistance / 80.0)
        let stopMinutes = finalStops.reduce(0) { $0 + $1.durationMinutes }

        return Tour(
            name: template.tourName,
            description: template.tourDescription,
            stops: finalStops,
            estimatedDurationMinutes: walkingMinutes + stopMinutes,
            distanceMeters: totalDistance,
            category: category,
            centerCoordinate: coordinate,
            locationName: locationName,
            narrativeThread: template.narrativeThread,
            guidePersona: GuidePreferences.selectedPersona ?? template.guidePersona,
            templateId: template.id
        )
    }

    // MARK: - Claude Enrichment for Template Tours

    private func enrichStopsWithClaude(
        stops: [TourStop],
        template: TourTemplate,
        locationName: String
    ) async -> [TourStop]? {
        guard let apiKey = APIKeyManager.shared.claudeAPIKey, !apiKey.isEmpty else { return nil }

        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 6..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }

        let stopsList = stops.enumerated().map { index, stop in
            """
            Stop \(index + 1): \(stop.name)
            Description: \(stop.description)
            Walking narration: \(stop.walkingNarration ?? "none")
            Historical note: \(stop.historicalNote ?? "none")
            Tip: \(stop.tips ?? "none")
            """
        }.joined(separator: "\n\n")

        let prompt = """
        You are \(template.guidePersona.name), \(template.guidePersona.tagline). \
        Your voice style: \(template.guidePersona.voiceStyle).

        Rewrite the descriptions for this \(template.tourName) tour in \(locationName). \
        It's currently \(timeOfDay). The narrative thread is: \(template.narrativeThread)

        Current stops:
        \(stopsList)

        Rewrite each stop's description and walking narration IN CHARACTER as \(template.guidePersona.name). \
        Make them vivid, personal, and time-aware (reference \(timeOfDay) light, atmosphere, etc. where natural). \
        Keep historical notes factual. Keep tips practical.

        Respond in this EXACT JSON format (no markdown, no code fences):
        {
          "stops": [
            {
              "description": "rewritten description",
              "walkingNarration": "rewritten walking narration or null",
              "historicalNote": "keep or improve historical note or null",
              "tip": "keep or improve tip or null"
            }
          ]
        }
        """

        var systemParts = ["You are a charismatic tour guide. Respond only with valid JSON."]
        let modifier = GuidePreferences.systemPromptModifier
        if !modifier.isEmpty { systemParts.append(modifier) }
        let system = systemParts.joined(separator: " ")
        let messages = [APIMessage(role: "user", content: prompt)]

        do {
            let responseText = try await callClaudeAPI(apiKey: apiKey, system: system, messages: messages)

            var cleaned = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleaned.hasPrefix("```") {
                cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
                cleaned = cleaned.replacingOccurrences(of: "```", with: "")
                cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard let data = cleaned.data(using: .utf8) else { return nil }

            struct EnrichedStops: Decodable {
                let stops: [EnrichedStop]
            }
            struct EnrichedStop: Decodable {
                let description: String?
                let walkingNarration: String?
                let historicalNote: String?
                let tip: String?
            }

            let enriched = try JSONDecoder().decode(EnrichedStops.self, from: data)

            // Merge enriched content back, keeping coordinates and structure
            var result: [TourStop] = []
            for (index, stop) in stops.enumerated() {
                if index < enriched.stops.count {
                    let e = enriched.stops[index]
                    result.append(TourStop(
                        name: stop.name,
                        description: e.description ?? stop.description,
                        coordinate: stop.coordinate,
                        orderIndex: stop.orderIndex,
                        durationMinutes: stop.durationMinutes,
                        historicalNote: e.historicalNote ?? stop.historicalNote,
                        tips: e.tip ?? stop.tips,
                        imageSystemName: stop.imageSystemName,
                        walkingNarration: e.walkingNarration ?? stop.walkingNarration,
                        discoveryPoints: stop.discoveryPoints
                    ))
                } else {
                    result.append(stop)
                }
            }
            return result
        } catch {
            return nil // Fall back to template content
        }
    }

    // MARK: - AI-First Tour Generation

    /// Claude designs the entire tour — picks the best stops, writes descriptions,
    /// then we geocode each stop via MapKit to get real coordinates.
    private func generateAIDesignedTour(
        coordinate: CLLocationCoordinate2D,
        locationName: String,
        category: TourCategory,
        numberOfStops: Int,
        durationMinutes: Int,
        radiusMeters: Double
    ) async -> Tour? {
        guard let apiKey = APIKeyManager.shared.claudeAPIKey, !apiKey.isEmpty else {
            return nil
        }

        let categoryGuidance = guidanceForCategory(category, locationName: locationName)

        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 6..<12: timeOfDay = "morning"
        case 12..<17: timeOfDay = "afternoon"
        case 17..<21: timeOfDay = "evening"
        default: timeOfDay = "night"
        }

        let radiusString: String = {
            if radiusMeters < 1000 { return "\(Int(radiusMeters)) meters" }
            return String(format: "%.1f km", radiusMeters / 1000)
        }()

        let prompt = """
        Design a \(category.rawValue) walking tour in \(locationName) \
        (near \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))).
        It's currently \(timeOfDay) — tailor tips, atmosphere descriptions, and recommendations accordingly.

        Target duration: about \(durationMinutes) minutes total, walking at a relaxed pace.
        Pick \(numberOfStops) real, specific places that a knowledgeable local guide would recommend. \
        They should all lie within a \(radiusString) walking radius of the starting coordinate and be ordered as a logical walking route, so the total walking distance stays comfortable for the target duration.

        IMPORTANT - What to include for this \(category.rawValue) tour:
        \(categoryGuidance)

        Respond in this EXACT JSON format (no markdown, no code fences, just raw JSON):
        {
          "tourName": "A creative, evocative tour name specific to this location",
          "tourDescription": "A compelling 1-2 sentence description that makes someone excited to take this tour",
          "narrativeThread": "A thematic arc connecting all stops — what story does this tour tell?",
          "guidePersona": {
            "name": "A local-sounding first name",
            "tagline": "A short description like 'lifelong local and history buff'",
            "voiceStyle": "2-3 adjectives describing how this guide speaks",
            "greeting": "A warm opening line in character",
            "signoff": "A memorable farewell line in character"
          },
          "stops": [
            {
              "name": "The actual, real name of this place",
              "searchQuery": "A precise search query to find this place on Apple Maps (e.g. 'Marienplatz Munich' or 'English Garden Munich')",
              "description": "A vivid 2-3 sentence description written as spoken narration — use directions like 'Look to your left...', 'Notice the...', 'As you face the entrance...'",
              "historicalFacts": [
                {
                  "year": "YYYY or a range like '1680s', or null if not applicable",
                  "title": "Short fact title (3-6 words)",
                  "content": "A vivid 1-2 sentence fact",
                  "category": "one of: general | architecture | culture | event | famous | legend | art | nature"
                }
              ],
              "tip": "A practical insider tip (best time to visit, what to look for, where to stand, what to order, etc.)",
              "durationMinutes": 15,
              "iconType": "landmark",
              "walkingNarration": "What to notice and enjoy while walking from the previous stop to this one. Write as spoken — 'As you walk along...', 'On your right you'll see...' (null for the first stop)",
              "discoveryPoints": [
                {
                  "name": "Something interesting to notice between stops",
                  "description": "A brief, vivid spoken description — 'Look to your left...', 'Notice the...'",
                  "searchQuery": "A search query to find this point on a map (e.g. 'Fountain of Neptune Florence')",
                  "iconSystemName": "An SF Symbol name like 'building.2', 'leaf.fill', 'music.note', 'paintpalette.fill', or 'eye.fill'"
                }
              ]
            }
          ]
        }

        Rules:
        - Only suggest REAL places that actually exist in \(locationName)
        - Each stop must have a unique, specific name (not generic like "Local Restaurant")
        - The searchQuery must be specific enough to find the exact place on a map
        - iconType must be one of: landmark, restaurant, museum, park, shopping, entertainment, transit, hotel, historical, viewpoint
        - Order stops as a logical walking route, not random
        - Make descriptions vivid and specific to each place, never generic
        - DO NOT just list museums unless this is specifically an Art tour
        - Each stop MUST have 2-3 discoveryPoints with a REQUIRED searchQuery for each — things to notice on the walk between stops
        - discoveryPoints searchQuery must be specific enough to locate on a map (e.g. 'Palazzo della Ragione Milan', not just 'old building')
        - walkingNarration should be null for the first stop
        - historicalFacts should have 2-4 facts per stop, each categorized correctly and with a year when known. Mix categories (e.g. one architecture fact, one famous person fact, one legend) rather than all in the same category.
        """

        var systemParts = [
            """
            You are an expert local travel guide for \(locationName) who designs unforgettable walking tours. \
            You know the best spots, hidden gems, and the stories behind every place. \
            Respond only with valid JSON, no markdown formatting.
            """
        ]
        let aiModifier = GuidePreferences.systemPromptModifier
        if !aiModifier.isEmpty { systemParts.append(aiModifier) }
        if let userPersona = GuidePreferences.selectedPersona {
            systemParts.append(
                "The tour's guide character is fixed: \(userPersona.name), \(userPersona.tagline). Voice style: \(userPersona.voiceStyle). Write the tour name, description, and every stop description in that voice. In the JSON guidePersona field, echo back exactly: name=\"\(userPersona.name)\", tagline=\"\(userPersona.tagline)\", voiceStyle=\"\(userPersona.voiceStyle)\", greeting=\"\(userPersona.greeting)\", signoff=\"\(userPersona.signoff)\"."
            )
        }
        let system = systemParts.joined(separator: "\n\n")
        let messages = [APIMessage(role: "user", content: prompt)]

        do {
            let responseText = try await callClaudeAPI(apiKey: apiKey, system: system, messages: messages)
            guard let aiTour = parseAIDesignedTour(responseText) else { return nil }

            // Geocode each stop via MapKit to get real coordinates
            var tourStops: [TourStop] = []
            for (index, aiStop) in aiTour.stops.enumerated() {
                let resolvedCoord = await geocodeStop(
                    query: aiStop.searchQuery,
                    near: coordinate
                ) ?? coordinate

                // Geocode discovery points
                var discoveryPoints: [DiscoveryPoint] = []
                for dp in aiStop.discoveryPoints {
                    let dpCoord = await geocodeStop(
                        query: dp.searchQuery,
                        near: resolvedCoord
                    ) ?? resolvedCoord

                    discoveryPoints.append(DiscoveryPoint(
                        name: dp.name,
                        description: dp.description,
                        coordinate: dpCoord,
                        iconSystemName: dp.iconSystemName ?? "eye.fill"
                    ))
                }

                tourStops.append(TourStop(
                    name: aiStop.name,
                    description: aiStop.description,
                    coordinate: resolvedCoord,
                    orderIndex: index,
                    durationMinutes: aiStop.durationMinutes,
                    historicalNote: aiStop.historicalFacts.first?.content,
                    historicalFacts: aiStop.historicalFacts.isEmpty ? nil : aiStop.historicalFacts,
                    tips: aiStop.tip,
                    imageSystemName: iconForType(aiStop.iconType),
                    walkingNarration: aiStop.walkingNarration,
                    discoveryPoints: discoveryPoints.isEmpty ? nil : discoveryPoints
                ))
            }

            // Filter out stops that couldn't be geocoded (still at the start coordinate)
            let validStops = tourStops.filter { stop in
                let d = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
                    .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                return d > 10 // at least 10m from start point means it was geocoded
            }

            guard !validStops.isEmpty else { return nil }

            // Optimize walking route order based on geocoded coordinates
            let reindexedStops = optimizeStopOrder(stops: validStops, from: coordinate)

            let totalDistance = calculateRouteDistance(stops: reindexedStops, from: coordinate)
            let walkingMinutes = Int(totalDistance / 80.0)
            let stopMinutes = reindexedStops.reduce(0) { $0 + $1.durationMinutes }

            return Tour(
                name: aiTour.tourName,
                description: aiTour.tourDescription,
                stops: reindexedStops,
                estimatedDurationMinutes: walkingMinutes + stopMinutes,
                distanceMeters: totalDistance,
                category: category,
                centerCoordinate: coordinate,
                locationName: locationName,
                narrativeThread: aiTour.narrativeThread,
                guidePersona: GuidePreferences.selectedPersona ?? aiTour.guidePersona
            )
        } catch {
            return nil
        }
    }

    /// Geocode a stop name via MapKit to find its real coordinates.
    private func geocodeStop(
        query: String,
        near coordinate: CLLocationCoordinate2D
    ) async -> CLLocationCoordinate2D? {
        let results = await mapSearchService.searchForQuery(
            query,
            coordinate: coordinate,
            radius: 5000
        )
        return results.first?.coordinate
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "landmark": return "star.fill"
        case "restaurant": return "fork.knife"
        case "museum": return "building.columns.fill"
        case "park": return "leaf.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "ticket.fill"
        case "transit": return "bus.fill"
        case "hotel": return "bed.double.fill"
        case "historical": return "clock.fill"
        case "viewpoint": return "eye.fill"
        default: return "mappin.circle.fill"
        }
    }

    // MARK: - AI Response Parsing

    private struct AIDesignedTour {
        let tourName: String
        let tourDescription: String
        let narrativeThread: String?
        let guidePersona: GuidePersona?
        let stops: [AIDesignedStop]
    }

    private struct AIDesignedStop {
        let name: String
        let searchQuery: String
        let description: String
        let historicalFacts: [HistoricalFact]
        let tip: String?
        let durationMinutes: Int
        let iconType: String
        let walkingNarration: String?
        let discoveryPoints: [AIDiscoveryPoint]
    }

    private struct AIDiscoveryPoint {
        let name: String
        let description: String
        let searchQuery: String
        let iconSystemName: String?
    }

    private func parseAIDesignedTour(_ json: String) -> AIDesignedTour? {
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
            let narrativeThread: String?
            let guidePersona: GuidePersonaJSON?
            let stops: [StopJSON]
        }

        struct GuidePersonaJSON: Decodable {
            let name: String?
            let tagline: String?
            let voiceStyle: String?
            let greeting: String?
            let signoff: String?
        }

        struct StopJSON: Decodable {
            let name: String
            let searchQuery: String
            let description: String
            let historicalNote: String?   // Legacy single-string form (kept for compat)
            let historicalFacts: [HistoricalFactJSON]?
            let tip: String?
            let durationMinutes: Int?
            let iconType: String?
            let walkingNarration: String?
            let discoveryPoints: [DiscoveryPointJSON]?
        }

        struct HistoricalFactJSON: Decodable {
            let year: String?
            let title: String
            let content: String
            let category: String?
        }

        struct DiscoveryPointJSON: Decodable {
            let name: String
            let description: String
            let searchQuery: String?
            let iconSystemName: String?
        }

        do {
            let parsed = try JSONDecoder().decode(TourJSON.self, from: data)

            let persona: GuidePersona?
            if let p = parsed.guidePersona,
               let name = p.name, !name.isEmpty {
                persona = GuidePersona(
                    name: name,
                    tagline: p.tagline ?? "",
                    voiceStyle: p.voiceStyle ?? "",
                    greeting: p.greeting ?? "",
                    signoff: p.signoff ?? ""
                )
            } else {
                persona = nil
            }

            let stops = parsed.stops.map { stop in
                let dps = (stop.discoveryPoints ?? []).map { dp -> AIDiscoveryPoint in
                    let query = (dp.searchQuery?.isEmpty == false) ? dp.searchQuery! : "\(dp.name) \(stop.searchQuery)"
                    return AIDiscoveryPoint(
                        name: dp.name,
                        description: dp.description,
                        searchQuery: query,
                        iconSystemName: dp.iconSystemName
                    )
                }

                // Prefer the new structured facts array; fall back to synthesizing
                // one fact from the legacy historicalNote if that's all we got.
                var facts: [HistoricalFact] = (stop.historicalFacts ?? []).map { f in
                    HistoricalFact(
                        year: f.year,
                        title: f.title,
                        content: f.content,
                        category: FactCategory(rawValue: f.category ?? "general") ?? .general
                    )
                }
                if facts.isEmpty, let note = stop.historicalNote, !note.isEmpty {
                    facts = [HistoricalFact(title: "Historical Note", content: note, category: .general)]
                }

                return AIDesignedStop(
                    name: stop.name,
                    searchQuery: stop.searchQuery,
                    description: stop.description,
                    historicalFacts: facts,
                    tip: stop.tip,
                    durationMinutes: stop.durationMinutes ?? 10,
                    iconType: stop.iconType ?? "landmark",
                    walkingNarration: stop.walkingNarration,
                    discoveryPoints: dps
                )
            }
            return AIDesignedTour(
                tourName: parsed.tourName,
                tourDescription: parsed.tourDescription,
                narrativeThread: parsed.narrativeThread,
                guidePersona: persona,
                stops: stops
            )
        } catch {
            return nil
        }
    }

    // MARK: - MapKit Fallback Tour (when no API key)

    private func generateMapKitFallbackTour(
        coordinate: CLLocationCoordinate2D,
        locationName: String,
        category: TourCategory,
        numberOfStops: Int
    ) async -> Tour? {
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

        let selected = selectOptimalStops(
            from: uniquePOIs,
            startCoordinate: coordinate,
            count: min(numberOfStops, uniquePOIs.count)
        )

        let stops = selected.enumerated().map { index, poi in
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

        let totalDistance = calculateRouteDistance(stops: stops, from: coordinate)
        let walkingMinutes = Int(totalDistance / 80.0)
        let stopMinutes = stops.reduce(0) { $0 + $1.durationMinutes }

        let tour = Tour(
            name: generateTourName(category: category, location: locationName),
            description: generateTourDescription(category: category, location: locationName, stopCount: stops.count),
            stops: stops,
            estimatedDurationMinutes: walkingMinutes + stopMinutes,
            distanceMeters: totalDistance,
            category: category,
            centerCoordinate: coordinate,
            locationName: locationName
        )

        self.currentTour = tour
        return tour
    }

    private func callClaudeAPI(
        apiKey: String,
        system: String,
        messages: [APIMessage]
    ) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url, timeoutInterval: 15)
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
            model: "claude-sonnet-4-6",
            max_tokens: 4096,
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

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            return placemarks.first?.locality
        } catch {
            return nil
        }
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
        // Use the tour's stored location name when placemark isn't available
        // (e.g. touring Munich from a Simulator in Cupertino)
        let city = placemark?.locality ?? currentTour?.locationName
        let country = placemark?.country

        return LocationContext(
            city: city,
            country: country,
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

    private func guidanceForCategory(_ category: TourCategory, locationName: String) -> String {
        switch category {
        case .historical:
            return """
            Focus on HISTORIC SITES, not museums. Pick places like: old city gates, medieval squares, \
            ancient ruins, historic battlefields, old town halls, historic bridges, war memorials, \
            historic churches/cathedrals (for their age, not religion), former royal residences, \
            historic marketplaces, old fortifications/walls, and sites where important events happened. \
            Each stop should tell a story about \(locationName)'s past. Avoid museums entirely.
            """
        case .cultural:
            return """
            Focus on places that showcase the LIVING CULTURE of \(locationName): theaters, opera houses, \
            local markets where residents shop, traditional neighborhoods, places of worship known for \
            their community role, cultural centers, traditional craft workshops, iconic local gathering \
            spots (famous cafes, beer halls, tea houses), festival grounds, and places that represent \
            the daily life and traditions of locals. Avoid museums and purely historic monuments.
            """
        case .food:
            return """
            Pick the best SPECIFIC restaurants, bakeries, food markets, street food spots, \
            breweries/wineries, cafes, and food halls in \(locationName). Choose places famous for \
            a particular dish or drink. Include a mix: one iconic/famous spot, one hidden local gem, \
            one market or food hall, and others. Name the actual establishment, not just "a restaurant."
            """
        case .nature:
            return """
            Focus on GREEN SPACES AND NATURE: parks, botanical gardens, riverside walks, lakes, \
            hilltop viewpoints, nature reserves, urban forests, garden terraces, waterfall spots, \
            and scenic promenades. Pick places where someone can enjoy being outdoors and in nature, \
            not buildings.
            """
        case .architecture:
            return """
            Focus on BUILDINGS AND STRUCTURES worth seeing for their design: cathedrals, palaces, \
            modern skyscrapers, famous bridges, opera houses, train stations with grand architecture, \
            unique residential buildings, city halls, towers, and buildings by famous architects. \
            Each stop should be a building or structure, not a museum or park.
            """
        case .art:
            return """
            Focus on ART: art museums, galleries, street art districts/murals, sculpture gardens, \
            public art installations, artist studios open to visitors, design museums, photography \
            galleries, and art-focused neighborhoods. This is the one tour type where museums are \
            appropriate — but mix in outdoor art and galleries too.
            """
        case .nightlife:
            return """
            Pick the best EVENING AND NIGHT spots: iconic bars, rooftop bars with views, cocktail bars, \
            live music venues, jazz clubs, beer gardens, wine bars, night markets, and areas known for \
            their nightlife strip. Choose specific named establishments, not generic categories.
            """
        case .general:
            return """
            Pick the TOP HIGHLIGHTS a first-time visitor absolutely must see in \(locationName). \
            Include a mix: one iconic landmark, one great viewpoint, one cultural spot, one food \
            recommendation, and one hidden gem that most tourists miss. Make it a "best of" tour.
            """
        default:
            // Curated categories won't reach here, but provide a fallback
            return "Pick the best spots for a memorable walking tour in \(locationName)."
        }
    }

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
        default:
            return ["landmark", "tourist attraction", "famous"]
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

    // MARK: - Route Optimization

    /// Reorders stops into an efficient walking route using nearest-neighbor + 2-opt improvement.
    private func optimizeStopOrder(
        stops: [TourStop],
        from start: CLLocationCoordinate2D
    ) -> [TourStop] {
        guard stops.count > 2 else {
            return stops.enumerated().map { index, stop in
                TourStop(name: stop.name, description: stop.description,
                         coordinate: stop.coordinate, orderIndex: index,
                         durationMinutes: stop.durationMinutes,
                         historicalNote: stop.historicalNote, tips: stop.tips,
                         imageSystemName: stop.imageSystemName,
                         walkingNarration: stop.walkingNarration,
                         discoveryPoints: stop.discoveryPoints)
            }
        }

        // Step 1: Nearest-neighbor ordering
        var remaining = stops
        var ordered: [TourStop] = []
        var currentCoord = start

        while !remaining.isEmpty {
            let currentLoc = CLLocation(latitude: currentCoord.latitude, longitude: currentCoord.longitude)
            remaining.sort { s1, s2 in
                CLLocation(latitude: s1.latitude, longitude: s1.longitude).distance(from: currentLoc) <
                CLLocation(latitude: s2.latitude, longitude: s2.longitude).distance(from: currentLoc)
            }
            let next = remaining.removeFirst()
            ordered.append(next)
            currentCoord = next.coordinate
        }

        // Step 2: 2-opt improvement to remove crossings
        ordered = twoOptImprove(ordered, from: start)

        // Determine which stops changed predecessor and clear their walkingNarration
        let oldNames = stops.map { $0.name }
        let newNames = ordered.map { $0.name }

        return ordered.enumerated().map { index, stop in
            // Clear walkingNarration if predecessor changed (or for first stop)
            let predecessorChanged: Bool
            if index == 0 {
                predecessorChanged = false // first stop narration is typically nil anyway
            } else {
                let oldIndex = oldNames.firstIndex(of: stop.name)
                let oldPredecessor = oldIndex.flatMap { $0 > 0 ? oldNames[$0 - 1] : nil }
                let newPredecessor = newNames[index - 1]
                predecessorChanged = oldPredecessor != newPredecessor
            }

            return TourStop(
                name: stop.name, description: stop.description,
                coordinate: stop.coordinate, orderIndex: index,
                durationMinutes: stop.durationMinutes,
                historicalNote: stop.historicalNote, tips: stop.tips,
                imageSystemName: stop.imageSystemName,
                walkingNarration: predecessorChanged ? nil : stop.walkingNarration,
                discoveryPoints: stop.discoveryPoints)
        }
    }

    /// Standard 2-opt: iteratively reverse segments to reduce total route distance.
    private func twoOptImprove(_ route: [TourStop], from start: CLLocationCoordinate2D) -> [TourStop] {
        guard route.count > 2 else { return route }

        func totalDistance(_ r: [TourStop]) -> Double {
            var dist: Double = 0
            var prev = CLLocation(latitude: start.latitude, longitude: start.longitude)
            for stop in r {
                let loc = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
                dist += prev.distance(from: loc)
                prev = loc
            }
            return dist
        }

        var best = route
        var bestDist = totalDistance(best)
        var improved = true

        while improved {
            improved = false
            for i in 0..<(best.count - 1) {
                for j in (i + 1)..<best.count {
                    var candidate = best
                    candidate[(i)...j].reverse()
                    let candidateDist = totalDistance(candidate)
                    if candidateDist < bestDist {
                        best = candidate
                        bestDist = candidateDist
                        improved = true
                    }
                }
            }
        }

        return best
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
        default: return "Explore \(location)"
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
        default:
            return "\(base), discovering the best this area has to offer."
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
