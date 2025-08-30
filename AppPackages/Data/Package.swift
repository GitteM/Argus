// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Data",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Data",
            targets: ["Core"]
        ),
        .library(
            name: "DataSource",
            targets: ["DataSource"]
        ),
        .library(
            name: "Persistence",
            targets: ["Persistence"]
        ),
        .library(
            name: "Repositories",
            targets: ["Repositories"]
        ),
        .library(
            name: "DataUtilities",
            targets: ["DataUtilities"]
        ),
    ],
    dependencies: [
        .package(path: "../Domain"),

        // MARK: - MQTT (For IoT real-time communication)

        .package(url: "https://github.com/emqx/CocoaMQTT.git", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                "Repositories",
                "Persistence",
                "DataSource",
            ],
            path: "Sources/Core"
        ),
        .target(
            name: "DataSource",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                "CocoaMQTT",
                "DataUtilities",
            ],
            path: "Sources/DataSource"
        ),
        .target(
            name: "Persistence",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
            ],
            path: "Sources/Persistence"
        ),
        .target(
            name: "Repositories",
            dependencies: [
                .product(name: "Domain", package: "Domain"),
                "Persistence",
                "DataSource",
            ],
            path: "Sources/Repositories"
        ),
        .target(
            name: "DataUtilities",
            dependencies: [
                .product(name: "ServiceProtocols", package: "Domain"),
            ],
            path: "Sources/Utilities"
        ),
        .testTarget(
            name: "DataSourceTests",
            dependencies: [
                "DataSource",
                .product(name: "Domain", package: "Domain"),
            ]
        ),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"],
            path: "Tests/PersistenceTests"
        ),
        .testTarget(
            name: "RepositoriesTests",
            dependencies: ["Repositories"],
            path: "Tests/RepositoriesTests"
        ),
    ]
)
