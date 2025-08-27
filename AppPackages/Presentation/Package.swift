// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Presentation",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Dashboard", targets: ["Dashboard"]),
        .library(name: "DeviceDetail", targets: ["DeviceDetail"]),
        .library(name: "Presentation", targets: ["Presentation"]),
        .library(name: "SharedUI", targets: ["SharedUI"]),
        .library(name: "Stores", targets: ["Stores"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Infrastructure"),
        .package(path: "../Data"),
        .package(path: "../Navigation"),
    ],
    targets: [
        .target(
            name: "Presentation",
            dependencies: [
                "Dashboard",
                "DeviceDetail",
                "SharedUI",
            ],
            path: "Sources/Presentation"
        ),
        .target(
            name: "Dashboard",
            dependencies: [
                "SharedUI",
                "Stores",
                .product(
                    name: "Navigation",
                    package: "Navigation"
                ),
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
                .product(
                    name: "Infrastructure",
                    package: "Infrastructure"
                ),
            ],
            path: "Sources/Dashboard"
        ),
        .target(
            name: "DeviceDetail",
            dependencies: [
                "SharedUI",
                "Stores",
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
                .product(
                    name: "Infrastructure",
                    package: "Infrastructure"
                ),
            ],
            path: "Sources/DeviceDetail"
        ),
        .target(
            name: "SharedUI",
            dependencies: [
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
                .product(
                    name: "Infrastructure",
                    package: "Infrastructure"
                ),
                .product(
                    name: "Data",
                    package: "Data"
                ),
            ],
            path: "Sources/SharedUI",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "Stores",
            dependencies: [
                "SharedUI",
                .product(
                    name: "Domain",
                    package: "Domain"
                ),
                .product(
                    name: "Infrastructure",
                    package: "Infrastructure"
                ),
            ],
            path: "Sources/Stores"
        ),
    ]
)
