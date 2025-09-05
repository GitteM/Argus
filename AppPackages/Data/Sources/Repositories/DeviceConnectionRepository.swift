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

    public func addDevice(_ discoveredDevice: DiscoveredDevice) async
        -> Result<Device, AppError> {
        // Check if device already exists
        switch await getManagedDevices() {
        case let .success(existingDevices):
            if existingDevices
                .contains(where: { $0.id == discoveredDevice.id }) {
                return .failure(
                    .deviceAlreadyExists(
                        deviceId: discoveredDevice.id
                    )
                )
            }
        case let .failure(error):
            return .failure(error)
        }

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

        switch await getManagedDevices() {
        case let .success(managedDevices):
            var updatedDevices = managedDevices
            updatedDevices.append(device)

            switch await cacheManager.set(
                updatedDevices,
                key: "managed_devices",
                ttl: nil
            ) {
            case .success:
                return .success(device)
            case let .failure(error):
                return .failure(.persistenceError(
                    operation: "add_device",
                    details: "Failed to save device '\(device.id)': " +
                        "\(error.errorDescription ?? "unknown error")"
                ))
            }
        case let .failure(error):
            return .failure(error)
        }
    }

    public func removeDevice(deviceId: String) async -> Result<Void, AppError> {
        switch await getManagedDevices() {
        case let .success(managedDevices):
            // Check if device exists
            guard managedDevices.contains(where: { $0.id == deviceId })
            else {
                return .failure(.deviceNotFound(deviceId: deviceId))
            }

            let filteredDevices = managedDevices
                .filter { $0.id != deviceId }

            switch await cacheManager.set(
                filteredDevices,
                key: "managed_devices",
                ttl: nil
            ) {
            case .success:
                return .success(())
            case let .failure(error):
                return .failure(.persistenceError(
                    operation: "remove_device",
                    details: "Failed to remove device '\(deviceId)': " +
                        "\(error.errorDescription ?? "unknown error")"
                ))
            }
        case let .failure(error):
            return .failure(error)
        }
    }

    public func getManagedDevices() async -> Result<[Device], AppError> {
        let cacheResult: Result<[Device]?, AppError> = cacheManager
            .get(key: "managed_devices")
        switch cacheResult {
        case let .success(cached):
            return .success(cached ?? [])
        case let .failure(error):
            return .failure(.persistenceError(
                operation: "get_managed_devices",
                details: "Failed to retrieve devices from cache: " +
                    "\(error.errorDescription ?? "unknown error")"
            ))
        }
    }
}
