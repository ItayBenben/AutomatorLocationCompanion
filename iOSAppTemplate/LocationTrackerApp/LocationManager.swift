import Foundation
import CoreLocation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var lastLocationError: String?

    private let manager: CLLocationManager

    override init() {
        let mgr = CLLocationManager()
        self.manager = mgr
        self.authorizationStatus = mgr.authorizationStatus
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = kCLDistanceFilterNone
        mgr.pausesLocationUpdatesAutomatically = false
        mgr.allowsBackgroundLocationUpdates = true
        mgr.showsBackgroundLocationIndicator = true
        mgr.activityType = .other
    }

    func requestAlwaysAuthorization() {
        lastLocationError = nil
        manager.requestAlwaysAuthorization()
    }

    /// Starts continuous GPS updates (higher power).
    func startUpdating() {
        lastLocationError = nil
        manager.startUpdatingLocation()
    }

    /// Stops continuous GPS updates.
    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    /// Best-effort "keep working when app is backgrounded":
    /// - Continuous updates while running
    /// - Significant-change + Visits so iOS can wake/relaunch you on movement
    enum TrackingMode: String {
        case standard
        case lowPower
    }

    func startTracking(mode: TrackingMode) {
        lastLocationError = nil
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            manager.startMonitoringSignificantLocationChanges()
        }
        manager.startMonitoringVisits()
        switch mode {
        case .standard:
            manager.startUpdatingLocation()
        case .lowPower:
            manager.stopUpdatingLocation()
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.stopMonitoringVisits()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = loc
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        // Visits are coarse but useful to wake the app in background.
        let coord = CLLocationCoordinate2D(latitude: visit.coordinate.latitude, longitude: visit.coordinate.longitude)
        let timestamp = visit.departureDate == Date.distantFuture ? visit.arrivalDate : visit.departureDate
        let loc = CLLocation(coordinate: coord, altitude: 0, horizontalAccuracy: 100, verticalAccuracy: 0, timestamp: timestamp)
        Task { @MainActor in
            self.lastLocation = loc
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastLocationError = error.localizedDescription
        }
    }
}

