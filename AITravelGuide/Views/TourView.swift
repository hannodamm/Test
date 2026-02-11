import SwiftUI
import MapKit

struct TourView: View {
    @EnvironmentObject var tourViewModel: TourViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var exploreViewModel: ExploreViewModel

    @State private var showStopSheet = false
    @State private var showStopChat = false
    @State private var showGuideChat = false
    @State private var showEndTourConfirmation = false
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if tourViewModel.isOnTour, let tour = tourViewModel.currentTour {
                    activeTourView(tour: tour)
                } else if tourViewModel.isGenerating {
                    generatingView
                } else if let tour = tourViewModel.currentTour {
                    tourPreview(tour: tour)
                } else {
                    tourSetupView
                }
            }
            .navigationTitle("Tour")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Tour Setup

    private var tourSetupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.accent)
                    Text("Create a Tour")
                        .font(.title2.bold())
                    Text(exploreViewModel.searchedLocationName != nil
                        ? "Generate a personalized walking tour in \(exploreViewModel.searchedLocationName!)"
                        : "Generate a personalized walking tour based on your current location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Category Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tour Type")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(TourCategory.allCases, id: \.self) { category in
                            TourCategoryCard(
                                category: category,
                                isSelected: tourViewModel.selectedCategory == category
                            ) {
                                tourViewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Location info
                tourLocationInfo
                    .padding(.horizontal)

                // Generate button
                Button {
                    Task {
                        if let customCoord = exploreViewModel.searchedCoordinate {
                            await tourViewModel.generateTour(
                                coordinate: customCoord,
                                placemark: nil
                            )
                        } else if let coord = locationManager.currentLocation?.coordinate {
                            await tourViewModel.generateTour(
                                coordinate: coord,
                                placemark: locationManager.currentPlacemark
                            )
                        }
                    }
                } label: {
                    Label(
                        exploreViewModel.searchedCoordinate != nil
                            ? "Generate Tour in \(exploreViewModel.searchedLocationName ?? "Searched Location")"
                            : "Generate Tour",
                        systemImage: "wand.and.stars"
                    )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationManager.currentLocation == nil && exploreViewModel.searchedCoordinate == nil)
                .padding(.horizontal)

                // Tour history
                if !tourViewModel.tourHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Tours")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tourViewModel.tourHistory) { tour in
                            Button {
                                tourViewModel.currentTour = tour
                                tourViewModel.currentStopIndex = 0
                            } label: {
                                TourHistoryRow(tour: tour)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Tour Location Info

    private var tourLocationInfo: some View {
        Group {
            if let customName = exploreViewModel.searchedLocationName {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(customName)
                            .font(.subheadline.bold())
                        Text("Searched location from Explore tab")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        exploreViewModel.searchedCoordinate = nil
                        exploreViewModel.searchedLocationName = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            } else if locationManager.currentPlacemark != nil {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                    Text(locationManager.locationDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Generating View

    private var generatingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating your tour...")
                .font(.headline)
            Text(exploreViewModel.searchedLocationName != nil
                ? "Finding the best stops in \(exploreViewModel.searchedLocationName!)"
                : "Finding the best stops near you")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Tour Preview

    private func tourPreview(tour: Tour) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Tour info header
                VStack(alignment: .leading, spacing: 8) {
                    Text(tour.name)
                        .font(.title2.bold())
                    Text(tour.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Label(tour.formattedDuration, systemImage: "clock")
                        Label(tour.formattedDistance, systemImage: "figure.walk")
                        Label("\(tour.stops.count) stops", systemImage: "mappin.and.ellipse")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()

                // Mini map
                Map(initialPosition: .region(regionForTour(tour))) {
                    ForEach(tour.stops) { stop in
                        Annotation(stop.name, coordinate: stop.coordinate) {
                            TourStopMarker(stop: stop, isActive: false)
                        }
                    }
                    MapPolyline(coordinates: tour.stops.map { $0.coordinate })
                        .stroke(.blue, lineWidth: 3)
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Stops list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tour Stops")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(tour.stops.enumerated()), id: \.element.id) { index, stop in
                        TourStopCard(stop: stop, index: index, isActive: false, isCompleted: false)
                            .padding(.horizontal)
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        tourViewModel.currentTour = nil
                    } label: {
                        Text("Discard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        tourViewModel.startTour()
                        if let stops = tourViewModel.currentTour?.stops {
                            locationManager.startMonitoringTourStops(stops)
                        }
                    } label: {
                        Label("Start Tour", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    // MARK: - Active Tour

    private func activeTourView(tour: Tour) -> some View {
        VStack(spacing: 0) {
            // Map section
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(tour.stops) { stop in
                    let isActive = stop.id == tourViewModel.currentStop?.id
                    let isCompleted = stop.orderIndex < tourViewModel.currentStopIndex
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        TourStopMarker(stop: stop, isActive: isActive)
                            .opacity(isCompleted ? 0.5 : 1.0)
                    }
                }

                MapPolyline(coordinates: tour.stops.map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(height: 300)
            .onAppear {
                // Center on the first stop when the active tour view appears
                if let firstStop = tour.stops.first {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: firstStop.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    ))
                }
            }

            // Progress bar
            ProgressView(value: tourViewModel.progress)
                .tint(.blue)

            // Current stop info
            if let stop = tourViewModel.currentStop {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Stop \(tourViewModel.currentStopIndex + 1) of \(tour.stops.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let location = locationManager.currentLocation,
                               let distance = tourViewModel.distanceToCurrentStop(from: location) {
                                Text(distance)
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }
                        }

                        Text(stop.name)
                            .font(.title3.bold())

                        Text(stop.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if tourViewModel.arrivedAtStop {
                            arrivedBanner
                        }

                        if let note = stop.historicalNote {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Historical Note", systemImage: "book.fill")
                                    .font(.caption.bold())
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }

                        if let tip = stop.tips {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Tip", systemImage: "lightbulb.fill")
                                    .font(.caption.bold())
                                Text(tip)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        }

                        // Chat buttons
                        HStack(spacing: 12) {
                            Button {
                                showStopChat = true
                            } label: {
                                Label("About this stop", systemImage: "mappin.circle")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accent)

                            Button {
                                showGuideChat = true
                            } label: {
                                Label("Ask guide", systemImage: "bubble.left.and.text.bubble.right")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                        }

                        // Navigation buttons
                        HStack(spacing: 12) {
                            Button {
                                tourViewModel.goToPreviousStop()
                                if let prev = tourViewModel.currentStop {
                                    focusOnStop(prev)
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(tourViewModel.currentStopIndex == 0)

                            Button {
                                openDirections(to: stop)
                            } label: {
                                Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                tourViewModel.advanceToNextStop()
                                if let next = tourViewModel.currentStop {
                                    focusOnStop(next)
                                }
                            } label: {
                                HStack {
                                    Text(tourViewModel.stopsRemaining > 0 ? "Next" : "Finish")
                                    Image(systemName: tourViewModel.stopsRemaining > 0 ? "chevron.right" : "checkmark")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        // Show all stops on map
                        Button {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                cameraPosition = .region(regionForTour(tour))
                            }
                        } label: {
                            Label("Show Full Route", systemImage: "map")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)

                        // End tour button
                        Button(role: .destructive) {
                            showEndTourConfirmation = true
                        } label: {
                            Text("End Tour")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .confirmationDialog(
                            "End this tour?",
                            isPresented: $showEndTourConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("End Tour", role: .destructive) {
                                locationManager.stopMonitoringAllRegions()
                                tourViewModel.endTour()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Your progress will be saved to tour history.")
                        }
                    }
                    .padding()
                }
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                tourViewModel.checkProximityToCurrentStop(userLocation: location)
            }
        }
        .onChange(of: locationManager.enteredRegionId) { _, regionId in
            if let id = regionId {
                tourViewModel.handleRegionEntry(regionId: id)
            }
        }
        .sheet(isPresented: $showStopChat) {
            if let stop = tourViewModel.currentStop {
                StopChatSheet(
                    stop: stop,
                    tour: tour,
                    locationManager: locationManager
                )
            }
        }
        .sheet(isPresented: $showGuideChat) {
            GuideChatSheet(
                tour: tour,
                locationManager: locationManager
            )
        }
    }

    private var arrivedBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("You've arrived at this stop!")
                .font(.subheadline.bold())
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Map Camera Helpers

    private func regionForTour(_ tour: Tour) -> MKCoordinateRegion {
        guard !tour.stops.isEmpty else {
            return MKCoordinateRegion(
                center: tour.centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }

        var minLat = tour.stops[0].latitude
        var maxLat = tour.stops[0].latitude
        var minLon = tour.stops[0].longitude
        var maxLon = tour.stops[0].longitude

        for stop in tour.stops {
            minLat = min(minLat, stop.latitude)
            maxLat = max(maxLat, stop.latitude)
            minLon = min(minLon, stop.longitude)
            maxLon = max(maxLon, stop.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.005),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.005)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    private func focusOnStop(_ stop: TourStop) {
        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: stop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }

    private func openDirections(to stop: TourStop) {
        let placemark = MKPlacemark(coordinate: stop.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}

// MARK: - Guide Chat Sheet (general questions while on tour)

struct GuideChatSheet: View {
    let tour: Tour
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @FocusState private var isInputFocused: Bool

    private let claudeAPI = ClaudeAPIService()
    private let tourGuideService = TourGuideService()

    /// Use the tour's location name, falling back to GPS-based description
    private var tourLocationDescription: String {
        if tour.locationName != "the area" {
            return tour.locationName
        }
        return locationManager.locationDescription
    }

    private var quickQuestions: [String] {
        [
            "Where should I eat nearby?",
            "Is this area safe at night?",
            "How do I get to the city center?",
            "What's the best coffee shop around here?",
            "Any hidden gems nearby?",
            "What's the local specialty food?"
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Context header
                HStack(spacing: 10) {
                    Image(systemName: "globe.americas.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("AI Travel Guide")
                            .font(.subheadline.bold())
                        Text(tourLocationDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("On Tour", systemImage: "figure.walk")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            if isTyping {
                                TypingIndicator()
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                // Quick questions
                if messages.count <= 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickQuestions, id: \.self) { question in
                                Button {
                                    inputText = question
                                    sendMessage()
                                } label: {
                                    Text(question)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.secondarySystemBackground), in: Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                // Input
                HStack(spacing: 12) {
                    TextField("Ask anything about the area...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Travel Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            let city = tour.locationName != "the area" ? tour.locationName : (locationManager.currentCity ?? "the area")
            messages.append(ChatMessage.assistantMessage(
                "I'm your travel guide for \(city). Ask me anything — restaurant recommendations, transport tips, safety advice, local customs, or whatever's on your mind!"
            ))
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage.userMessage(text))
        inputText = ""
        isTyping = true

        Task {
            let response: String

            // Use tour's location for context, not the user's GPS
            let tourLocation = CLLocation(
                latitude: tour.centerLatitude,
                longitude: tour.centerLongitude
            )

            if APIKeyManager.shared.hasAPIKey {
                let context = tourGuideService.buildLocationContext(
                    location: tourLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
                // Enrich the question with the tour's city so Claude knows the correct location
                let enrichedQuestion = "I'm on a tour in \(tour.locationName). \(text)"
                response = await claudeAPI.ask(
                    question: enrichedQuestion,
                    conversationHistory: messages,
                    locationContext: context
                )
            } else {
                response = tourGuideService.generateFallbackResponse(
                    to: text,
                    location: tourLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
            }

            messages.append(ChatMessage.assistantMessage(response))
            isTyping = false
        }
    }
}

// MARK: - Stop Chat Sheet (questions about current stop)

struct StopChatSheet: View {
    let stop: TourStop
    let tour: Tour
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @FocusState private var isInputFocused: Bool

    private let claudeAPI = ClaudeAPIService()
    private let tourGuideService = TourGuideService()

    private var quickQuestions: [String] {
        [
            "Tell me more about \(stop.name)",
            "What's the history of this place?",
            "Any tips for visiting here?",
            "What should I see nearby?"
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stop context header
                HStack(spacing: 10) {
                    Image(systemName: stop.imageSystemName)
                        .foregroundStyle(.accent)
                    VStack(alignment: .leading) {
                        Text(stop.name)
                            .font(.subheadline.bold())
                        Text("Stop \(stop.orderIndex + 1) on \(tour.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground))

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                            }
                            if isTyping {
                                TypingIndicator()
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                // Quick questions (shown when chat is fresh)
                if messages.count <= 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickQuestions, id: \.self) { question in
                                Button {
                                    inputText = question
                                    sendMessage()
                                } label: {
                                    Text(question)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.secondarySystemBackground), in: Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                // Input
                HStack(spacing: 12) {
                    TextField("Ask about \(stop.name)...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .accent)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isTyping)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("Ask About This Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            messages.append(ChatMessage.assistantMessage(
                "You're at \(stop.name). \(stop.description) Ask me anything about this stop, its history, or what to do here!"
            ))
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage.userMessage(text))
        inputText = ""
        isTyping = true

        Task {
            let response: String

            // Use the stop's coordinate for context, not GPS
            let stopLocation = CLLocation(
                latitude: stop.latitude,
                longitude: stop.longitude
            )

            if APIKeyManager.shared.hasAPIKey {
                let context = tourGuideService.buildLocationContext(
                    location: stopLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
                // Prepend stop context so Claude knows which stop and city we're in
                let enrichedQuestion = "I'm in \(tour.locationName), currently at tour stop \"\(stop.name)\": \(stop.description). \(stop.historicalNote ?? "") My question: \(text)"
                response = await claudeAPI.ask(
                    question: enrichedQuestion,
                    conversationHistory: messages,
                    locationContext: context
                )
            } else {
                response = tourGuideService.generateFallbackResponse(
                    to: text,
                    location: stopLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
            }

            messages.append(ChatMessage.assistantMessage(response))
            isTyping = false
        }
    }
}

// MARK: - Tour Category Card

struct TourCategoryCard: View {
    let category: TourCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Tour History Row

struct TourHistoryRow: View {
    let tour: Tour

    var body: some View {
        HStack {
            Image(systemName: tour.category.systemImage)
                .foregroundStyle(.accent)
                .frame(width: 32)
            VStack(alignment: .leading) {
                Text(tour.name)
                    .font(.subheadline.bold())
                Text("\(tour.stops.count) stops - \(tour.formattedDistance)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(tour.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
