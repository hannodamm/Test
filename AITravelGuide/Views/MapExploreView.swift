import SwiftUI
import MapKit

struct MapExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var tourViewModel: TourViewModel

    @State private var selectedMapItem: PointOfInterest?
    @State private var showCategoryFilter = false
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        ZStack(alignment: .top) {
            mapContent

            VStack(spacing: 0) {
                searchBar
                if showCategoryFilter {
                    categoryFilterBar
                }
            }

            if viewModel.isLoading {
                loadingOverlay
            }
        }
        .sheet(item: $selectedMapItem) { poi in
            POIDetailSheet(poi: poi, locationManager: locationManager)
        }
        .onAppear {
            if let location = locationManager.currentLocation {
                viewModel.updateRegion(for: location)
                Task {
                    await viewModel.loadNearbyPOIs(coordinate: location.coordinate)
                }
            }
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            if let location = newLocation {
                Task {
                    await viewModel.loadNearbyPOIs(coordinate: location.coordinate)
                }
            }
        }
    }

    // MARK: - Map

    private var mapContent: some View {
        Map(position: $cameraPosition, selection: $selectedMapItem) {
            UserAnnotation()

            ForEach(viewModel.filteredPOIs) { poi in
                Annotation(poi.name, coordinate: poi.coordinate) {
                    POIMarker(poi: poi)
                        .onTapGesture {
                            selectedMapItem = poi
                        }
                }
                .tag(poi)
            }

            if let tour = tourViewModel.currentTour {
                ForEach(tour.stops) { stop in
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        TourStopMarker(stop: stop, isActive: stop.id == tourViewModel.currentStop?.id)
                    }
                }

                MapPolyline(coordinates: tour.stops.map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search places nearby...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit {
                        if let coord = locationManager.currentLocation?.coordinate {
                            Task { await viewModel.search(near: coord) }
                        }
                    }
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                withAnimation { showCategoryFilter.toggle() }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle\(showCategoryFilter ? ".fill" : "")")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Category Filter

    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(POICategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: viewModel.selectedCategories.contains(category)
                    ) {
                        viewModel.toggleCategory(category)
                        if let coord = locationManager.currentLocation?.coordinate {
                            Task { await viewModel.refreshPOIs(coordinate: coord) }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Loading

    private var loadingOverlay: some View {
        VStack {
            Spacer()
            HStack {
                ProgressView()
                Text("Finding places...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Supporting Views

struct POIMarker: View {
    let poi: PointOfInterest

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: poi.category.systemImage)
                .font(.caption)
                .foregroundStyle(.white)
                .padding(6)
                .background(colorForCategory(poi.category), in: Circle())
                .shadow(radius: 2)
        }
    }

    private func colorForCategory(_ category: POICategory) -> Color {
        switch category {
        case .landmark: return .orange
        case .restaurant: return .red
        case .museum: return .purple
        case .park: return .green
        case .shopping: return .pink
        case .entertainment: return .yellow
        case .transit: return .blue
        case .hotel: return .indigo
        case .historical: return .brown
        case .viewpoint: return .teal
        }
    }
}

struct TourStopMarker: View {
    let stop: TourStop
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.blue : Color.blue.opacity(0.7))
                .frame(width: 32, height: 32)
            Text("\(stop.orderIndex + 1)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .shadow(radius: isActive ? 4 : 2)
        .scaleEffect(isActive ? 1.2 : 1.0)
        .animation(.spring, value: isActive)
    }
}

struct CategoryChip: View {
    let category: POICategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: category.systemImage)
                    .font(.caption2)
                Text(category.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - POI Detail Sheet

struct POIDetailSheet: View {
    let poi: PointOfInterest
    let locationManager: LocationManager

    @Environment(\.dismiss) private var dismiss
    @State private var highlights: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: poi.category.systemImage)
                            .font(.title2)
                            .foregroundStyle(.accent)
                        VStack(alignment: .leading) {
                            Text(poi.name)
                                .font(.title2.bold())
                            Text(poi.category.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let distance = poi.formattedDistance {
                            Text(distance)
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }
                    }

                    Divider()

                    // Address
                    if let address = poi.address, !address.isEmpty {
                        Label(address, systemImage: "mappin")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Description
                    if let desc = poi.description {
                        Text(desc)
                            .font(.body)
                    }

                    // Highlights
                    if !highlights.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Highlights")
                                .font(.headline)
                            ForEach(highlights, id: \.self) { highlight in
                                Label(highlight, systemImage: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            openInMaps()
                        } label: {
                            Label("Open in Apple Maps", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        if let phone = poi.phoneNumber {
                            Button {
                                if let url = URL(string: "tel://\(phone)") {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                Label(phone, systemImage: "phone.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }

                        if let url = poi.url {
                            Link(destination: url) {
                                Label("Visit Website", systemImage: "globe")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            let service = TourGuideService()
            highlights = service.generateHighlights(
                for: poi,
                placemark: locationManager.currentPlacemark
            )
        }
        .presentationDetents([.medium, .large])
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: poi.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = poi.name
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
