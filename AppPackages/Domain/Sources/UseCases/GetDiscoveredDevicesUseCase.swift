import Entities
import RepositoryProtocols

public final class GetDiscoveredDevicesUseCase: @unchecked Sendable {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    public init(deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    public func execute() async throws -> [DiscoveredDevice] {
        let result = await deviceDiscoveryRepository.getDiscoveredDevices()
        switch result {
        case let .success(allDiscovered):
            return allDiscovered.filter { !$0.isAlreadyAdded }
        case let .failure(error):
            throw error
        }
    }
}
