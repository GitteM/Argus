import Entities
import RepositoryProtocols

@available(macOS 10.15, iOS 13, *)
public final class SubscribeToDeviceStatesUseCase: @unchecked Sendable {
    private let deviceStateRepository: DeviceStateRepositoryProtocol

    public init(deviceStateRepository: DeviceStateRepositoryProtocol) {
        self.deviceStateRepository = deviceStateRepository
    }

    @available(macOS 10.15, iOS 13, *)
    public func execute(stateTopic: String) async throws
        -> AsyncStream<DeviceState> {
        try await deviceStateRepository
            .subscribeToDeviceState(stateTopic: stateTopic)
    }
}
