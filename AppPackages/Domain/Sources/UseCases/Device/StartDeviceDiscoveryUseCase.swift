import Entities
import RepositoryProtocols

class StartDeviceDiscoveryUseCase {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    init(
        deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol
    ) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    func execute() async throws {
        try await deviceDiscoveryRepository.startDiscovery()
    }
}
