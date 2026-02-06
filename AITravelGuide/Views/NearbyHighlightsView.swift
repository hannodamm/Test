import SwiftUI
import MapKit

struct NearbyHighlightsView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var searchService = MapSearchService()
    @State private var highlights: [HighlightSection] = []
    @State private var isLoading = false
    @State private var selectedPOI: PointOfInterest?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && highlights.isEmpty {
                    loadingView
                } else if highlights.isEmpty {
                    emptyView
                } else {
                    highlightsList
                }
            }
            .navigationTitle("Highlights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await loadHighlights() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(item: $selectedPOI) { poi in
                POIDetailSheet(poi: poi, locationManager: locationManager)
            }
        }
        .onAppear {
            if highlights.isEmpty {
                Task { await loadHighlights() }
            }
        }
        .onChange(of: locationManager.currentLocation) { oldValue, newValue in
            guard let newLoc = newValue, let oldLoc = oldValue else { return }
            // Reload if moved more than 500m
            if newLoc.distance(from: oldLoc) > 500 {
                Task { await loadHighlights() }
            }
        }
    }

    // MARK: - Highlights List

    private var highlightsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Location header
                locationHeader

                // Highlight sections
                ForEach(highlights) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: section.icon)
                                .foregroundStyle(section.color)
                            Text(section.title)
                                .font(.headline)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(section.pois) { poi in
                                    HighlightCard(poi: poi) {
                                        selectedPOI = poi
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // "Explore more" footer
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Explore the map for more places")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Location Header

    private var locationHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(.blue)
                Text("Near You")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let city = locationManager.currentCity {
                Text(city)
                    .font(.title.bold())
            }
            if let neighborhood = locationManager.currentNeighborhood {
                Text(neighborhood)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Loading & Empty

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Discovering highlights nearby...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Highlights Found")
                .font(.headline)
            Text("Make sure location access is enabled to discover nearby points of interest.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                locationManager.requestPermission()
            } label: {
                Text("Enable Location")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadHighlights() async {
        guard let coordinate = locationManager.currentLocation?.coordinate else { return }
        isLoading = true

        let categorySections: [(String, String, Color, [POICategory])] = [
            ("Must See", "star.fill", .orange, [.landmark, .viewpoint]),
            ("Culture & History", "building.columns.fill", .purple, [.museum, .historical]),
            ("Food & Drink", "fork.knife", .red, [.restaurant]),
            ("Parks & Nature", "leaf.fill", .green, [.park]),
            ("Entertainment", "ticket.fill", .blue, [.entertainment, .shopping])
        ]

        var newSections: [HighlightSection] = []

        for (title, icon, color, categories) in categorySections {
            var sectionPOIs: [PointOfInterest] = []
            for category in categories {
                let results = await searchService.searchNearby(
                    coordinate: coordinate,
                    category: category,
                    radius: 1500
                )
                sectionPOIs.append(contentsOf: results.prefix(4))
            }

            if !sectionPOIs.isEmpty {
                newSections.append(HighlightSection(
                    title: title,
                    icon: icon,
                    color: color,
                    pois: sectionPOIs
                ))
            }
        }

        highlights = newSections
        isLoading = false
    }
}

struct HighlightSection: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let pois: [PointOfInterest]
}
