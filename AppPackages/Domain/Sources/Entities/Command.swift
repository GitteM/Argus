import Foundation

public struct Command: Codable, Sendable {
    let type: CommandType
    let payload: Data
    let targetDevice: String

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
