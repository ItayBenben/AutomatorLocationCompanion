import Foundation
import UIKit

enum DeviceId {
    static func stableId() -> String {
        // Uses vendor ID (stable per app vendor, resets on all-vendor uninstall).
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}

