import Foundation

public struct DiscoveredDevice: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let unitOfMeasurement: String?
    public let supportsBrightness: Bool
    public let discoveredAt: Date
    public let isAlreadyAdded: Bool
    public let commandTopic: String
    public let stateTopic: String

    public init(
        id: String,
        name: String,
        type: DeviceType,
        manufacturer: String,
        model: String,
        unitOfMeasurement: String? = nil,
        supportsBrightness: Bool,
        discoveredAt: Date,
        isAlreadyAdded: Bool,
        commandTopic: String,
        stateTopic: String
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.manufacturer = manufacturer
        self.model = model
        self.unitOfMeasurement = unitOfMeasurement
        self.supportsBrightness = supportsBrightness
        self.discoveredAt = discoveredAt
        self.isAlreadyAdded = isAlreadyAdded
        self.commandTopic = commandTopic
        self.stateTopic = stateTopic
    }
}

public extension DiscoveredDevice {
    static let mockNew1 = DiscoveredDevice(
        id: "living_room_light",
        name: "Living Room Light",
        type: .smartLight,
        manufacturer: "Smart lights",
        model: "XYZ123",
        supportsBrightness: true,
        discoveredAt: Date(),
        isAlreadyAdded: false,
        commandTopic: "home/light/living_room_light/set",
        stateTopic: "home/light/living_room_light/state"
    )

    static let mockNew2 = DiscoveredDevice(
        id: "kitchen_temp_sensor",
        name: "Kitchen Temperature Sensor",
        type: .temperatureSensor,
        manufacturer: "Smart sensors",
        model: "YZA456",
        unitOfMeasurement: "C",
        supportsBrightness: false,
        discoveredAt: Date().addingTimeInterval(-120),
        isAlreadyAdded: true,
        commandTopic: "home/light/kitchen_temp_sensor/set",
        stateTopic: "home/light/kitchen_temp_sensor/state"
    )

    static var mockDefaults: [DiscoveredDevice] {
        [.mockNew1, .mockNew2]
    }
}
