import Foundation

public struct Device: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let unitOfMeasurement: String?
    public let supportsBrightness: Bool
    public let isManaged: Bool
    public let addedDate: Date
    public var lastSeen: Date?
    public var status: DeviceConnectionStatus
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
        isManaged: Bool,
        addedDate: Date,
        lastSeen: Date?,
        status: DeviceConnectionStatus,
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
        self.isManaged = isManaged
        self.addedDate = addedDate
        self.lastSeen = lastSeen
        self.status = status
        self.commandTopic = commandTopic
        self.stateTopic = stateTopic
    }
}

public extension Device {
    static let mockLight = Device(
        id: "living_room_light",
        name: "Living Room Light",
        type: .smartLight,
        manufacturer: "Smart lights",
        model: "XYZ123",
        unitOfMeasurement: nil,
        supportsBrightness: true,
        isManaged: false,
        addedDate: Date(),
        lastSeen: nil,
        status: .connected,
        commandTopic: "home/light/living_room_light/set",
        stateTopic: "home/light/living_room_light/state"
    )

    static let mockTemperatureSensor = Device(
        id: "kitchen_temp_sensor",
        name: "Kitchen Temperature Sensor",
        type: .temperatureSensor,
        manufacturer: "Smart sensors",
        model: "YZA456",
        unitOfMeasurement: "C",
        supportsBrightness: false,
        isManaged: false,
        addedDate: Date(),
        lastSeen: nil,
        status: .disconnected,
        commandTopic: "home/light/kitchen_temp_sensor/set",
        stateTopic: "home/light/kitchen_temp_sensor/state"
    )

    static var mockDefaults: [Device] {
        [.mockLight, mockTemperatureSensor]
    }
}
