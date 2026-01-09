// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocationTrackerApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .executable(name: "LocationTrackerApp", targets: ["LocationTrackerApp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "LocationTrackerApp",
            dependencies: [
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "GoogleSignInSwift", package: "GoogleSignIn-iOS"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)

