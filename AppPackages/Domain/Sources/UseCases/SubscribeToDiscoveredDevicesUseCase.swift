import Entities
import RepositoryProtocols

public final class SubscribeToDiscoveredDevicesUseCase: @unchecked Sendable {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    public init(deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    public func execute() async throws -> AsyncStream<[DiscoveredDevice]> {
        try await deviceDiscoveryRepository.subscribeToDiscoveredDevices()
    }
}
