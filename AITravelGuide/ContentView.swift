import SwiftUI

struct ContentView: View {
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var tourViewModel: TourViewModel

    @State private var selectedTab: Tab = .explore

    var body: some View {
        TabView(selection: $selectedTab) {
            MapExploreView()
                .tabItem {
                    Label("Explore", systemImage: "map")
                }
                .tag(Tab.explore)

            TourView()
                .tabItem {
                    Label("Tour", systemImage: tourViewModel.isOnTour ? "figure.walk" : "point.topleft.down.to.point.bottomright.curvepath")
                }
                .tag(Tab.tour)
                .badge(tourViewModel.isOnTour ? "Live" : nil)

            NearbyHighlightsView()
                .tabItem {
                    Label("Highlights", systemImage: "star")
                }
                .tag(Tab.highlights)

            ChatView()
                .tabItem {
                    Label("AI Guide", systemImage: "bubble.left.and.text.bubble.right")
                }
                .tag(Tab.chat)
        }
        .tint(.accentColor)
        .overlay {
            if locationManager.authorizationStatus == .notDetermined {
                locationPermissionOverlay
            }
        }
    }

    private var locationPermissionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.accent)

                Text("Enable Location")
                    .font(.title2.bold())

                Text("AI Travel Guide needs your location to create personalized tours, find nearby highlights, and answer questions about your surroundings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    locationManager.requestPermission()
                } label: {
                    Text("Allow Location Access")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(30)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(30)
        }
    }
}

enum Tab: String {
    case explore
    case tour
    case highlights
    case chat
}
