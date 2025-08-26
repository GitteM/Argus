import Foundation

public struct DiscoveredDevice: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let discoveredAt: Date
    public let isAlreadyAdded: Bool

    public init(
        id: String,
        name: String,
        type: DeviceType,
        manufacturer: String,
        model: String,
        discoveredAt: Date,
        isAlreadyAdded: Bool
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.discoveredAt = discoveredAt
        self.isAlreadyAdded = isAlreadyAdded
    }
}

public extension DiscoveredDevice {
    static let mockNew1 = DiscoveredDevice(
        id: "mock-device-001",
        name: "Living Room Light",
        type: .smartLight,
        manufacturer: "Smart lights",
        model: "XYZ123",
        discoveredAt: Date(),
        isAlreadyAdded: false
    )

    static let mockNew2 = DiscoveredDevice(
        id: "mock-device-002",
        name: "Kitchen Temperature Sensor",
        type: .temperatureSensor,
        manufacturer: "Smart sensors",
        model: "YZA456",
        discoveredAt: Date().addingTimeInterval(-120),
        isAlreadyAdded: false
    )

    static let mockAdded1 = DiscoveredDevice(
        id: "mock-device-003",
        name: "Smart Thermostat",
        type: .smartThermostat,
        manufacturer: "Smart home",
        model: "ZYX789",
        discoveredAt: Date().addingTimeInterval(-60),
        isAlreadyAdded: true
    )

    static var mockDefaults: [DiscoveredDevice] {
        [.mockNew1, .mockNew2, mockAdded1]
    }
}
