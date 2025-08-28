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
