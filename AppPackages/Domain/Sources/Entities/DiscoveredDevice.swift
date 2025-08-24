import Foundation

public struct DiscoveredDevice: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let signalStrength: Int
    public let discoveredAt: Date
    public let isAlreadyAdded: Bool

    public init(
        id: String,
        name: String,
        type: DeviceType,
        signalStrength: Int,
        discoveredAt: Date,
        isAlreadyAdded: Bool
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.signalStrength = signalStrength
        self.discoveredAt = discoveredAt
        self.isAlreadyAdded = isAlreadyAdded
    }
}
