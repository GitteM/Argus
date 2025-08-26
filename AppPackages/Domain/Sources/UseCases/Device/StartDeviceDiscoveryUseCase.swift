import Entities
import RepositoryProtocols

public final class StartDeviceDiscoveryUseCase: @unchecked Sendable {
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol

    public init(
        deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol
    ) {
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
    }

    public func execute() async throws {
        try await deviceDiscoveryRepository.startDiscovery()
    }
}
