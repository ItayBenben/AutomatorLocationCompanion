import Foundation

enum AppConfig {
    /// Replace with your server endpoint (e.g. https://example.com/api/location).
    /// You can also override at runtime via the UI in this sample app.
    static let defaultServerURLString = "http://localhost:8787/location"

    /// Default send interval in seconds.
    static let defaultSendIntervalSeconds: TimeInterval = 10

    static let minIntervalSeconds: TimeInterval = 2
    static let maxIntervalSeconds: TimeInterval = 3600
}

