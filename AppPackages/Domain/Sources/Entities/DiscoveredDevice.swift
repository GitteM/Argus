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
        id: "bedroom_light_discovered",
        name: "Bedroom Light",
        type: .smartLight,
        manufacturer: "Smart lights",
        model: "XYZ456",
        supportsBrightness: true,
        discoveredAt: Date(),
        isAlreadyAdded: false,
        commandTopic: "home/light/bedroom_light/set",
        stateTopic: "home/light/bedroom_light/state"
    )

    static let mockNew2 = DiscoveredDevice(
        id: "bathroom_temp_discovered",
        name: "Bathroom Temperature",
        type: .temperatureSensor,
        manufacturer: "Smart sensors",
        model: "YZA789",
        unitOfMeasurement: "C",
        supportsBrightness: false,
        discoveredAt: Date().addingTimeInterval(-120),
        isAlreadyAdded: false,
        commandTopic: "home/sensor/bathroom_temp/set",
        stateTopic: "home/sensor/bathroom_temp/state"
    )

    static var mockDefaults: [DiscoveredDevice] {
        [.mockNew1, .mockNew2]
    }
}
