import Foundation

public extension Bundle {
    static let mqttHost: String = Bundle.main.infoDictionary?["MQTT_HOST"] as? String ?? "localhost"

    static let mqttPort: UInt16 = {
        guard let portString = Bundle.main.infoDictionary?["MQTT_PORT"] as? String,
              let port = UInt16(portString)
        else {
            return 1883 // Default MQTT port
        }
        return port
    }()
}
