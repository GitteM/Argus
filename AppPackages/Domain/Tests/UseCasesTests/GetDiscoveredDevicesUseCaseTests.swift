import Entities
import Foundation
import RepositoryProtocols
import Testing
@testable import UseCases

@Suite("GetDiscoveredDevicesUseCase Tests")
struct GetDiscoveredDevicesUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute with mixed devices should return only non-added devices")
    func executeWithMixedDevices() async throws {
        // Given
        let addedDevice = DiscoveredDevice(
            id: "added_device",
            name: "Added Device",
            type: .smartLight,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: true, // Already added
            commandTopic: "test/added/command",
            stateTopic: "test/added/state"
        )
        let newDevice1 = DiscoveredDevice.mockNew1 // isAlreadyAdded = false
        let newDevice2 = DiscoveredDevice.mockNew2 // isAlreadyAdded = false

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [addedDevice, newDevice1, newDevice2]
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(result.contains { $0.id == newDevice1.id })
        #expect(result.contains { $0.id == newDevice2.id })
        #expect(!result.contains { $0.id == addedDevice.id })
        #expect(mockRepository.getDiscoveredDevicesCallCount == 1)
    }

    @Test("Execute with only new devices should return all devices")
    func executeWithOnlyNewDevices() async throws {
        // Given
        let newDevice1 = DiscoveredDevice.mockNew1
        let newDevice2 = DiscoveredDevice.mockNew2
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [newDevice1, newDevice2]
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(result[0].id == newDevice1.id)
        #expect(result[1].id == newDevice2.id)
        #expect(result.allSatisfy { !$0.isAlreadyAdded })
    }

    @Test("Execute with only added devices should return empty array")
    func executeWithOnlyAddedDevices() async throws {
        // Given
        let addedDevice1 = DiscoveredDevice(
            id: "added_device_1",
            name: "Added Device 1",
            type: .smartLight,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: true,
            commandTopic: "test/added1/command",
            stateTopic: "test/added1/state"
        )
        let addedDevice2 = DiscoveredDevice(
            id: "added_device_2",
            name: "Added Device 2",
            type: .temperatureSensor,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: false,
            discoveredAt: Date(),
            isAlreadyAdded: true,
            commandTopic: "test/added2/command",
            stateTopic: "test/added2/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [addedDevice1, addedDevice2]
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.isEmpty)
        #expect(mockRepository.getDiscoveredDevicesCallCount == 1)
    }

    @Test("Execute with no devices should return empty array")
    func executeWithNoDevices() async throws {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = []
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.isEmpty)
        #expect(mockRepository.getDiscoveredDevicesCallCount == 1)
    }

    // MARK: - Error Cases

    @Test("Execute when repository throws error should propagate error")
    func executeWhenRepositoryThrowsError() async {
        // Given
        let expectedError = TestError.repositoryError
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = expectedError
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When/Then
        await #expect(throws: TestError.repositoryError) {
            try await sut.execute()
        }
        #expect(mockRepository.getDiscoveredDevicesCallCount == 1)
    }

    @Test(
        "Execute when repository throws device not found error should propagate error"
    )
    func executeWhenRepositoryThrowsDeviceNotFoundError() async {
        // Given
        let expectedError = TestError.deviceNotFound
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = expectedError
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When/Then
        await #expect(throws: TestError.deviceNotFound) {
            try await sut.execute()
        }
    }

    // MARK: - Filtering Logic Tests

    @Test("Execute should preserve device properties for non-added devices")
    func executeShouldPreserveDeviceProperties() async throws {
        // Given
        let originalDevice = DiscoveredDevice(
            id: "test_device",
            name: "Test Device Name",
            type: .temperatureSensor,
            manufacturer: "Test Manufacturer Inc",
            model: "Model XYZ123",
            unitOfMeasurement: "Celsius",
            supportsBrightness: false,
            discoveredAt: Date(timeIntervalSince1970: 1_609_459_200),
            // Fixed date for testing
            isAlreadyAdded: false,
            commandTopic: "home/sensor/test/command",
            stateTopic: "home/sensor/test/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [originalDevice]
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 1)
        let filteredDevice = result[0]
        #expect(filteredDevice.id == originalDevice.id)
        #expect(filteredDevice.name == originalDevice.name)
        #expect(filteredDevice.type == originalDevice.type)
        #expect(filteredDevice.manufacturer == originalDevice.manufacturer)
        #expect(filteredDevice.model == originalDevice.model)
        #expect(filteredDevice.unitOfMeasurement == originalDevice
            .unitOfMeasurement
        )
        #expect(filteredDevice.supportsBrightness == originalDevice
            .supportsBrightness
        )
        #expect(filteredDevice.discoveredAt == originalDevice.discoveredAt)
        #expect(filteredDevice.commandTopic == originalDevice.commandTopic)
        #expect(filteredDevice.stateTopic == originalDevice.stateTopic)
        #expect(!filteredDevice.isAlreadyAdded)
    }

    @Test("Execute multiple invocations should call repository each time")
    func executeMultipleInvocations() async throws {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [DiscoveredDevice.mockNew1]
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        _ = try await sut.execute()
        _ = try await sut.execute()
        _ = try await sut.execute()

        // Then
        #expect(mockRepository.getDiscoveredDevicesCallCount == 3)
    }

    // MARK: - Device Type Filtering Tests

    @Test("Execute with mixed device types should filter correctly")
    func executeWithMixedDeviceTypes() async throws {
        // Given
        let smartLight = DiscoveredDevice(
            id: "light_1",
            name: "Smart Light",
            type: .smartLight,
            manufacturer: "Light Co",
            model: "Light Model",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: "home/light/command",
            stateTopic: "home/light/state"
        )
        let temperatureSensor = DiscoveredDevice(
            id: "temp_1",
            name: "Temperature Sensor",
            type: .temperatureSensor,
            manufacturer: "Sensor Co",
            model: "Temp Model",
            unitOfMeasurement: "F",
            supportsBrightness: false,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: "home/temp/command",
            stateTopic: "home/temp/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [smartLight, temperatureSensor]
        let sut =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository: mockRepository
            )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(result.contains { $0.type == .smartLight })
        #expect(result.contains { $0.type == .temperatureSensor })
    }
}

// MARK: - Mock Repository

@available(macOS 10.15, iOS 13, *)
private final class MockDeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    var getDiscoveredDevicesCallCount = 0
    var discoveredDevices: [DiscoveredDevice] = []
    var shouldThrowError = false
    var errorToThrow: Error = TestError.repositoryError

    func getDiscoveredDevices() async throws -> [DiscoveredDevice] {
        getDiscoveredDevicesCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return discoveredDevices
    }

    func subscribeToDiscoveredDevices() async throws
        -> AsyncStream<[DiscoveredDevice]> {
        // Not needed for GetDiscoveredDevicesUseCase tests
        AsyncStream { continuation in
            continuation.yield(discoveredDevices)
            continuation.finish()
        }
    }
}
