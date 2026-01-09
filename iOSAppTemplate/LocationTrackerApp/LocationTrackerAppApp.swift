import SwiftUI
import GoogleSignIn

@main
struct LocationTrackerAppApp: App {
    @StateObject private var auth = GoogleAuthViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tracking = TrackingViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(locationManager)
                .environmentObject(tracking)
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    tracking.bind(auth: auth, locationManager: locationManager)
                }
        }
    }
}

