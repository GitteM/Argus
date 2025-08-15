// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Infrastructure",
    products: [
        .library(
            name: "Infrastructure",
            targets: ["Infrastructure"]
        )
    ],
    dependencies: [
            .package(url: "https://github.com/realm/SwiftLint", from: "0.50.0")
    ],
    targets: [
        .target(
            name: "Infrastructure",
            dependencies: [],
            plugins: [
                .plugin(
                    name: "SwiftLintBuildToolPlugin",
                    package: "SwiftLint"
                )
            ]
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: ["Infrastructure"]
        )
    ]
)
