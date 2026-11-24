// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CameraFeature",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "CameraFeature", targets: ["CameraFeature"])],
    targets: [
        .target(name: "CameraFeature"),
        .testTarget(name: "CameraFeatureTests", dependencies: ["CameraFeature"])
    ]
)
