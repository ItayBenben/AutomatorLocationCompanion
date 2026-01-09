import Foundation
import GoogleSignIn

/// App-wide single graph so tracking can start at launch (even without UI).
@MainActor
final class AppServices: ObservableObject {
    let auth: GoogleAuthViewModel
    let locationManager: LocationManager
    let tracking: TrackingViewModel

    init() {
        configureGoogleSignIn()

        let auth = GoogleAuthViewModel()
        let locationManager = LocationManager()
        let tracking = TrackingViewModel()

        self.auth = auth
        self.locationManager = locationManager
        self.tracking = tracking

        // Bind immediately so background relaunches still send.
        tracking.bind(auth: auth, locationManager: locationManager)
    }

    private func configureGoogleSignIn() {
        // GoogleSignIn needs a configuration. In many setups this comes from GoogleService-Info.plist,
        // but this template supports a simple Info.plist key too.
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
           !clientID.contains("YOUR_IOS_CLIENT_ID"),
           !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }
}

