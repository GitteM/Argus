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

    public func getDiscoveredDevices() async throws -> [DiscoveredDevice] {
        if let cached: [DiscoveredDevice] = cacheManager.get(key: "discovered_devices") {
            return cached.filter {
                // Only return devices discovered in last 5 minutes
                Date().timeIntervalSince($0.discoveredAt) < 300
            }
        }
        return []
    }

    public func subscribeToDiscoveredDevices() async -> AsyncStream<[Entities.DiscoveredDevice]> {
        await mqttDataSource.subscribeToDeviceDiscovery()
    }
}
