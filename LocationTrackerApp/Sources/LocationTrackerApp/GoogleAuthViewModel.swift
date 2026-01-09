import Foundation
import Combine
import UIKit
import GoogleSignIn

@MainActor
final class GoogleAuthViewModel: ObservableObject {
    @Published private(set) var isSignedIn: Bool = false
    @Published private(set) var email: String?
    @Published private(set) var idToken: String?
    @Published private(set) var lastAuthError: String?

    init() {
        restorePreviousSignIn()
    }

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            Task { @MainActor in
                if let error {
                    self?.applySignedOutState(errorMessage: "Restore sign-in failed: \(error.localizedDescription)")
                    return
                }
                self?.applyUser(user)
            }
        }
    }

    func signIn(presentingViewController: UIViewController) {
        lastAuthError = nil
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            Task { @MainActor in
                if let error {
                    self?.applySignedOutState(errorMessage: "Sign-in failed: \(error.localizedDescription)")
                    return
                }
                self?.applyUser(result?.user)
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        applySignedOutState(errorMessage: nil)
    }

    /// Ensures `idToken` is fresh enough to use for server auth.
    func refreshTokensIfNeeded() async {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            applySignedOutState(errorMessage: nil)
            return
        }
        do {
            let refreshed = try await user.refreshTokensIfNeeded()
            applyUser(refreshed)
        } catch {
            applySignedOutState(errorMessage: "Token refresh failed: \(error.localizedDescription)")
        }
    }

    private func applySignedOutState(errorMessage: String?) {
        isSignedIn = false
        email = nil
        idToken = nil
        lastAuthError = errorMessage
    }

    private func applyUser(_ user: GIDGoogleUser?) {
        guard let user else {
            applySignedOutState(errorMessage: nil)
            return
        }
        isSignedIn = true
        email = user.profile?.email
        idToken = user.idToken?.tokenString
    }
}

