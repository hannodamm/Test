import SwiftUI
import MapKit

struct TourView: View {
    @EnvironmentObject var tourViewModel: TourViewModel
    @EnvironmentObject var locationManager: LocationManager

    @State private var showStopSheet = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

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
                    Text("Generate a personalized walking tour based on your current location")
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

                // Current location info
                if let placemark = locationManager.currentPlacemark {
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
                    .padding(.horizontal)
                }

                // Generate button
                Button {
                    Task {
                        if let coord = locationManager.currentLocation?.coordinate {
                            await tourViewModel.generateTour(
                                coordinate: coord,
                                placemark: locationManager.currentPlacemark
                            )
                        }
                    }
                } label: {
                    Label("Generate Tour", systemImage: "wand.and.stars")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationManager.currentLocation == nil)
                .padding(.horizontal)

                // Tour history
                if !tourViewModel.tourHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Tours")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(tourViewModel.tourHistory) { tour in
                            TourHistoryRow(tour: tour)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
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
            Text("Finding the best stops near you")
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
                Map {
                    ForEach(tour.stops) { stop in
                        Annotation(stop.name, coordinate: stop.coordinate) {
                            TourStopMarker(stop: stop, isActive: false)
                        }
                    }
                    MapPolyline(coordinates: tour.stops.map { $0.coordinate })
                        .stroke(.blue, lineWidth: 3)
                }
                .frame(height: 200)
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
            }
            .frame(height: 300)

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

                        // Navigation buttons
                        HStack(spacing: 12) {
                            Button {
                                tourViewModel.goToPreviousStop()
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
                            } label: {
                                HStack {
                                    Text(tourViewModel.stopsRemaining > 0 ? "Next" : "Finish")
                                    Image(systemName: tourViewModel.stopsRemaining > 0 ? "chevron.right" : "checkmark")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }

                        // End tour button
                        Button(role: .destructive) {
                            locationManager.stopMonitoringAllRegions()
                            tourViewModel.endTour()
                        } label: {
                            Text("End Tour")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
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

    private func openDirections(to stop: TourStop) {
        let placemark = MKPlacemark(coordinate: stop.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = stop.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
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
