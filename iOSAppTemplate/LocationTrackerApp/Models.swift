import Foundation
import CoreLocation

struct LocationPayload: Codable {
    let latitude: Double
    let longitude: Double
    let horizontalAccuracy: Double?
    let altitude: Double?
    let speed: Double?
    let course: Double?
    let timestampISO8601: String
    let deviceId: String
}

extension CLLocation {
    func toPayload(deviceId: String) -> LocationPayload {
        LocationPayload(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            horizontalAccuracy: horizontalAccuracy >= 0 ? horizontalAccuracy : nil,
            altitude: verticalAccuracy >= 0 ? altitude : nil,
            speed: speed >= 0 ? speed : nil,
            course: course >= 0 ? course : nil,
            timestampISO8601: ISO8601DateFormatter().string(from: timestamp),
            deviceId: deviceId
        )
    }
}

