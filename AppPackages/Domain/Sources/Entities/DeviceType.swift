import Foundation

public enum DeviceType: String, CaseIterable, Codable, Sendable {
    case smartLight = "smart_light"
    case temperatureSensor = "temperature_sensor"
    case unknown

    public var displayName: String {
        switch self {
        case .smartLight: "Smart Light"
        case .temperatureSensor: "Temperature Sensor"
        case .unknown: "Unknown"
        }
    }

    public var icon: String {
        switch self {
        case .smartLight: "lightbulb.fill"
        case .temperatureSensor: "thermometer.medium"
        case .unknown: "questionmark.diamond.fill"
        }
    }
}
