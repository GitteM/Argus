// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Domain",
            targets: [
                "Entities", "RepositoryProtocols", "UseCases",
            ]
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
    dependencies: [
        .package(url: "https://github.com/emqx/CocoaMQTT.git", from: "2.1.0"),
    ],
    targets: [
        .target(
            name: "Entities",
            dependencies: [],
            path: "Sources/Entities"
        ),

        .target(
            name: "RepositoryProtocols",
            dependencies: [
                "Entities",
                "CocoaMQTT",
            ],
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
            name: "Unit",
            dependencies: [
                "Entities",
                "RepositoryProtocols",
                "UseCases",
            ],
            path: "Tests/Unit"
        ),
    ]
)
