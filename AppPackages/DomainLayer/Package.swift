// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "DomainLayer",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "DomainLayer",
            targets: ["Entities", "RepositoryProtocols", "UseCases"]
        ),
        .library(
            name: "Entities",
            targets: ["Entities"]
        ),
        .library(
            name: "RepositoryProtocols",
            targets: ["RepositoryProtocols"]
        ),
        .library(
            name: "UseCases",
            targets: ["UseCases"]
        ),
    ],
    targets: [
        .target(
            name: "Entities",
            dependencies: [],
            path: "Sources/Entities"
        ),

        .target(
            name: "RepositoryProtocols",
            dependencies: ["Entities"],
            path: "Sources/RepositoryProtocols"
        ),

        .target(
            name: "UseCases",
            dependencies: [
                "Entities",
                "RepositoryProtocols",
            ],
            path: "Sources/UseCases"
        ),
        .testTarget(
            name: "DomainLayerTests",
            dependencies: [
                "Entities",
                "RepositoryProtocols",
                "UseCases",
            ],
            path: "Tests/DomainLayerTests"
        ),
    ]
)
