// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Infrastructure",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "Configuration",
            targets: ["Configuration"]
        ),
        .library(
            name: "DependencyInjection",
            targets: ["DependencyInjection"]
        ),
        .library(
            name: "Infrastructure",
            targets: ["Infrastructure"]
        ),
        .library(
            name: "Services",
            targets: ["Services"]
        ),
        .library(
            name: "Utilities",
            targets: ["Utilities"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Data"),
    ],
    targets: [
        .target(
            name: "Configuration",
            path: "Sources/Configuration"
        ),
        .target(
            name: "DependencyInjection",
            dependencies: [
                "Services",
                "Configuration",
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
                .product(
                    name: "Data",
                    package: "Data"
                ),
            ],
            path: "Sources/DependencyInjection"
        ),
        .target(
            name: "Infrastructure",
            dependencies: [
                "Services",
                "DependencyInjection",
                "Utilities",
            ],
            path: "Sources/Infrastructure"
        ),
        .target(
            name: "Services",
            dependencies: [
                "Utilities",
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
            ],
            path: "Sources/Services"
        ),
        .target(
            name: "Utilities",
            dependencies: [
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
            ],
            path: "Sources/Utilities"
        ),
        .testTarget(
            name: "ConfigurationTests",
            dependencies: ["Configuration"],
            path: "Tests/ConfigurationTests"
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
            path: "Tests/ServicesTests"
        ),
        .testTarget(
            name: "DependencyInjectionTests",
            dependencies: ["DependencyInjection"],
            path: "Tests/DependencyInjectionTests"
        ),
        .testTarget(
            name: "UtilitiesTests",
            dependencies: ["Utilities"],
            path: "Tests/UtilitiesTests"
        ),
    ]
)
