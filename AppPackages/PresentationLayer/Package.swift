// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "PresentationLayer",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PresentationLayer", targets: ["PresentationLayer"]),
        .library(name: "CommonModule", targets: ["CommonModule"]),
        .library(name: "DashboardModule", targets: ["DashboardModule"]),
        .library(name: "DeviceDetailModule", targets: ["DeviceDetailModule"]),
        .library(name: "SettingsModule", targets: ["SettingsModule"]),
        .library(name: "AlertsModule", targets: ["AlertsModule"]),
    ],
    dependencies: [
        .package(path: "../DomainLayer"),
    ],
    targets: [
        .target(
            name: "PresentationLayer",
            dependencies: [
                "DashboardModule",
                "DeviceDetailModule",
                "SettingsModule",
                "AlertsModule",
                "CommonModule",
            ]
        ),
        .target(
            name: "CommonModule",
            dependencies: [
                "DomainLayer",
            ],
            path: "Sources/CommonModule"
        ),

        // MARK: - Feature Modules

        .target(
            name: "DashboardModule",
            dependencies: [
                "CommonModule",
                "DomainLayer",
            ],
            path: "Sources/DashboardModule"
        ),
        .target(
            name: "DeviceDetailModule",
            dependencies: [
                "CommonModule",
                "DomainLayer",
            ],
            path: "Sources/DeviceDetailModule"
        ),
        .target(
            name: "SettingsModule",
            dependencies: [
                "CommonModule",
                "DomainLayer",
            ],
            path: "Sources/SettingsModule"
        ),
        .target(
            name: "AlertsModule",
            dependencies: [
                "CommonModule",
                "DomainLayer",
            ],
            path: "Sources/AlertsModule"
        ),

        // MARK: - Test Targets

        .testTarget(
            name: "AlertsModuleTests",
            dependencies: ["AlertsModule"],
            path: "Tests/AlertsModuleTests"
        ),
        .testTarget(
            name: "DashboardModuleTests",
            dependencies: ["DashboardModule"],
            path: "Tests/DashboardModuleTests"
        ),
        .testTarget(
            name: "DeviceDetailModuleTests",
            dependencies: ["DeviceDetailModule"],
            path: "Tests/DeviceDetailModuleTests"
        ),
        .testTarget(
            name: "SettingsModuleTests",
            dependencies: ["SettingsModule"],
            path: "Tests/SettingsModuleTests"
        ),
    ]
)
