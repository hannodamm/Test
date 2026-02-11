import SwiftUI

@main
struct AITravelGuideApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tourViewModel = TourViewModel()
    @StateObject private var exploreViewModel = ExploreViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(tourViewModel)
                .environmentObject(exploreViewModel)
        }
    }
}
