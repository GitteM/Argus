import DataSource
import Entities
import Foundation
import Persistence
import RepositoryProtocols

public struct DeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    private let deviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol
    private let cacheManager: CacheManagerProtocol

    public init(
        deviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol,
        cacheManager: CacheManagerProtocol
    ) {
        self.deviceDiscoveryDataSource = deviceDiscoveryDataSource
        self.cacheManager = cacheManager
    }

    public func startDiscovery() async throws {
        try await deviceDiscoveryDataSource.startDeviceDiscovery()
    }

    public func stopDiscovery() async throws {
        try await deviceDiscoveryDataSource.stopDeviceDiscovery()
    }

    public func getDiscoveredDevices() async throws -> [DiscoveredDevice] {
        // First check cache
        if let cached: [DiscoveredDevice] = cacheManager.get(key: "discovered_devices") {
            let recent = cached.filter {
                // Only return devices discovered in last 5 minutes
                Date().timeIntervalSince($0.discoveredAt) < 300
            }
            if !recent.isEmpty {
                return recent
            }
        }

        // If no cached devices or they're expired, get from discovery data source
        let discoveredDevices = await deviceDiscoveryDataSource.getDiscoveredDevices()

        // Cache the fresh results
        if !discoveredDevices.isEmpty {
            cacheManager.set(discoveredDevices, key: "discovered_devices", ttl: 300) // 5 minutes
        }

        return discoveredDevices
    }

    public func subscribeToDiscoveredDevices() async throws -> AsyncStream<[DiscoveredDevice]> {
        await deviceDiscoveryDataSource.subscribeToDeviceDiscovery()
    }
}
