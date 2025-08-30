import Foundation

public struct Command: Codable, Sendable {
    public let type: CommandType
    public let payload: Data
    public let targetDevice: String

    public init(
        type: CommandType,
        payload: Data,
        targetDevice: String
    ) {
        self.type = type
        self.payload = payload
        self.targetDevice = targetDevice
    }
}

public enum CommandType: Codable, Sendable {
    case unknown
}
