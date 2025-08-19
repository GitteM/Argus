import Entities

public typealias SendDeviceCommandResult = Result<Command, Error>

public protocol SendDeviceCommandUseCase {
    func execute(_ command: Command) async throws -> SendDeviceCommandResult
}
