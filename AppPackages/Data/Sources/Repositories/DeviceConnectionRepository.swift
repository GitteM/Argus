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

        switch await cacheManager.set(
            managedDevices,
            key: "managed_devices",
            ttl: nil
        ) {
        case .success:
            break
        case let .failure(error):
            throw error
        }

        return device
    }

    public func removeDevice(deviceId: String) async throws {
        let managedDevices = try await getManagedDevices()
        let filteredDevices = managedDevices.filter { $0.id != deviceId }

        switch await cacheManager.set(
            filteredDevices,
            key: "managed_devices",
            ttl: nil
        ) {
        case .success:
            break
        case let .failure(error):
            throw error
        }
    }

    public func getManagedDevices() async throws -> [Device] {
        switch cacheManager.get(key: "managed_devices") as Result<
            [Device]?,
            AppError
        > {
        case let .success(cached):
            return cached ?? []
        case let .failure(error):
            throw error
        }
    }
}
