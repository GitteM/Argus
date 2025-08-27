import Entities
import RepositoryProtocols

public final class SubscribeToDeviceStatesUseCase: @unchecked Sendable {
    private let deviceStateRepository: DeviceStateRepositoryProtocol

    public init(deviceStateRepository: DeviceStateRepositoryProtocol) {
        self.deviceStateRepository = deviceStateRepository
    }

    public func execute() async throws -> AsyncStream<[DeviceState]> {
        try await deviceStateRepository.subscribeToDeviceStates()
    }
}
