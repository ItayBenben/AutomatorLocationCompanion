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
    }

    func requestAlwaysAuthorization() {
        lastLocationError = nil
        manager.requestAlwaysAuthorization()
    }

    func startUpdating() {
        lastLocationError = nil
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
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

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastLocationError = error.localizedDescription
        }
    }
}

