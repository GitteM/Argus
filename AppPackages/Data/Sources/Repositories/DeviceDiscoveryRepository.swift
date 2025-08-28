import DataSource
import Entities
import Foundation
import Persistence
import RepositoryProtocols

public struct DeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    private let deviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol

    public init(
        deviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol
    ) {
        self.deviceDiscoveryDataSource = deviceDiscoveryDataSource
    }

    public func getDiscoveredDevices() async throws -> [DiscoveredDevice] {
        // DataSource already handles caching with proper cleanup
        await deviceDiscoveryDataSource.getDiscoveredDevices()
    }

    public func subscribeToDiscoveredDevices() async throws
        -> AsyncStream<[DiscoveredDevice]> {
        await deviceDiscoveryDataSource.subscribeToDeviceDiscovery()
    }
}
