import Entities
import RepositoryProtocols

public final class AddDeviceUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol

    public init(
        deviceConnectionRepository: DeviceConnectionRepositoryProtocol
    ) {
        self.deviceConnectionRepository = deviceConnectionRepository
    }

    public func execute(discoveredDevice: DiscoveredDevice) async throws
        -> Device {
        let result = await deviceConnectionRepository
            .addDevice(discoveredDevice)
        switch result {
        case let .success(device):
            return device
        case let .failure(error):
            throw error
        }
    }
}
