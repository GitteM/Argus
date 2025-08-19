// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "InfrastructureLayer",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "InfrastructureLayer",
            targets: ["InfrastructureLayer"]
        ),
        .library(
            name: "CoreServices",
            targets: ["CoreServices"]
        ),
        .library(
            name: "DependencyInjection",
            targets: ["DependencyInjection"]
        ),
        .library(
            name: "Navigation",
            targets: ["Navigation"]
        ),
        .library(
            name: "CommonUI",
            targets: ["CommonUI"]
        ),
        .library(
            name: "Security",
            targets: ["Security"]
        ),
    ],
    dependencies: [
        .package(path: "../DomainLayer"),
    ],
    targets: [
        .target(
            name: "InfrastructureLayer",
            dependencies: [
                "CoreServices",
                "DependencyInjection",
                "Navigation",
                "CommonUI",
                "Security",
            ],
            path: "Sources/InfrastructureLayer"
        ),

        .target(
            name: "CoreServices",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
            ],
            path: "Sources/CoreServices"
        ),
        .target(
            name: "DependencyInjection",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
            ],
            path: "Sources/DependencyInjection"
        ),
        .target(
            name: "Navigation",
            dependencies: [],
            path: "Sources/Navigation"
        ),
        .target(
            name: "CommonUI",
            dependencies: [],
            path: "Sources/CommonUI",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "Security",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
            ],
            path: "Sources/Security"
        ),

        // MARK: - Test Targets

        .testTarget(
            name: "CoreServicesTests",
            dependencies: ["CoreServices"],
            path: "Tests/CoreServicesTests"
        ),
        .testTarget(
            name: "DependencyInjectionTests",
            dependencies: ["DependencyInjection"],
            path: "Tests/DependencyInjectionTests"
        ),
        .testTarget(
            name: "NavigationTests",
            dependencies: ["Navigation"],
            path: "Tests/NavigationTests"
        ),
        .testTarget(
            name: "CommonUITests",
            dependencies: ["CommonUI"],
            path: "Tests/CommonUITests"
        ),
        .testTarget(
            name: "SecurityTests",
            dependencies: ["Security"],
            path: "Tests/SecurityTests"
        ),
    ]
)
