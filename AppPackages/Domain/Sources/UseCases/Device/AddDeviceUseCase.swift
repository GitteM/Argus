import Entities
import RepositoryProtocols

class AddDeviceUseCase {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol

    init(
        deviceConnectionRepository: DeviceConnectionRepositoryProtocol
    ) {
        self.deviceConnectionRepository = deviceConnectionRepository
    }

    func execute(discoveredDevice: DiscoveredDevice) async throws -> Device {
        try await deviceConnectionRepository.addDevice(discoveredDevice)
    }
}
