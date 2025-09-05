import Entities
import RepositoryProtocols

public final class SendDeviceCommandUseCase: @unchecked Sendable {
    private let deviceCommandRepository: DeviceCommandRepositoryProtocol

    public init(deviceCommandRepository: DeviceCommandRepositoryProtocol) {
        self.deviceCommandRepository = deviceCommandRepository
    }

    public func execute(deviceId: String, command: Command) async throws {
        let result = await deviceCommandRepository.sendDeviceCommand(
            deviceId: deviceId,
            command: command
        )
        switch result {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }
}
