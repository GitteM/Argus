import Foundation

public struct DeviceState: Sendable {
    public let deviceId: String
    public let isOnline: Bool
    public let battery: Int?
    public let temperature: Double?
    public let lastUpdate: Date

    public init(
        deviceId: String,
        isOnline: Bool,
        battery: Int?,
        temperature: Double?,
        lastUpdate: Date
    ) {
        self.deviceId = deviceId
        self.isOnline = isOnline
        self.battery = battery
        self.temperature = temperature
        self.lastUpdate = lastUpdate
    }
}
