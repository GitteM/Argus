// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Presentation",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "Alerts", targets: ["Alerts"]),
        .library(name: "Dashboard", targets: ["Dashboard"]),
        .library(name: "DeviceDetail", targets: ["DeviceDetail"]),
        .library(name: "Navigation", targets: ["Navigation"]),
        .library(name: "Presentation", targets: ["Presentation"]),
        .library(name: "Settings", targets: ["Settings"]),
        .library(name: "SharedUI", targets: ["SharedUI"]),
    ],
    dependencies: [
        .package(path: "../Domain"),
        .package(path: "../Infrastructure"),
        .package(path: "../Data"),
    ],
    targets: [
        .target(
            name: "Presentation",
            dependencies: [
                "Alerts",
                "Dashboard",
                "DeviceDetail",
                "Navigation",
                "Settings",
                "SharedUI",
            ],
            path: "Sources/Presentation"
        ),
        .target(
            name: "Alerts",
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
            path: "Sources/Alerts"
        ),
        .target(
            name: "Dashboard",
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
            path: "Sources/Dashboard"
        ),
        .target(
            name: "DeviceDetail",
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
            path: "Sources/DeviceDetail"
        ),
        .target(
            name: "Navigation",
            dependencies: [],
            path: "Sources/Navigation"
        ),
        .target(
            name: "Settings",
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
            path: "Sources/Settings"
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
        .testTarget(
            name: "AlertsTests",
            dependencies: ["Alerts"],
            path: "Tests/AlertsTests"
        ),
        .testTarget(
            name: "DashboardTests",
            dependencies: ["Dashboard"],
            path: "Tests/DashboardTests"
        ),
        .testTarget(
            name: "DeviceDetailTests",
            dependencies: ["DeviceDetail"],
            path: "Tests/DeviceDetailTests"
        ),
        .testTarget(
            name: "NavigationTests",
            dependencies: ["Navigation"],
            path: "Tests/NavigationTests"
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"],
            path: "Tests/SettingsTests"
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUI"],
            path: "Tests/SharedUITests"
        ),
    ]
)
