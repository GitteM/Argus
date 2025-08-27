import Entities
import RepositoryProtocols

public final class GetDiscoveredDevicesUseCase: @unchecked Sendable {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    public init(deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    public func execute() async throws -> [DiscoveredDevice] {
        let allDiscovered = try await deviceDiscoveryRepository.getDiscoveredDevices()
        return allDiscovered.filter { !$0.isAlreadyAdded }
    }
}
