import SwiftUI
import UIKit

/// Provides a `UIViewController` reference for presenting Google Sign-In.
struct UIViewControllerAccessor: UIViewControllerRepresentable {
    @Binding var viewController: UIViewController?

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = ResolverViewController()
        vc.onResolve = { resolved in
            DispatchQueue.main.async {
                self.viewController = resolved
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class ResolverViewController: UIViewController {
    var onResolve: ((UIViewController) -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onResolve?(self)
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard
            let scene = connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
        else { return nil }

        return root.topMostPresented()
    }
}

extension UIViewController {
    func topMostPresented() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostPresented()
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostPresented()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostPresented()
        }
        return self
    }
}

