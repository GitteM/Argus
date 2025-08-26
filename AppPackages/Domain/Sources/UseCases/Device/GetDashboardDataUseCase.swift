import Entities
import RepositoryProtocols

public struct DeviceData: Sendable {
    public let managedDevices: [Device]
    public let discoveredDevices: [DiscoveredDevice]
}

public class GetDashboardDataUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol
    private let deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol
    private let deviceStateRepository: DeviceStateRepositoryProtocol

    public init(
        deviceConnectionRepository: DeviceConnectionRepositoryProtocol,
        deviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol,
        deviceStateRepository: DeviceStateRepositoryProtocol
    ) {
        self.deviceConnectionRepository = deviceConnectionRepository
        self.deviceDiscoveryRepository = deviceDiscoveryRepository
        self.deviceStateRepository = deviceStateRepository
    }

    public func execute() async throws -> DeviceData {
        async let managedDevices = deviceConnectionRepository.getManagedDevices()
        async let discoveredDevices = deviceDiscoveryRepository.getDiscoveredDevices()

        let (managed, discovered) = try await (managedDevices, discoveredDevices)

        return DeviceData(
            managedDevices: managed,
            discoveredDevices: discovered.filter { !$0.isAlreadyAdded }
        )
    }
}
