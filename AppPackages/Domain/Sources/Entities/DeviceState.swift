import Foundation

public struct DeviceState: Sendable {
    public let deviceId: String
    public let isOnline: Bool
    public let lastUpdate: Date

    public init(
        deviceId: String,
        isOnline: Bool,
        lastUpdate: Date
    ) {
        self.deviceId = deviceId
        self.isOnline = isOnline
        self.lastUpdate = lastUpdate
    }
}
