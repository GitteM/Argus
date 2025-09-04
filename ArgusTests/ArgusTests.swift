import Entities
import Foundation
import OSLog
import Persistence
import Repositories
import ServiceProtocols
import Testing

// MARK: - Integration Test Suite

@Suite("Integration Tests")
struct ArgusIntegrationTests {
    // MARK: - Device Connection Repository Integration Tests

    @Test("Device connection repository should propagate cache errors")
    func deviceConnectionRepository_whenCacheError_propagatesError(
    ) async throws {
        // Given
        let mockLogger = MockLogger()
        let failingCacheManager = FailingCacheManager(logger: mockLogger)

        let repository = DeviceConnectionRepository(
            cacheManager: failingCacheManager
        )

        // When & Then
        await #expect(throws: AppError.self) {
            _ = try await repository.getManagedDevices()
        }
    }

    @Test(
        "Device connection repository should handle successful cache operations"
    )
    func deviceConnectionRepository_whenCacheSucceeds_returnsDevices(
    ) async throws {
        // Given
        let mockLogger = MockLogger()
        let workingCacheManager = try CacheManager(logger: mockLogger)
        let repository = DeviceConnectionRepository(
            cacheManager: workingCacheManager
        )

        // Clear any existing cache data to ensure test isolation
        try clearCache(workingCacheManager)

        // Pre-populate cache with test devices
        let testDevices = [
            Device.integrationTestLight,
            Device.integrationTestSensor
        ]
        let setCacheResult = await workingCacheManager.set(
            testDevices,
            key: "managed_devices",
            ttl: nil
        )
        switch setCacheResult {
        case .success:
            break
        case let .failure(error):
            throw error
        }

        // When
        let devices = try await repository.getManagedDevices()

        // Then
        #expect(devices.count == 2)
        #expect(devices.contains { $0.id == Device.integrationTestLight.id })
        #expect(devices.contains { $0.id == Device.integrationTestSensor.id })
    }

    @Test("Device connection repository should cache retrieved devices")
    func deviceConnectionRepository_cacheIntegration_storesAndRetrievesDevices(
    ) async throws {
        // Given
        let mockLogger = MockLogger()
        let workingCacheManager = try CacheManager(logger: mockLogger)
        let repository = DeviceConnectionRepository(
            cacheManager: workingCacheManager
        )

        // Clear any existing cache data to ensure test isolation
        try clearCache(workingCacheManager)

        // When - Initially should return empty array (no cached devices)
        let initialDevices = try await repository.getManagedDevices()

        // Debug: Print what's actually in the cache if it's not empty
        if !initialDevices.isEmpty {
            print(
                "DEBUG: Initial devices (expected empty): \(initialDevices.map { "\($0.id) (managed: \($0.isManaged))" })"
            )
        }

        #expect(
            initialDevices.isEmpty,
            "Cache should be empty after clearing, but contains \(initialDevices.count) devices"
        )

        // Add a device, which should cache it
        let discoveredDevice = DiscoveredDevice.integrationTestDevice
        let addedDevice = try await repository.addDevice(discoveredDevice)

        // Retrieve devices again - should return the cached device
        let cachedDevices = try await repository.getManagedDevices()

        // Debug: Print what's actually in the cache after adding device
        print(
            "DEBUG: Cached devices after adding: \(cachedDevices.map { "\($0.id) (managed: \($0.isManaged))" })"
        )
        print(
            "DEBUG: Added device: \(addedDevice.id) (managed: \(addedDevice.isManaged))"
        )

        // Then
        #expect(addedDevice.id == discoveredDevice.id)
        #expect(addedDevice
            .isManaged ==
            true
        ) // The device returned from addDevice should be managed

        // More flexible expectations - just ensure the device was added to
        // cache
        #expect(
            !cachedDevices.isEmpty,
            "Cache should contain devices after adding one"
        )
        #expect(
            cachedDevices.contains { $0.id == addedDevice.id },
            "Added device should be found in cache"
        )

        // Find the added device and verify its properties
        let addedDeviceInCache = cachedDevices.first { $0.id == addedDevice.id }
        #expect(
            addedDeviceInCache != nil,
            "Added device should be findable in cache"
        )
        #expect(
            addedDeviceInCache?.isManaged == true,
            "Added device should be marked as managed in cache"
        )
    }

    // MARK: - Cache Manager Integration with File System

    @Test("Cache manager should handle file system errors gracefully")
    func cacheManager_fileSystemIntegration_handlesErrors() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)
        let testData = TestData(id: "integration_test", value: 999)

        // When - Normal operation should succeed
        let result = await cacheManager.set(testData, key: "integration_key")

        // Then
        switch result {
        case .success:
            #expect(true) // Expected success
        case let .failure(error):
            // If it fails, it should be a proper AppError
            #expect(error.category == .system || error.category == .data)
        }
    }

    // MARK: - End-to-End Data Flow Tests

    @Test("End-to-end data flow from repository through cache to storage")
    func endToEndDataFlow_repositoryToCacheToStorage() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)
        let discoveredDevice = DiscoveredDevice.integrationTestDevice

        let repository = DeviceConnectionRepository(
            cacheManager: cacheManager
        )

        // Clear any existing cache data to ensure test isolation
        try clearCache(cacheManager)

        // When - Add a device (should persist to cache and disk)
        let addedDevice = try await repository.addDevice(discoveredDevice)

        // Verify it's in the managed devices (retrieved from cache)
        let managedDevices = try await repository.getManagedDevices()

        // Test device removal
        try await repository.removeDevice(deviceId: addedDevice.id)
        let devicesAfterRemoval = try await repository.getManagedDevices()

        // Then
        #expect(addedDevice.id == discoveredDevice.id)
        #expect(managedDevices.contains { $0.id == addedDevice.id })
        #expect(devicesAfterRemoval.isEmpty) // Device should be removed
    }
}

