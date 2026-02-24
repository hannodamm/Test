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
            if let tour = tourViewModel.currentTour ?? tourViewModel.tourHistory.last {
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
            }
        }
        .onChange(of: locationManager.enteredRegionId) { _, regionId in
            if let id = regionId {
                tourViewModel.handleRegionEntry(regionId: id)
            }
        }
        .onChange(of: tourViewModel.nearbyDiscoveryPoint) { _, point in
            if let point {
                withAnimation(.none) { showDiscoveryBanner = true }
                speechService.speak(point.description)
                Task {
                    try? await Task.sleep(for: .seconds(15))
                    await MainActor.run { withAnimation(.none) { showDiscoveryBanner = false } }
                }
            }
        }
        .onChange(of: tourViewModel.progressCommentary) { _, commentary in
            if let commentary {
                withAnimation(.none) { showProgressBanner = true }
                speechService.speak(commentary)
                Task {
                    try? await Task.sleep(for: .seconds(10))
                    await MainActor.run { withAnimation(.none) { showProgressBanner = false } }
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
                .foregroundStyle(.orange)
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
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }

    private func progressBanner(commentary: String) -> some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundStyle(.yellow)
            Text(commentary)
                .font(.subheadline.bold())
            Spacer()
            Button { showProgressBanner = false } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
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

// MARK: - Tour Rating Sheet

struct TourRatingSheet: View {
    let tour: Tour
    let tourViewModel: TourViewModel
    let storageService: TourStorageService

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)

                Text("How was your tour?")
                    .font(.title2.bold())

                Text(tour.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Star rating
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            withAnimation(.spring(duration: 0.2)) {
                                rating = star
                            }
                        } label: {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(star <= rating ? .orange : .secondary)
                        }
                    }
                }
                .padding(.vertical)

                if rating > 0 {
                    Text(ratingLabel)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    if rating > 0 {
                        var ratedTour = tour
                        ratedTour.rating = rating
                        storageService.saveTour(ratedTour)
                    }
                    dismiss()
                } label: {
                    Text(rating > 0 ? "Submit Rating" : "Skip")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(rating > 0 ? .orange : .secondary)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Rate Tour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Not great"
        case 2: return "Could be better"
        case 3: return "It was okay"
        case 4: return "Really enjoyed it!"
        case 5: return "Amazing tour!"
        default: return ""
        }
    }
}

// MARK: - Guide Chat Sheet

struct GuideChatSheet: View {
    let tour: Tour
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechService: SpeechService
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @FocusState private var isInputFocused: Bool

