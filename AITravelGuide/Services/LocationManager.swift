import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    @Published var currentHeading: CLHeading?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    @Published var isMonitoringRegions: Bool = false
    @Published var enteredRegionId: String?

    private let clLocationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var monitoredStopIds: [String: CLCircularRegion] = [:]

    private var hasTriedIPFallback = false

    override init() {
        super.init()
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        clLocationManager.distanceFilter = 10
        clLocationManager.allowsBackgroundLocationUpdates = true
        clLocationManager.pausesLocationUpdatesAutomatically = false
        clLocationManager.showsBackgroundLocationIndicator = true
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

    // MARK: - Heading

    func startUpdatingHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        clLocationManager.headingFilter = 5
        clLocationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        clLocationManager.stopUpdatingHeading()
        currentHeading = nil
    }

    /// Human-readable direction from the user's current facing to a target coordinate.
    /// Returns nil when location or heading is unavailable/unreliable (e.g. device flat).
    func directionLabel(to target: CLLocationCoordinate2D) -> String? {
        guard let origin = currentLocation?.coordinate,
              let heading = currentHeading,
              heading.headingAccuracy >= 0 else { return nil }

        let facing = heading.trueHeading >= 0 ? heading.trueHeading : heading.magneticHeading
        guard facing >= 0 else { return nil }

        let bearing = Self.bearing(from: origin, to: target)
        var relative = bearing - facing
        while relative > 180 { relative -= 360 }
        while relative < -180 { relative += 360 }

        switch abs(relative) {
        case ..<30: return "ahead"
        case 30..<120: return relative > 0 ? "on your right" : "on your left"
        default: return "behind you"
        }
    }

    private static func bearing(
        from origin: CLLocationCoordinate2D,
        to target: CLLocationCoordinate2D
    ) -> CLLocationDirection {
        let lat1 = origin.latitude * .pi / 180
        let lat2 = target.latitude * .pi / 180
        let dLon = (target.longitude - origin.longitude) * .pi / 180

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        let degrees = radians * 180 / .pi
        return (degrees + 360).truncatingRemainder(dividingBy: 360)
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

    // MARK: - IP-Based Location Fallback

    /// When GPS isn't available (e.g. in the Simulator), detect approximate
    /// location from the device's IP address.
    func tryIPBasedLocation() async {
        guard currentLocation == nil, !hasTriedIPFallback else { return }
        hasTriedIPFallback = true

        guard let url = URL(string: "http://ip-api.com/json/?fields=status,lat,lon,city,country,regionName") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(IPLocationResult.self, from: data)

            guard result.status == "success" else { return }

            let location = CLLocation(latitude: result.lat, longitude: result.lon)
            self.currentLocation = location
            _ = await self.reverseGeocode(location)
        } catch {
            // IP geolocation failed silently — user can still search locations manually
        }
    }
}

private struct IPLocationResult: Decodable {
    let status: String
    let lat: Double
    let lon: Double
    let city: String?
    let country: String?
    let regionName: String?
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
                // If GPS doesn't respond within 3 seconds (e.g. Simulator),
                // fall back to IP-based location detection
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await self.tryIPBasedLocation()
                }
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

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.currentHeading = newHeading
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
