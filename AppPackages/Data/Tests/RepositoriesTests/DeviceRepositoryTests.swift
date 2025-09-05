import Entities
import Foundation
import Persistence
@testable import Repositories
import Testing

// MARK: - DeviceConnectionRepository Tests

@Test("DeviceConnectionRepository adds device successfully")
func addDeviceSuccess() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)
    let discoveredDevice = createMockDiscoveredDevice(id: "test-device-1")

    mockCacheManager.stubbedGetResult = .success([Device]?.none)
    mockCacheManager.stubbedSetResult = .success(())

    // When
    let result = await repository.addDevice(discoveredDevice)

    // Then
    switch result {
    case let .success(device):
        #expect(device.id == "test-device-1")
        #expect(device.name == "Test Device")
        #expect(device.isManaged == true)
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceConnectionRepository fails to add existing device")
func addDeviceAlreadyExists() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)
    let discoveredDevice = createMockDiscoveredDevice(id: "existing-device")
    let existingDevice = createMockDevice(id: "existing-device")

    mockCacheManager.stubbedGetResult = .success([existingDevice])

    // When
    let result = await repository.addDevice(discoveredDevice)

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .deviceAlreadyExists(deviceId) = error {
            #expect(deviceId == "existing-device")
        } else {
            Issue.record("Expected deviceAlreadyExists but got: \(error)")
        }
    }
}

@Test("DeviceConnectionRepository handles cache failure on add device")
func addDeviceCacheFailure() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)
    let discoveredDevice = createMockDiscoveredDevice(id: "test-device")

    mockCacheManager.stubbedGetResult = .success([Device]?.none)
    mockCacheManager.stubbedSetResult = .failure(.cacheError(
        key: "managed_devices",
        operation: "set"
    ))

    // When
    let result = await repository.addDevice(discoveredDevice)

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .persistenceError(operation, details) = error {
            #expect(operation == "add_device")
            #expect(details?.contains("test-device") == true)
        } else {
            Issue.record("Expected persistenceError but got: \(error)")
        }
    }
}

@Test("DeviceConnectionRepository removes device successfully")
func removeDeviceSuccess() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)
    let existingDevice = createMockDevice(id: "device-to-remove")

    mockCacheManager.stubbedGetResult = .success([existingDevice])
    mockCacheManager.stubbedSetResult = .success(())

    // When
    let result = await repository.removeDevice(deviceId: "device-to-remove")

    // Then
    switch result {
    case .success:
        #expect(mockCacheManager.setCallCount == 1)
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceConnectionRepository fails to remove non-existent device")
func removeDeviceNotFound() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)

    mockCacheManager.stubbedGetResult = .success([Device]())

    // When
    let result = await repository.removeDevice(deviceId: "non-existent-device")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .deviceNotFound(deviceId) = error {
            #expect(deviceId == "non-existent-device")
        } else {
            Issue.record("Expected deviceNotFound but got: \(error)")
        }
    }
}

@Test("DeviceConnectionRepository gets managed devices successfully")
func getManagedDevicesSuccess() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)
    let testDevices = [
        createMockDevice(id: "device1"),
        createMockDevice(id: "device2")
    ]

    mockCacheManager.stubbedGetResult = .success(testDevices)

    // When
    let result = await repository.getManagedDevices()

    // Then
    switch result {
    case let .success(devices):
        #expect(devices.count == 2)
        #expect(devices.first?.id == "device1")
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceConnectionRepository handles cache failure when getting devices")
func getManagedDevicesCacheFailure() async throws {
    // Given
    let mockCacheManager = MockCacheManager()
    let repository = DeviceConnectionRepository(cacheManager: mockCacheManager)

    mockCacheManager.stubbedGetResult = .failure(.cacheError(
        key: "managed_devices",
        operation: "get"
    ))

    // When
    let result = await repository.getManagedDevices()

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .persistenceError(operation, _) = error {
            #expect(operation == "get_managed_devices")
        } else {
            Issue.record("Expected persistenceError but got: \(error)")
        }
    }
}

// MARK: - Mock Objects and Helpers

final class MockCacheManager: CacheManagerProtocol, @unchecked Sendable {
    var stubbedGetResult: Result<[Device]?, AppError> = .success(nil)
    var stubbedSetResult: Result<Void, AppError> = .success(())
    var getCallCount = 0
    var setCallCount = 0

    func get<T: Codable>(key _: String) -> Result<T?, AppError> {
        getCallCount += 1
        guard let result = stubbedGetResult as? Result<T?, AppError> else {
            return .failure(.persistenceError(
                operation: "mock_get",
                details: "Type mismatch in mock"
            ))
        }
        return result
    }

    func set(
        _: some Codable & Sendable,
        key _: String,
        ttl _: TimeInterval?
    ) async -> Result<Void, AppError> {
        setCallCount += 1
        return stubbedSetResult
    }

    func remove(key _: String) {}

    func clear() -> Result<Void, AppError> {
        .success(())
    }

    func exists(key _: String) -> Bool {
        true
    }
}

private func createMockDiscoveredDevice(id: String) -> DiscoveredDevice {
    DiscoveredDevice(
        id: id,
        name: "Test Device",
        type: .smartLight,
        manufacturer: "Test Manufacturer",
        model: "Test Model",
        unitOfMeasurement: nil,
        supportsBrightness: false,
        discoveredAt: Date(),
        isAlreadyAdded: false,
        commandTopic: "test/\(id)/commands",
        stateTopic: "test/\(id)/state"
    )
}

private func createMockDevice(id: String) -> Device {
    Device(
        id: id,
        name: "Test Device",
        type: .smartLight,
        manufacturer: "Test Manufacturer",
        model: "Test Model",
        unitOfMeasurement: nil,
        supportsBrightness: false,
        isManaged: true,
        addedDate: Date(),
        lastSeen: Date(),
        status: .connected,
        commandTopic: "test/\(id)/commands",
        stateTopic: "test/\(id)/state"
    )
}
