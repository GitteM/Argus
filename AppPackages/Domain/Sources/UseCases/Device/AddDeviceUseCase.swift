import Entities
import RepositoryProtocols

public final class AddDeviceUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol

    public init(
        deviceConnectionRepository: DeviceConnectionRepositoryProtocol
    ) {
        self.deviceConnectionRepository = deviceConnectionRepository
    }

    public func execute(discoveredDevice: DiscoveredDevice) async throws -> Device {
        try await deviceConnectionRepository.addDevice(discoveredDevice)
    }
}
