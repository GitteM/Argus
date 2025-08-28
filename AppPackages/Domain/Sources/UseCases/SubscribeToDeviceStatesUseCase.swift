import Entities
import RepositoryProtocols

public final class SubscribeToDeviceStatesUseCase: @unchecked Sendable {
    private let deviceStateRepository: DeviceStateRepositoryProtocol

    public init(deviceStateRepository: DeviceStateRepositoryProtocol) {
        self.deviceStateRepository = deviceStateRepository
    }

    public func execute(stateTopic: String) async throws
        -> AsyncStream<DeviceState> {
        try await deviceStateRepository
            .subscribeToDeviceState(stateTopic: stateTopic)
    }
}
