import SwiftUI
import MapKit

struct TourView: View {
    @EnvironmentObject var tourViewModel: TourViewModel
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var exploreViewModel: ExploreViewModel
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var tourStorageService: TourStorageService

    @State private var showStopSheet = false
    @State private var showStopChat = false
    @State private var showGuideChat = false
    @State private var showDirections = false
    @State private var showEndTourConfirmation = false
    @State private var showRating = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showDiscoveryBanner = false
    @State private var showProgressBanner = false
    @State private var locationCheckTask: Task<Void, Never>?
    @State private var cachedDiscoveryPoints: [DiscoveryPoint] = []

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
        .sheet(isPresented: $showRating) {
            if let tour = tourViewModel.currentTour ?? tourStorageService.tourHistory.first {
                TourRatingSheet(tour: tour, tourViewModel: tourViewModel, storageService: tourStorageService)
            }
        }
    }

    // MARK: - Tour Generation Helper

    private var hasCoordinates: Bool {
        exploreViewModel.searchedCoordinate != nil || locationManager.currentLocation != nil
    }

    private func triggerTourGeneration() {
        Task {
            if let customCoord = exploreViewModel.searchedCoordinate {
                await tourViewModel.generateTour(coordinate: customCoord, placemark: nil)
            } else if let coord = locationManager.currentLocation?.coordinate {
                await tourViewModel.generateTour(coordinate: coord, placemark: locationManager.currentPlacemark)
            }
        }
    }

    // MARK: - Tour Setup

    private var cityName: String? {
        exploreViewModel.searchedLocationName ?? locationManager.currentCity
    }

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
                categorySelectionView

                // Location info
                tourLocationInfo
                    .padding(.horizontal)

                // Error banner
                if let error = tourViewModel.tourGenerationError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                        Spacer()
                        Button("Try Again") {
                            triggerTourGeneration()
                        }
                        .font(.subheadline.bold())
                    }
                    .padding()
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Generate button
                Button {
                    triggerTourGeneration()
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

                // Location unavailable hint
                if locationManager.currentLocation == nil && exploreViewModel.searchedCoordinate == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "location.slash.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Location unavailable")
                            .font(.subheadline.bold())
                        Text("Enable Location Services or search for a city in the Explore tab to generate a tour.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Open Settings", systemImage: "gear")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Tour history
                if !tourStorageService.tourHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Tours")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tourStorageService.tourHistory) { tour in
                            Button {
                                tourViewModel.currentTour = tour
                                tourViewModel.currentStopIndex = 0
                                Task { await tourViewModel.calculateWalkingRoutes() }
                            } label: {
                                TourHistoryRow(tour: tour)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }

                // Saved tours
                if !tourStorageService.savedTours.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Saved Tours")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tourStorageService.savedTours) { tour in
                            Button {
                                tourViewModel.currentTour = tour
                                tourViewModel.currentStopIndex = 0
                                Task { await tourViewModel.calculateWalkingRoutes() }
                            } label: {
                                TourHistoryRow(tour: tour)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }

                // Empty state when no tours exist
                if tourStorageService.tourHistory.isEmpty && tourStorageService.savedTours.isEmpty {
                    VStack(spacing: 8) {
                        Text("No tours yet")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text("Generate your first tour above!")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Category Selection

    private var categorySelectionView: some View {
        let coordinate = exploreViewModel.searchedCoordinate ?? locationManager.currentLocation?.coordinate
        let categories = TourCategory.categories(for: coordinate)

        return VStack(alignment: .leading, spacing: 16) {
            if !categories.curated.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Curated Tours")
                        .font(.headline)
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(categories.curated, id: \.self) { category in
                            TourCategoryCard(
                                category: category,
                                isSelected: tourViewModel.selectedCategory == category,
                                isCurated: true
                            ) {
                                tourViewModel.selectedCategory = category
                                if hasCoordinates {
                                    triggerTourGeneration()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(categories.curated.isEmpty ? "Tour Type" : "AI-Generated Tours")
                    .font(.headline)
                    .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(categories.generic, id: \.self) { category in
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
                    HStack {
                        Text(tour.name)
                            .font(.title2.bold())
                        Spacer()
                        // Voice narration button
                        HStack(spacing: 8) {
                            Button {
                                speechService.toggle("\(tour.name). \(tour.description)")
                            } label: {
                                Image(systemName: speechService.isSpeaking ? "pause.circle.fill" : speechService.isPaused ? "play.circle.fill" : "speaker.wave.2.fill")
                                    .font(.title3)
                                    .foregroundStyle(speechService.isPaused ? .orange : .accent)
                            }
                            if speechService.isSpeaking || speechService.isPaused {
                                Button {
                                    speechService.stop()
                                } label: {
                                    Image(systemName: "stop.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
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

                // Mini map with walking routes
                Map(initialPosition: .region(regionForTour(tour))) {
                    ForEach(tour.stops) { stop in
                        Annotation(stop.name, coordinate: stop.coordinate) {
                            TourStopMarker(stop: stop, isActive: false)
                        }
                    }
                    // Show walking routes if available, otherwise straight line
                    if !tourViewModel.walkingRouteSegments.isEmpty {
                        ForEach(Array(tourViewModel.walkingRouteSegments.enumerated()), id: \.offset) { _, segment in
                            MapPolyline(coordinates: segment)
                                .stroke(.blue, lineWidth: 3)
                        }
                    } else {
                        MapPolyline(coordinates: tour.stops.map { $0.coordinate })
                            .stroke(.blue, lineWidth: 3)
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                if tourViewModel.isCalculatingRoutes {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Calculating walking routes...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Stops list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tour Stops")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(tour.stops.enumerated()), id: \.element.id) { index, stop in
                        VStack(spacing: 0) {
                            TourStopCard(stop: stop, index: index, isActive: false, isCompleted: false)

                            // Walking ETA between stops
                            if index < tourViewModel.walkingETAs.count {
                                let eta = tourViewModel.walkingETAs[index]
                                if eta > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "figure.walk")
                                            .font(.caption2)
                                        Text("\(Int(eta / 60)) min walk")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 44)
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .task {
            // Preload first stop narration while user reviews the preview
            if let firstStop = tour.stops.first {
                await speechService.preloadStopNarration(firstStop, tour: tour)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        tourViewModel.currentTour = nil
                        speechService.stop()
                        speechService.clearNarrationCache()
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
                        // Auto-narrate first stop
                        if let firstStop = tourViewModel.currentStop {
                            Task { await speechService.speakStopNarration(firstStop, tour: tourViewModel.currentTour) }
                        }
                    } label: {
                        Label("Start Tour", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                // Regenerate and Save
                HStack(spacing: 12) {
                    Button {
                        speechService.stop()
                        Task { await tourViewModel.regenerateTour() }
                    } label: {
                        Label("Try Different Tour", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)

                    Button {
                        tourStorageService.saveTour(tour)
                    } label: {
                        Label(
                            tourStorageService.savedTours.contains(where: { $0.id == tour.id }) ? "Saved" : "Save Tour",
                            systemImage: tourStorageService.savedTours.contains(where: { $0.id == tour.id }) ? "checkmark" : "square.and.arrow.down"
                        )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .disabled(tourStorageService.savedTours.contains(where: { $0.id == tour.id }))
                }
            }
            .padding()
            .background(.bar)
        }
    }

    // MARK: - Active Tour

    private func activeTourView(tour: Tour) -> some View {
        VStack(spacing: 0) {
            // Map section with walking routes
            Map(position: $cameraPosition, content: { activeTourMapContent(tour: tour) })
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            .frame(height: 300)
            .onAppear {
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
                activeStopDetailView(stop: stop, tour: tour)
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            guard let location = newLocation else { return }
            locationCheckTask?.cancel()
            locationCheckTask = Task {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                tourViewModel.checkProximityToCurrentStop(userLocation: location)
                tourViewModel.checkProximityToDiscoveryPoints(userLocation: location)
                tourViewModel.checkDepartureFromStop(userLocation: location)
                tourViewModel.checkApproachToNextStop(userLocation: location)
            }
        }
        .onChange(of: locationManager.enteredRegionId) { _, regionId in
            if let id = regionId {
                tourViewModel.handleRegionEntry(regionId: id)
            }
        }
        .onChange(of: tourViewModel.nearbyDiscoveryPoint) { _, point in
            if let point {
                withAnimation(AppAnimation.bannerIn) { showDiscoveryBanner = true }
                speechService.speak(point.description)
                Task {
                    try? await Task.sleep(for: .seconds(15))
                    await MainActor.run { withAnimation(AppAnimation.bannerOut) { showDiscoveryBanner = false } }
                }
            }
        }
        .onChange(of: tourViewModel.progressCommentary) { _, commentary in
            if let commentary {
                withAnimation(AppAnimation.bannerIn) { showProgressBanner = true }
                speechService.speak(commentary)
                Task {
                    try? await Task.sleep(for: .seconds(10))
                    await MainActor.run { withAnimation(AppAnimation.bannerOut) { showProgressBanner = false } }
                }
            }
        }
        .onChange(of: tourViewModel.arrivedAtStop) { _, arrived in
            if arrived, let stop = tourViewModel.currentStop {
                speechService.speakArrival(at: stop, persona: tour.guidePersona)
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    await speechService.speakStopNarration(stop, tour: tourViewModel.currentTour)
                }
            }
        }
        .onChange(of: tourViewModel.hasDepartedCurrentStop) { _, departed in
            if departed, let currentStop = tourViewModel.currentStop,
               let narration = currentStop.walkingNarration {
                speechService.speakWalkingNarration(narration, persona: tour.guidePersona)
            }
        }
        .onChange(of: tourViewModel.approachingNextStop) { _, approaching in
            if approaching, let nextStop = tourViewModel.nextStop {
                speechService.speakApproachTeaser(for: nextStop, persona: tour.guidePersona)
            }
        }
        .onAppear { cachedDiscoveryPoints = discoveryPointsForMap }
        .onChange(of: tourViewModel.currentStopIndex) { _, _ in
            cachedDiscoveryPoints = discoveryPointsForMap
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
        .sheet(isPresented: $showDirections) {
            if let nextStop = tourViewModel.nextStop,
               let currentStop = tourViewModel.currentStop {
                WalkingDirectionsSheet(
                    fromStop: currentStop,
                    toStop: nextStop,
                    steps: tourViewModel.currentSegmentSteps,
                    routeCoordinates: tourViewModel.currentSegmentRoute,
                    eta: tourViewModel.walkingETAToNextStop,
                    distance: tourViewModel.currentSegmentDistance
                )
            } else if let currentStop = tourViewModel.currentStop {
                // Last stop — no next stop, just show current stop location
                WalkingDirectionsSheet(
                    fromStop: currentStop,
                    toStop: currentStop,
                    steps: [],
                    routeCoordinates: [],
                    eta: nil,
                    distance: nil
                )
            }
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

    // MARK: - Active Stop Detail

    @ViewBuilder
    private func activeStopDetailView(stop: TourStop, tour: Tour) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Stop \(tourViewModel.currentStopIndex + 1) of \(tour.stops.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let eta = tourViewModel.walkingETAToNextStop {
                        Label(eta, systemImage: "figure.walk")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                    if let location = locationManager.currentLocation,
                       let distance = tourViewModel.distanceToCurrentStop(from: location) {
                        Text(distance)
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                }

                HStack {
                    Text(stop.name)
                        .font(.title3.bold())
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            if speechService.isPaused {
                                speechService.resume()
                            } else if speechService.isSpeaking {
                                speechService.pause()
                            } else {
                                Task { await speechService.speakStopNarration(stop, tour: tourViewModel.currentTour) }
                            }
                        } label: {
                            Image(systemName: speechService.isSpeaking ? "pause.circle.fill" : speechService.isPaused ? "play.circle.fill" : "speaker.wave.2.fill")
                                .font(.title3)
                                .foregroundStyle(speechService.isPaused ? .orange : .accent)
                        }
                        if speechService.isSpeaking || speechService.isPaused {
                            Button {
                                speechService.stop()
                            } label: {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Text(stop.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if tourViewModel.arrivedAtStop {
                    arrivedBanner
                }

                // Discovery point banner
                if showDiscoveryBanner, let point = tourViewModel.nearbyDiscoveryPoint {
                    discoveryBanner(point: point)
                }

                // Progress commentary banner
                if showProgressBanner, let commentary = tourViewModel.progressCommentary {
                    progressBanner(commentary: commentary)
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
                    .background(AppColors.historicalBackground, in: RoundedRectangle(cornerRadius: 8))
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
                    .background(AppColors.tipBackground, in: RoundedRectangle(cornerRadius: 8))
                }

                activeStopSecondaryButtons(stop: stop, tour: tour)
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            activeStopNavBar(stop: stop, tour: tour)
        }
    }

    @ViewBuilder
    private func activeStopNavBar(stop: TourStop, tour: Tour) -> some View {
        HStack(spacing: 12) {
            Button {
                tourViewModel.goToPreviousStop()
                if let prev = tourViewModel.currentStop {
                    focusOnStop(prev)
                    Task { await speechService.speakStopNarration(prev, tour: tourViewModel.currentTour) }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(tourViewModel.currentStopIndex == 0)

            Button {
                showDirections = true
            } label: {
                Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                let previousStop = tourViewModel.currentStop
                tourViewModel.advanceToNextStop()
                tourViewModel.checkProgressCommentary()
                if let next = tourViewModel.currentStop {
                    focusOnStop(next)
                    if let narration = previousStop?.walkingNarration {
                        speechService.speakWalkingNarration(narration, persona: tour.guidePersona)
                    } else {
                        Task { await speechService.speakStopNarration(next, tour: tourViewModel.currentTour) }
                    }
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
        .padding()
        .background(.bar)
    }

    @ViewBuilder
    private func activeStopSecondaryButtons(stop: TourStop, tour: Tour) -> some View {
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
                Label(
                    tour.guidePersona.map { "Ask \($0.name)" } ?? "Ask guide",
                    systemImage: "bubble.left.and.text.bubble.right"
                )
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .tint(.blue)
        }

        // Show full route
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

        // End tour
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
            Button("End Tour & Rate", role: .destructive) {
                speechService.stop()
                speechService.clearNarrationCache()
                locationManager.stopMonitoringAllRegions()
                tourStorageService.saveTour(tour)
                showRating = true
                tourViewModel.endTour()
            }
            Button("End Tour", role: .destructive) {
                speechService.stop()
                speechService.clearNarrationCache()
                locationManager.stopMonitoringAllRegions()
                tourStorageService.saveTour(tour)
                tourViewModel.endTour()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your tour will be saved automatically.")
        }
    }

    private func discoveryBanner(point: DiscoveryPoint) -> some View {
        HStack {
            Image(systemName: point.iconSystemName)
                .foregroundStyle(AppColors.discoveryIcon)
            VStack(alignment: .leading, spacing: 2) {
                Text(point.name)
                    .font(.subheadline.bold())
                Text(point.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { showDiscoveryBanner = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppColors.discoveryBackground, in: RoundedRectangle(cornerRadius: 8))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func progressBanner(commentary: String) -> some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundStyle(AppColors.progressIcon)
            Text(commentary)
                .font(.subheadline.bold())
            Spacer()
            Button { showProgressBanner = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppColors.progressBackground, in: RoundedRectangle(cornerRadius: 8))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Active Tour Map Content

    @MapContentBuilder
    private func activeTourMapContent(tour: Tour) -> some MapContent {
        UserAnnotation()

        ForEach(tour.stops) { stop in
            let isActive = stop.id == tourViewModel.currentStop?.id
            let isCompleted = stop.orderIndex < tourViewModel.currentStopIndex
            Annotation(stop.name, coordinate: stop.coordinate) {
                TourStopMarker(stop: stop, isActive: isActive)
                    .opacity(isCompleted ? 0.5 : 1.0)
            }
        }

        ForEach(cachedDiscoveryPoints, id: \.id) { point in
            Annotation(point.name, coordinate: point.coordinate) {
                ZStack {
                    Circle().fill(.orange).frame(width: 22, height: 22)
                    Image(systemName: point.iconSystemName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }

        if !tourViewModel.walkingRouteSegments.isEmpty {
            ForEach(Array(tourViewModel.walkingRouteSegments.enumerated()), id: \.offset) { index, segment in
                let isWalked = index < tourViewModel.currentStopIndex
                MapPolyline(coordinates: segment)
                    .stroke(isWalked ? .gray : .blue, lineWidth: 3)
            }
        } else {
            MapPolyline(coordinates: tour.stops.map { $0.coordinate })
                .stroke(.blue, lineWidth: 3)
        }
    }

    // MARK: - Discovery Points Helper

    private var discoveryPointsForMap: [DiscoveryPoint] {
        var points: [DiscoveryPoint] = []
        if let current = tourViewModel.currentStop {
            points.append(contentsOf: current.discoveryPoints ?? [])
        }
        if let next = tourViewModel.nextStop {
            points.append(contentsOf: next.discoveryPoints ?? [])
        }
        return points
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

}
