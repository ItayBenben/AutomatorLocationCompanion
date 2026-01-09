import SwiftUI
import GoogleSignIn

@main
struct LocationTrackerAppApp: App {
    @StateObject private var services = AppServices()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(services.auth)
                .environmentObject(services.locationManager)
                .environmentObject(services.tracking)
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

