// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "DataLayer",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "DataLayer",
            targets: ["DataLayer"]
        ),
        .library(
            name: "Repositories",
            targets: ["Repositories"]
        ),
        .library(
            name: "NetworkLayer",
            targets: ["NetworkLayer"]
        ),
        .library(
            name: "PersistenceLayer",
            targets: ["PersistenceLayer"]
        ),
        .library(
            name: "DataSourceLayer",
            targets: ["DataSourceLayer"]
        ),
    ],
    dependencies: [
        .package(path: "../DomainLayer"),

        // MARK: - MQTT (Essential for IoT real-time communication)

        .package(url: "https://github.com/emqx/CocoaMQTT.git", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "DataLayer",
            dependencies: [
                "Repositories",
                "NetworkLayer",
                "PersistenceLayer",
                "DataSourceLayer",
            ],
            path: "Sources/DataLayer"
        ),

        .target(
            name: "Repositories",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
                "NetworkLayer",
                "PersistenceLayer",
                "DataSourceLayer",
            ],
            path: "Sources/Repositories"
        ),

        .target(
            name: "NetworkLayer",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
            ],
            path: "Sources/NetworkLayer"
        ),

        .target(
            name: "PersistenceLayer",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
            ],
            path: "Sources/PersistenceLayer"
        ),

        .target(
            name: "DataSourceLayer",
            dependencies: [
                .product(name: "DomainLayer", package: "DomainLayer"),
                "CocoaMQTT",
            ],
            path: "Sources/DataSourceLayer"
        ),

        // MARK: - Test Targets

        .testTarget(
            name: "DataLayerTests",
            dependencies: [
                "DataLayer",
                .product(name: "DomainLayer", package: "DomainLayer"),
            ],
            path: "Tests/DataLayerTests"
        ),
        .testTarget(
            name: "RepositoriesTests",
            dependencies: ["Repositories"],
            path: "Tests/RepositoriesTests"
        ),
        .testTarget(
            name: "NetworkLayerTests",
            dependencies: ["NetworkLayer"],
            path: "Tests/NetworkLayerTests"
        ),
        .testTarget(
            name: "PersistenceLayerTests",
            dependencies: ["PersistenceLayer"],
            path: "Tests/PersistenceLayerTests"
        ),
    ]
)
