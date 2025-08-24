import Foundation

public struct DeviceState: Sendable {
    let deviceId: String
    let isOnline: Bool
    let battery: Int?
    let temperature: Double?
    let lastUpdate: Date

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
