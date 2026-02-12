import SwiftUI

@main
struct AITravelGuideApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tourViewModel = TourViewModel()
    @StateObject private var exploreViewModel = ExploreViewModel()
    @StateObject private var speechService = SpeechService()
    @StateObject private var tourStorageService = TourStorageService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(tourViewModel)
                .environmentObject(exploreViewModel)
                .environmentObject(speechService)
                .environmentObject(tourStorageService)
        }
    }
}