// MARK: - Test Helpers

private func clearCache(_ cacheManager: CacheManagerProtocol) throws {
    let clearResult = cacheManager.clear()
    switch clearResult {
    case .success:
        break
    case let .failure(error):
        throw error
    }
}

// MARK: - Mock Dependencies for Integration Tests

private final class MockLogger: LoggerProtocol, @unchecked Sendable {
    private let _loggedMessages = NSMutableArray()

    var loggedMessages: [String] {
        _loggedMessages.compactMap { $0 as? String }
    }

    func log(_ message: String, level _: OSLogType) {
        _loggedMessages.add(message)
    }
}

private final class FailingCacheManager: CacheManagerProtocol {
    let logger: LoggerProtocol

    init(logger: LoggerProtocol) {
        self.logger = logger
    }

    func get<T: Codable>(key: String) -> Result<T?, AppError> {
        .failure(AppError.cacheError(key: key, operation: "get"))
    }

    func set(
        _: some Codable & Sendable,
        key: String,
        ttl _: TimeInterval?
    ) async -> Result<Void, AppError> {
        .failure(AppError.cacheError(key: key, operation: "set"))
    }

    func remove(key _: String) {
        // No-op for failing cache
    }

    func clear() -> Result<Void, AppError> {
        .failure(AppError.cacheError(key: "all", operation: "clear"))
    }

    func exists(key _: String) -> Bool {
        false
    }
}

// MARK: - Test Data

private struct TestData: Codable, Sendable {
    let id: String
    let value: Int
}

// MARK: - Mock Entities for Integration Tests

private extension Device {
    static let integrationTestLight = Device(
        id: "integration_test_light",
        name: "Test Light",
        type: .smartLight,
        manufacturer: "Test Co",
        model: "TEST123",
        unitOfMeasurement: nil,
        supportsBrightness: true,
        isManaged: false,
        addedDate: Date(),
        lastSeen: Date(),
        status: .connected,
        commandTopic: "test/light/set",
        stateTopic: "test/light/state"
    )

    static let integrationTestSensor = Device(
        id: "integration_test_sensor",
        name: "Test Sensor",
        type: .temperatureSensor,
        manufacturer: "Test Co",
        model: "TEST456",
        unitOfMeasurement: "C",
        supportsBrightness: false,
        isManaged: false,
        addedDate: Date(),
        lastSeen: Date(),
        status: .connected,
        commandTopic: "test/sensor/set",
        stateTopic: "test/sensor/state"
    )
}

private extension DiscoveredDevice {
    static let integrationTestDevice = DiscoveredDevice(
        id: "integration_test_device",
        name: "Test Discovered Device",
        type: .smartLight,
        manufacturer: "Test Co",
        model: "TEST789",
        unitOfMeasurement: nil,
        supportsBrightness: true,
        discoveredAt: Date(),
        isAlreadyAdded: false,
        commandTopic: "test/discovered/set",
        stateTopic: "test/discovered/state"
    )
}
