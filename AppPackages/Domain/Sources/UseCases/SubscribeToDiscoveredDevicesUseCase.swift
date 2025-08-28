import Entities
import RepositoryProtocols

@available(macOS 10.15, iOS 13, *)
public final class SubscribeToDiscoveredDevicesUseCase: @unchecked Sendable {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    public init(deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    @available(macOS 10.15, iOS 13, *)
    public func execute() async throws -> AsyncStream<[DiscoveredDevice]> {
        try await deviceDiscoveryRepository.subscribeToDiscoveredDevices()
    }
}
