// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Navigation",
    platforms: [
        .iOS(.v17),
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Navigation", targets: ["Navigation"]),
    ],
    dependencies: [
        .package(path: "../Presentation"),
    ],
    targets: [
        .target(
            name: "Navigation",
            dependencies: [
                .product(name: "DeviceDetail", package: "Presentation"),
                .product(name: "SharedUI", package: "Presentation"),
            ],
            path: "Sources/Navigation"
        ),
    ]
)
