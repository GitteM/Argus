import Foundation

public struct DeviceState: Sendable, Codable {
    public let deviceId: String
    public let deviceType: DeviceType
    public let isOnline: Bool
    public let lastUpdate: Date
    public let payload: String?
    public let temperatureSensor: TemperatureSensor?
    public let lightState: LightState?
    public init(
        deviceId: String,
        deviceType: DeviceType,
        isOnline: Bool,
        lastUpdate: Date,
        payload: String?,
        temperatureSensor: TemperatureSensor?,
        lightState: LightState?
    ) {
        self.deviceId = deviceId
        self.deviceType = deviceType
        self.isOnline = isOnline
        self.lastUpdate = lastUpdate
        self.payload = payload
        self.temperatureSensor = temperatureSensor
        self.lightState = lightState
    }
}

public struct TemperatureSensor: Sendable, Codable {
    public let temperature: Double
    public let date: Date
    public let battery: Int

    public init(
        temperature: Double,
        date: Date,
        battery: Int
    ) {
        self.temperature = temperature
        self.date = date
        self.battery = battery
    }

    enum CodingKeys: String, CodingKey {
        case temperature, battery
        case date = "timestamp"
    }
}

public struct LightState: Sendable, Codable {
    public let state: Bool
    public let brightness: Int?
    public let date: Date

    public init(
        state: Bool,
        brightness: Int?,
        date: Date
    ) {
        self.state = state
        self.brightness = brightness
        self.date = date
    }

    enum CodingKeys: String, CodingKey {
        case state, brightness
        case date = "timestamp"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let stateString = try? container
            .decode(String.self, forKey: .state) {
            state = stateString.lowercased() == "on"
        } else {
            state = try container.decode(Bool.self, forKey: .state)
        }

        brightness = try container.decodeIfPresent(
            Int.self,
            forKey: .brightness
        )
        date = try container.decode(Date.self, forKey: .date)
    }
}

// MARK: Mock Data

public extension DeviceState {
    static let mockTemperature = DeviceState(
        deviceId: "12345",
        deviceType: .temperatureSensor,
        isOnline: true,
        lastUpdate: Date(),
        payload: nil,
        temperatureSensor: .mockTemperature,
        lightState: nil
    )

    static let mockLight = DeviceState(
        deviceId: "6789",
        deviceType: .smartLight,
        isOnline: true,
        lastUpdate: Date(),
        payload: nil,
        temperatureSensor: nil,
        lightState: .mockOnWithBrightness
    )
}

public extension LightState {
    static let mockOnWithBrightness = LightState(
        state: true,
        brightness: 75,
        date: Date()
    )

    static let mockOff = LightState(
        state: false,
        brightness: 0,
        date: Date()
    )
}

public extension TemperatureSensor {
    static let mockTemperature: TemperatureSensor = .init(
        temperature: 22.5,
        date: Date(),
        battery: 100
    )

    static let mockLowBattery: TemperatureSensor = .init(
        temperature: 22.5,
        date: Date(),
        battery: 15
    )
}
