import RepositoryProtocols

class StopDeviceDiscoveryUseCase {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    init(deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    func execute() async throws {
        try await deviceDiscoveryRepository.stopDiscovery()
    }
}
