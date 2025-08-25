import Foundation

public struct DiscoveredDevice: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let signalStrength: Int
    public let discoveredAt: Date
    public let isAlreadyAdded: Bool

    public init(
        id: String,
        name: String,
        type: DeviceType,
        signalStrength: Int,
        discoveredAt: Date,
        isAlreadyAdded: Bool
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.signalStrength = signalStrength
        self.discoveredAt = discoveredAt
        self.isAlreadyAdded = isAlreadyAdded
    }
}

public extension DiscoveredDevice {
    static let mockNew1 = DiscoveredDevice(
        id: "discovered-001",
        name: "Mock Device 1",
        type: .smartPlug,
        signalStrength: 0,
        discoveredAt: Date(),
        isAlreadyAdded: false
    )

    static let mockNew2 = DiscoveredDevice(
        id: "discovered-002",
        name: "Mock Device 2",
        type: .temperatureSensor,
        signalStrength: 0,
        discoveredAt: Date().addingTimeInterval(-120),
        isAlreadyAdded: false
    )

    static let mockAdded1 = DiscoveredDevice(
        id: "discovered-003",
        name: "Mock Device 3",
        type: .temperatureSensor,
        signalStrength: 0,
        discoveredAt: Date().addingTimeInterval(-60),
        isAlreadyAdded: true
    )

    static var mockDefaults: [DiscoveredDevice] {
        [.mockNew1, .mockNew2, mockAdded1]
    }
}
