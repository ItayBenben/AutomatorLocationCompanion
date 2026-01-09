import Foundation
import Combine
import UIKit

@MainActor
final class TrackingViewModel: ObservableObject {
    @Published var serverURLString: String = UserDefaults.standard.string(forKey: "serverURLString") ?? AppConfig.defaultServerURLString {
        didSet { UserDefaults.standard.set(serverURLString, forKey: "serverURLString") }
    }
    @Published var sendIntervalSeconds: TimeInterval = {
        let val = UserDefaults.standard.double(forKey: "sendIntervalSeconds")
        return val > 0 ? val : AppConfig.defaultSendIntervalSeconds
    }() {
        didSet { UserDefaults.standard.set(sendIntervalSeconds, forKey: "sendIntervalSeconds") }
    }
    @Published var isTrackingEnabled: Bool = UserDefaults.standard.bool(forKey: "isTrackingEnabled") {
        didSet { UserDefaults.standard.set(isTrackingEnabled, forKey: "isTrackingEnabled") }
    }

    @Published private(set) var lastSendStatusText: String?
    @Published private(set) var lastSendErrorText: String?

    private weak var auth: GoogleAuthViewModel?
    private weak var locationManager: LocationManager?
    private let sender = LocationSender()

    private var cancellables = Set<AnyCancellable>()
    private var lastSentAt: Date?
    private var isSending = false

    var trackingHintText: String {
        if !isTrackingEnabled { return "Enable tracking to send updates on location changes (throttled to the interval)." }
        return "Tracking ON. The app will send when it receives location updates (including in background, if iOS allows)."
    }

    func bind(auth: GoogleAuthViewModel, locationManager: LocationManager) {
        self.auth = auth
        self.locationManager = locationManager

        locationManager.$lastLocation
            .compactMap { $0 }
            .sink { [weak self] _ in
                Task { await self?.maybeSendDueToLocationUpdate() }
            }
            .store(in: &cancellables)

        if isTrackingEnabled {
            start()
        }
    }

    func start() {
        guard let locationManager else { return }
        lastSendErrorText = nil
        locationManager.requestAlwaysAuthorization()
        locationManager.startTracking()
    }

    func stop() {
        locationManager?.stopTracking()
    }

    func sendNow() async {
        await send(force: true)
    }

    private func maybeSendDueToLocationUpdate() async {
        await send(force: false)
    }

    private func shouldSend(now: Date, force: Bool) -> Bool {
        if force { return true }
        guard isTrackingEnabled else { return false }
        guard !isSending else { return false }
        guard let lastSentAt else { return true }
        return now.timeIntervalSince(lastSentAt) >= sendIntervalSeconds
    }

    private func send(force: Bool) async {
        let now = Date()
        guard shouldSend(now: now, force: force) else { return }
        guard let auth, let locationManager else { return }

        isSending = true
        defer { isSending = false }

        // Ensure we have a fresh-ish token.
        await auth.refreshTokensIfNeeded()

        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "SendLocation") {
            // If time expires, iOS will end the task. We'll just best-effort.
        }
        defer {
            if bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
            }
        }

        do {
            let result = try await sender.sendLocation(
                serverURLString: serverURLString,
                idToken: auth.idToken,
                location: locationManager.lastLocation
            )
            lastSentAt = now
            lastSendErrorText = nil
            lastSendStatusText = "Sent @ \(now.formatted()) (HTTP \(result.statusCode))"
        } catch {
            lastSendErrorText = error.localizedDescription
            lastSendStatusText = "Last attempt @ \(now.formatted())"
        }
    }
}

