// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.55.0"),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.50.0"),
    ],
    targets: [
        .target(name: "BuildTools"),
    ]
)
