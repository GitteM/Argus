import Foundation

public extension Bundle {
    static let mqttHost: String =
        Bundle.main.infoDictionary?["MQTT_HOST"] as? String ?? "localhost"

    static let mqttPort: UInt16 = {
        if let portString = Bundle.main.infoDictionary?["MQTT_PORT"] as? String,
           let port = UInt16(portString) {
            return port
        }
        return 1883
    }()
}
