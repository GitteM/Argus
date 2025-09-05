import DataSource
import Entities
import Foundation
import Persistence
import RepositoryProtocols

@available(macOS 10.15, iOS 13, *)
public struct DeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    private let deviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol

    public init(
        deviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol
    ) {
        self.deviceDiscoveryDataSource = deviceDiscoveryDataSource
    }

    public func getDiscoveredDevices() async
        -> Result<[DiscoveredDevice], AppError> {
        // DataSource already handles caching with proper cleanup
        await deviceDiscoveryDataSource.getDiscoveredDevices()
    }

    @available(macOS 10.15, iOS 13, *)
    public func subscribeToDiscoveredDevices() async
        -> Result<AsyncStream<[DiscoveredDevice]>, AppError> {
        await deviceDiscoveryDataSource.subscribeToDeviceDiscovery()
    }
}
