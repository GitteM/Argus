// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Domain",
            targets: [
                "Entities", "RepositoryProtocols", "ServiceProtocols",
                "UseCases",
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
            name: "ServiceProtocols",
            targets: ["ServiceProtocols"]
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
                "ServiceProtocols",
            ],
            path: "Sources/RepositoryProtocols"
        ),
        .target(
            name: "ServiceProtocols",
            dependencies: [
                "Entities",
                "CocoaMQTT",
            ],
            path: "Sources/ServiceProtocols"
        ),
        .target(
            name: "UseCases",
            dependencies: [
                "Entities",
                "RepositoryProtocols",
                "ServiceProtocols",
            ],
            path: "Sources/UseCases"
        )
    ]
)
