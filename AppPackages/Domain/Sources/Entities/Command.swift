import Foundation

public struct Command {
    let type: CommandType
    let payload: Data
    let targetDevice: String
}

public enum CommandType {}
