import DataSource
import Entities
import Foundation
import Persistence
import RepositoryProtocols

public struct DeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    private let mqttDataSource: MQTTDataSourceProtocol
    private let cacheManager: CacheManagerProtocol

    public init(
        mqttDataSource: MQTTDataSourceProtocol,
        cacheManager: CacheManagerProtocol
    ) {
        self.mqttDataSource = mqttDataSource
        self.cacheManager = cacheManager
    }

    public func startDiscovery() async throws {
        try await mqttDataSource.startDeviceDiscovery()
    }

    public func stopDiscovery() async throws {
        try await mqttDataSource.stopDeviceDiscovery()
    }

    // FIXME: This looks shakey - fixit
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

        // If no cached devices or they're expired, get from MQTT data source
        let discoveredDevices = await mqttDataSource.getDiscoveredDevices()

        // Cache the fresh results
        if !discoveredDevices.isEmpty {
            cacheManager.set(discoveredDevices, key: "discovered_devices", ttl: 300) // 5 minutes
        }

        return discoveredDevices
    }

    public func subscribeToDiscoveredDevices() async -> AsyncStream<[Entities.DiscoveredDevice]> {
        await mqttDataSource.subscribeToDeviceDiscovery()
    }
}
