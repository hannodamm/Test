import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isMonitoringRegions: Bool = false
    @Published var enteredRegionId: String?

    private let clLocationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var monitoredStopIds: [String: CLCircularRegion] = [:]

    override init() {
        super.init()
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        clLocationManager.distanceFilter = 10
        clLocationManager.allowsBackgroundLocationUpdates = false
        clLocationManager.activityType = .fitness
    }

    func requestPermission() {
        clLocationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        clLocationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        clLocationManager.stopUpdatingLocation()
    }

    func startMonitoringTourStops(_ stops: [TourStop], radius: CLLocationDistance = 50) {
        stopMonitoringAllRegions()

        for stop in stops {
            let region = CLCircularRegion(
                center: stop.coordinate,
                radius: radius,
                identifier: stop.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            clLocationManager.startMonitoring(for: region)
            monitoredStopIds[stop.id.uuidString] = region
        }
        isMonitoringRegions = true
    }

    func stopMonitoringAllRegions() {
        for (_, region) in monitoredStopIds {
            clLocationManager.stopMonitoring(for: region)
        }
        monitoredStopIds.removeAll()
        isMonitoringRegions = false
        enteredRegionId = nil
    }

    func reverseGeocode(_ location: CLLocation) async -> CLPlacemark? {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placemark = placemarks.first
            self.currentPlacemark = placemark
            return placemark
        } catch {
            return nil
        }
    }

    var currentCity: String? {
        currentPlacemark?.locality
    }

    var currentCountry: String? {
        currentPlacemark?.country
    }

    var currentNeighborhood: String? {
        currentPlacemark?.subLocality
    }

    var locationDescription: String {
        let parts = [currentNeighborhood, currentCity, currentCountry].compactMap { $0 }
        return parts.isEmpty ? "Unknown Location" : parts.joined(separator: ", ")
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            if self.currentPlacemark == nil {
                _ = await self.reverseGeocode(location)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.locationError = LocationError.permissionDenied
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationError = error
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            self.enteredRegionId = region.identifier
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access was denied. Please enable it in Settings."
        case .locationUnavailable:
            return "Unable to determine your location."
        }
    }
}
