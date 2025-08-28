import DataSource
import Entities
import Foundation
import Persistence
import RepositoryProtocols

public struct DeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    private let cacheManager: CacheManagerProtocol

    public init(cacheManager: CacheManagerProtocol) {
        self.cacheManager = cacheManager
    }

    public func addDevice(_ discoveredDevice: DiscoveredDevice) async throws
        -> Device {
        let device = Device(
            id: discoveredDevice.id,
            name: discoveredDevice.name,
            type: discoveredDevice.type,
            manufacturer: discoveredDevice.manufacturer,
            model: discoveredDevice.model,
            unitOfMeasurement: discoveredDevice.unitOfMeasurement,
            supportsBrightness: discoveredDevice.supportsBrightness,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: discoveredDevice.commandTopic,
            stateTopic: discoveredDevice.stateTopic
        )

        var managedDevices = try await getManagedDevices()
        managedDevices.append(device)
        cacheManager.set(managedDevices, key: "managed_devices", ttl: nil)

        return device
    }

    public func removeDevice(deviceId: String) async throws {
        let managedDevices = try await getManagedDevices()
        let filteredDevices = managedDevices.filter { $0.id != deviceId }
        cacheManager.set(filteredDevices, key: "managed_devices", ttl: nil)
    }

    public func getManagedDevices() async throws -> [Device] {
        if let cached: [Device] = cacheManager.get(key: "managed_devices") {
            return cached
        }
        return []
    }
}
