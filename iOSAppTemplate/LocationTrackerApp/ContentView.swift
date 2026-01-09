import SwiftUI
import GoogleSignInSwift

struct ContentView: View {
    @EnvironmentObject private var auth: GoogleAuthViewModel
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var tracking: TrackingViewModel

    @State private var presentingVC: UIViewController?

    var body: some View {
        NavigationStack {
            Form {
                Section("Google") {
                    if auth.isSignedIn {
                        LabeledContent("Signed in as", value: auth.email ?? "(unknown)")
                        Button("Sign out", role: .destructive) {
                            auth.signOut()
                        }
                    } else {
                        GoogleSignInButton {
                            guard let vc = presentingVC ?? UIApplication.shared.topMostViewController() else {
                                auth.restorePreviousSignIn()
                                return
                            }
                            auth.signIn(presentingViewController: vc)
                        }
                        .frame(height: 44)
                    }

                    if let err = auth.lastAuthError {
                        Text(err).foregroundStyle(.red)
                    }
                }

                Section("Location") {
                    LabeledContent("Authorization", value: locationAuthText(locationManager.authorizationStatus))
                    Button("Request Always Permission") {
                        locationManager.requestAlwaysAuthorization()
                    }
                    if let err = locationManager.lastLocationError {
                        Text(err).foregroundStyle(.red)
                    }
                    if let loc = locationManager.lastLocation {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lat: \(loc.coordinate.latitude)")
                            Text("Lng: \(loc.coordinate.longitude)")
                            Text("Accuracy: \(Int(loc.horizontalAccuracy))m")
                            Text("Timestamp: \(loc.timestamp.formatted())")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    } else {
                        Text("No location yet.").foregroundStyle(.secondary)
                    }
                }

                Section("Server") {
                    TextField("Server URL", text: $tracking.serverURLString)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()

                    Stepper(
                        value: $tracking.sendIntervalSeconds,
                        in: AppConfig.minIntervalSeconds...AppConfig.maxIntervalSeconds,
                        step: 1
                    ) {
                        Text("Send every \(Int(tracking.sendIntervalSeconds)) seconds")
                    }

                    Button("Send now") {
                        Task { await tracking.sendNow() }
                    }
                    .disabled(!auth.isSignedIn)

                    if let status = tracking.lastSendStatusText {
                        Text(status).font(.footnote).foregroundStyle(.secondary)
                    }
                    if let err = tracking.lastSendErrorText {
                        Text(err).font(.footnote).foregroundStyle(.red)
                    }
                }

                Section("Tracking") {
                    Toggle("Tracking enabled", isOn: $tracking.isTrackingEnabled)
                        .onChange(of: tracking.isTrackingEnabled) { _, enabled in
                            if enabled {
                                tracking.start()
                            } else {
                                tracking.stop()
                            }
                        }

                    Text(tracking.trackingHintText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Location Tracker")
            .background(UIViewControllerAccessor(viewController: $presentingVC))
        }
    }

    private func locationAuthText(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedWhenInUse: return "When in use"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GoogleAuthViewModel())
        .environmentObject(LocationManager())
        .environmentObject(TrackingViewModel())
}

