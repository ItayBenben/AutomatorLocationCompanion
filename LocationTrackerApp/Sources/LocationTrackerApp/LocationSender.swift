import Foundation
import CoreLocation

struct SendResult {
    let statusCode: Int
    let responseBody: String
}

enum LocationSendError: Error, LocalizedError {
    case invalidServerURL
    case notSignedIn
    case noLocationYet
    case httpError(statusCode: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL: return "Invalid server URL."
        case .notSignedIn: return "Not signed in."
        case .noLocationYet: return "No location available yet."
        case let .httpError(statusCode, body): return "Server returned HTTP \(statusCode): \(body)"
        }
    }
}

final class LocationSender {
    private let urlSession: URLSession
    private let deviceId: String

    init(urlSession: URLSession = .shared, deviceId: String = DeviceId.stableId()) {
        self.urlSession = urlSession
        self.deviceId = deviceId
    }

    func sendLocation(
        serverURLString: String,
        idToken: String?,
        location: CLLocation?
    ) async throws -> SendResult {
        guard let url = URL(string: serverURLString), url.scheme != nil else {
            throw LocationSendError.invalidServerURL
        }
        guard let idToken, !idToken.isEmpty else {
            throw LocationSendError.notSignedIn
        }
        guard let location else {
            throw LocationSendError.noLocationYet
        }

        let payload = location.toPayload(deviceId: deviceId)
        let body = try JSONEncoder().encode(payload)

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await urlSession.data(for: req)
        let bodyString = String(data: data, encoding: .utf8) ?? ""
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200..<300).contains(statusCode) else {
            throw LocationSendError.httpError(statusCode: statusCode, body: bodyString)
        }
        return SendResult(statusCode: statusCode, responseBody: bodyString)
    }
}

