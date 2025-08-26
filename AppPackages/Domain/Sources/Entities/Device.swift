import Foundation

public struct Device: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let isManaged: Bool
    public let addedDate: Date
    public var lastSeen: Date?
    public var status: DeviceConnectionStatus

    public init(
        id: String,
        name: String,
        type: DeviceType,
        isManaged: Bool,
        addedDate: Date,
        lastSeen: Date?,
        status: DeviceConnectionStatus
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isManaged = isManaged
        self.addedDate = addedDate
        self.lastSeen = lastSeen
        self.status = status
    }
}

public enum DeviceType: String, CaseIterable, Codable, Sendable {
    case smartLight = "smart_light"
    case smartPlug = "smart_plug"
    case smartThermostat = "smart_thermostat"
    case smartCamera = "smart_camera"
    case smartLock = "smart_lock"
    case motionSensor = "motion_sensor"
    case temperatureSensor = "temperature_sensor"
    case smartSpeaker = "smart_speaker"
    case unknown

    public var displayName: String {
        switch self {
        case .smartLight: "Smart Light"
        case .smartPlug: "Smart Plug"
        case .smartThermostat: "Smart Thermostat"
        case .smartCamera: "Smart Camera"
        case .smartLock: "Smart Lock"
        case .motionSensor: "Motion Sensor"
        case .temperatureSensor: "Temperature Sensor"
        case .smartSpeaker: "Smart Speaker"
        case .unknown: "Unknown"
        }
    }

    public var icon: String {
        switch self {
        case .smartLight: "lightbulb.fill"
        case .smartPlug: "powerplug.fill"
        case .smartThermostat: "thermometer.variable"
        case .smartCamera: "video.fill"
        case .smartLock: "lock.fill"
        case .motionSensor: "sensor.tag.radiowaves.forward.fill"
        case .temperatureSensor: "thermometer.medium"
        case .smartSpeaker: "speaker.wave.2.fill"
        case .unknown: "questionmark.diamond.fill"
        }
    }
}

public extension Device {
    static let mockConnected = Device(
        id: "mock-device-001",
        name: "Mock Device Connected",
        type: .temperatureSensor,
        isManaged: false,
        addedDate: Date(),
        lastSeen: nil,
        status: .connected
    )

    static let mockDisconnected = Device(
        id: "mock-device-002",
        name: "Mock Device Disconnected",
        type: .temperatureSensor,
        isManaged: false,
        addedDate: Date(),
        lastSeen: nil,
        status: .disconnected
    )

    static var mockDefaults: [Device] {
        [.mockConnected, mockDisconnected]
    }
}