    private let claudeAPI = ClaudeAPIService()
    private let tourGuideService = TourGuideService()

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
                HStack(spacing: 10) {
                    Image(systemName: tour.guidePersona != nil ? "person.circle.fill" : "globe.americas.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(tour.guidePersona.map { "\($0.name)" } ?? "AI Travel Guide")
                            .font(.subheadline.bold())
                        Text(tour.guidePersona?.tagline ?? tourLocationDescription)
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
                    Button("Done") {
                        speechService.stop()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if let persona = tour.guidePersona {
                messages.append(ChatMessage.assistantMessage(persona.greeting))
            } else {
                let city = tour.locationName != "the area" ? tour.locationName : (locationManager.currentCity ?? "the area")
                messages.append(ChatMessage.assistantMessage(
                    "I'm your travel guide for \(city). Ask me anything — restaurant recommendations, transport tips, safety advice, local customs, or whatever's on your mind!"
                ))
            }
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
            let tourLocation = CLLocation(latitude: tour.centerLatitude, longitude: tour.centerLongitude)

            if APIKeyManager.shared.hasAPIKey {
                let context = tourGuideService.buildLocationContext(
                    location: tourLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
                let enrichedQuestion = "I'm on a tour in \(tour.locationName). \(text)"
                response = await claudeAPI.ask(
                    question: enrichedQuestion,
                    conversationHistory: messages,
                    locationContext: context,
                    guidePersona: tour.guidePersona
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

// MARK: - Stop Chat Sheet

struct StopChatSheet: View {
    let stop: TourStop
    let tour: Tour
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var speechService: SpeechService
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
                    Button("Done") {
                        speechService.stop()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            if tour.guidePersona != nil {
                messages.append(ChatMessage.assistantMessage(
                    "So, you're at \(stop.name). \(stop.description) What would you like to know?"
                ))
            } else {
                messages.append(ChatMessage.assistantMessage(
                    "You're at \(stop.name). \(stop.description) Ask me anything about this stop, its history, or what to do here!"
                ))
            }
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
            let stopLocation = CLLocation(latitude: stop.latitude, longitude: stop.longitude)

            if APIKeyManager.shared.hasAPIKey {
                let context = tourGuideService.buildLocationContext(
                    location: stopLocation,
                    placemark: nil,
                    nearbyPOIs: [],
                    currentTour: tour
                )
                let enrichedQuestion = "I'm in \(tour.locationName), currently at tour stop \"\(stop.name)\": \(stop.description). \(stop.historicalNote ?? "") My question: \(text)"
                response = await claudeAPI.ask(
                    question: enrichedQuestion,
                    conversationHistory: messages,
                    locationContext: context,
                    guidePersona: tour.guidePersona
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
    var isCurated: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .font(.title2)
                Text(category.rawValue)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                if isCurated {
                    Text("Curated")
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.orange.opacity(0.2))
                        .foregroundStyle(isSelected ? .white : .orange)
                        .clipShape(Capsule())
                }
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
                HStack(spacing: 4) {
                    Text("\(tour.stops.count) stops")
                    Text("-")
                    Text(tour.formattedDistance)
                    if let rating = tour.rating {
                        Text("-")
                        HStack(spacing: 1) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
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

// MARK: - Walking Directions Sheet

struct WalkingDirectionsSheet: View {
    let fromStop: TourStop
    let toStop: TourStop
    let steps: [WalkingDirectionStep]
    let routeCoordinates: [CLLocationCoordinate2D]
    let eta: String?
    let distance: CLLocationDistance?

    @EnvironmentObject var speechService: SpeechService
    @Environment(\.dismiss) private var dismiss

    private var isLastStop: Bool { fromStop.id == toStop.id }

    private var formattedDistance: String? {
        guard let d = distance, d > 0 else { return nil }
        if d < 1000 { return String(format: "%.0f m", d) }
        return String(format: "%.1f km", d / 1000)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Route header
                    routeHeader

                    // Route map
                    if !routeCoordinates.isEmpty {
                        routeMap
                    }

                    // Turn-by-turn steps
                    if !steps.isEmpty {
                        stepsList
                    } else if isLastStop {
                        lastStopMessage
                    } else {
                        noDirectionsMessage
                    }
                }
                .padding()
            }
            .navigationTitle("Walking Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                if !steps.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            let stepTexts = steps.map { $0.instructions }
                            speechService.speakDirectionSummary(
                                to: toStop,
                                steps: stepTexts,
                                distance: formattedDistance
                            )
                        } label: {
                            Image(systemName: speechService.isSpeaking ? "stop.circle.fill" : "speaker.wave.2")
                                .foregroundStyle(speechService.isSpeaking ? .red : .accent)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Route Header

    private var routeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLastStop {
                Text("You're at the last stop")
                    .font(.headline)
            } else {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("From")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(fromStop.name)
                            .font(.subheadline.bold())
                    }
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("To")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(toStop.name)
                            .font(.subheadline.bold())
                    }
                }
            }

            if !isLastStop {
                HStack(spacing: 16) {
                    if let eta {
                        Label(eta, systemImage: "clock")
                    }
                    if let formattedDistance {
                        Label(formattedDistance, systemImage: "figure.walk")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Route Map

    private var routeMap: some View {
        Map(initialPosition: .region(routeRegion)) {
            Annotation(fromStop.name, coordinate: fromStop.coordinate) {
                ZStack {
                    Circle().fill(.blue).frame(width: 28, height: 28)
                    Text("\(fromStop.orderIndex + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
            if !isLastStop {
                Annotation(toStop.name, coordinate: toStop.coordinate) {
                    ZStack {
                        Circle().fill(.green).frame(width: 28, height: 28)
                        Text("\(toStop.orderIndex + 1)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            MapPolyline(coordinates: routeCoordinates)
                .stroke(.blue, lineWidth: 4)
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var routeRegion: MKCoordinateRegion {
        guard !routeCoordinates.isEmpty else {
            return MKCoordinateRegion(
                center: fromStop.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        }
        var minLat = routeCoordinates[0].latitude
        var maxLat = routeCoordinates[0].latitude
        var minLon = routeCoordinates[0].longitude
        var maxLon = routeCoordinates[0].longitude

        for c in routeCoordinates {
            minLat = min(minLat, c.latitude)
            maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude)
            maxLon = max(maxLon, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.6, 0.004),
                longitudeDelta: max((maxLon - minLon) * 1.6, 0.004)
            )
        )
    }

    // MARK: - Steps List

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Turn-by-turn")
                .font(.headline)
                .padding(.bottom, 8)

            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    // Step number with line
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(index == 0 ? Color.blue : Color(.systemGray4))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundStyle(index == 0 ? .white : .primary)
                        }
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(Color(.systemGray4))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.instructions)
                            .font(.subheadline)
                        if step.distance > 0 {
                            Text(step.formattedDistance)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    Spacer()
                }
            }

            // Arrival indicator
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 28, height: 28)
                    Image(systemName: "flag.fill")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
                .frame(width: 28)

                Text("Arrive at \(toStop.name)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
                    .padding(.vertical, 8)
            }
        }
    }

    private var lastStopMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.title)
                .foregroundStyle(.green)
            Text("This is the final stop on your tour!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var noDirectionsMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Detailed directions aren't available for this segment. Head toward \(toStop.name) using the map above.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
