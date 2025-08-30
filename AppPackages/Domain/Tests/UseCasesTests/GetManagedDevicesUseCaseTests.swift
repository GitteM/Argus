import Entities
import Foundation
import RepositoryProtocols
import Testing
@testable import UseCases

@Suite("GetManagedDevicesUseCase Tests")
struct GetManagedDevicesUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute with multiple managed devices should return all devices")
    func executeWithMultipleManagedDevices() async throws {
        // Given
        let device1 = Device.mockLight
        let device2 = Device.mockTemperatureSensor
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device1, device2]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(result.contains { $0.id == device1.id })
        #expect(result.contains { $0.id == device2.id })
        #expect(mockRepository.getManagedDevicesCallCount == 1)
    }

    @Test("Execute with single managed device should return device array")
    func executeWithSingleManagedDevice() async throws {
        // Given
        let device = Device.mockLight
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 1)
        #expect(result[0].id == device.id)
        #expect(result[0].name == device.name)
        #expect(result[0].type == device.type)
        #expect(result[0].isManaged == device.isManaged)
    }

    @Test("Execute with no managed devices should return empty array")
    func executeWithNoManagedDevices() async throws {
        // Given
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = []
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.isEmpty)
        #expect(mockRepository.getManagedDevicesCallCount == 1)
    }

    // MARK: - Device Properties Tests

    @Test("Execute should preserve all device properties")
    func executeShouldPreserveDeviceProperties() async throws {
        // Given
        let originalDevice = Device(
            id: "test_managed_device",
            name: "Test Managed Device",
            type: .smartLight,
            manufacturer: "Test Manufacturer Ltd",
            model: "Model ABC789",
            unitOfMeasurement: nil,
            supportsBrightness: true,
            isManaged: true,
            addedDate: Date(timeIntervalSince1970: 1_609_459_200), // Fixed date
            lastSeen: Date(timeIntervalSince1970: 1_609_462_800),
            status: .connected,
            commandTopic: "home/managed/test/command",
            stateTopic: "home/managed/test/state"
        )

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [originalDevice]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 1)
        let returnedDevice = result[0]
        #expect(returnedDevice.id == originalDevice.id)
        #expect(returnedDevice.name == originalDevice.name)
        #expect(returnedDevice.type == originalDevice.type)
        #expect(returnedDevice.manufacturer == originalDevice.manufacturer)
        #expect(returnedDevice.model == originalDevice.model)
        #expect(returnedDevice.unitOfMeasurement == originalDevice
            .unitOfMeasurement
        )
        #expect(returnedDevice.supportsBrightness == originalDevice
            .supportsBrightness
        )
        #expect(returnedDevice.isManaged == originalDevice.isManaged)
        #expect(returnedDevice.addedDate == originalDevice.addedDate)
        #expect(returnedDevice.lastSeen == originalDevice.lastSeen)
        #expect(returnedDevice.status == originalDevice.status)
        #expect(returnedDevice.commandTopic == originalDevice.commandTopic)
        #expect(returnedDevice.stateTopic == originalDevice.stateTopic)
    }

    @Test("Execute with devices of different types should return all")
    func executeWithMixedDeviceTypes() async throws {
        // Given
        let smartLight = Device(
            id: "managed_light_1",
            name: "Managed Smart Light",
            type: .smartLight,
            manufacturer: "Light Co",
            model: "Light Model",
            supportsBrightness: true,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: "home/light/managed/command",
            stateTopic: "home/light/managed/state"
        )

        let temperatureSensor = Device(
            id: "managed_temp_1",
            name: "Managed Temperature Sensor",
            type: .temperatureSensor,
            manufacturer: "Sensor Co",
            model: "Temp Model",
            unitOfMeasurement: "C",
            supportsBrightness: false,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .disconnected,
            commandTopic: "home/temp/managed/command",
            stateTopic: "home/temp/managed/state"
        )

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [smartLight, temperatureSensor]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(result.contains { $0.type == .smartLight })
        #expect(result.contains { $0.type == .temperatureSensor })
        #expect(result.filter(\.isManaged).count == 2)
    }

    @Test(
        "Execute with devices having different connection statuses should return all"
    )
    func executeWithMixedConnectionStatuses() async throws {
        // Given
        let connectedDevice = Device(
            id: "connected_device",
            name: "Connected Device",
            type: .smartLight,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: true,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: "test/connected/command",
            stateTopic: "test/connected/state"
        )

        let disconnectedDevice = Device(
            id: "disconnected_device",
            name: "Disconnected Device",
            type: .temperatureSensor,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: false,
            isManaged: true,
            addedDate: Date(),
            lastSeen: nil,
            status: .disconnected,
            commandTopic: "test/disconnected/command",
            stateTopic: "test/disconnected/state"
        )

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [connectedDevice, disconnectedDevice]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 2)
        #expect(result.contains { $0.status == .connected })
        #expect(result.contains { $0.status == .disconnected })
    }

    // MARK: - Error Cases

    @Test("Execute when repository throws error should propagate error")
    func executeWhenRepositoryThrowsError() async {
        // Given
        let expectedError = MockError.repositoryFailure
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = expectedError
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When/Then
        await #expect(throws: MockError.repositoryFailure) {
            try await sut.execute()
        }
        #expect(mockRepository.getManagedDevicesCallCount == 1)
    }

    @Test(
        "Execute when repository throws device not found error should propagate error"
    )
    func executeWhenRepositoryThrowsDeviceNotFoundError() async {
        // Given
        let expectedError = MockError.deviceNotFound
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = expectedError
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When/Then
        await #expect(throws: MockError.deviceNotFound) {
            try await sut.execute()
        }
    }

    // MARK: - Repository Interaction Tests

    @Test("Execute multiple invocations should call repository each time")
    func executeMultipleInvocations() async throws {
        // Given
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [Device.mockLight]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        _ = try await sut.execute()
        _ = try await sut.execute()
        _ = try await sut.execute()

        // Then
        #expect(mockRepository.getManagedDevicesCallCount == 3)
    }

    @Test("Execute should only call getManagedDevices method")
    func executeShouldOnlyCallGetManagedDevicesMethod() async throws {
        // Given
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [
            Device.mockLight,
            Device.mockTemperatureSensor
        ]
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        _ = try await sut.execute()

        // Then
        #expect(mockRepository.getManagedDevicesCallCount == 1)
        #expect(mockRepository.addDeviceCallCount == 0)
        #expect(mockRepository.removeDeviceCallCount == 0)
    }

    // MARK: - Large Dataset Tests

    @Test("Execute with large number of devices should handle correctly")
    func executeWithLargeNumberOfDevices() async throws {
        // Given
        let devices = (1 ... 100).map { index in
            Device(
                id: "device_\(index)",
                name: "Device \(index)",
                type: index % 2 == 0 ? .smartLight : .temperatureSensor,
                manufacturer: "Test Manufacturer",
                model: "Model \(index)",
                unitOfMeasurement: index % 2 == 0 ? nil : "C",
                supportsBrightness: index % 2 == 0,
                isManaged: true,
                addedDate: Date(),
                lastSeen: Date(),
                status: .connected,
                commandTopic: "test/device_\(index)/command",
                stateTopic: "test/device_\(index)/state"
            )
        }

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = devices
        let sut = GetManagedDevicesUseCase(
            deviceConnectionRepository: mockRepository
        )

        // When
        let result = try await sut.execute()

        // Then
        #expect(result.count == 100)
        #expect(result.filter(\.isManaged).count == 100)
        #expect(result.count(where: { $0.type == .smartLight }) == 50)
        #expect(result.count(where: { $0.type == .temperatureSensor }) == 50)
    }
}

// MARK: - Mock Repository

private final class MockDeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    var getManagedDevicesCallCount = 0
    var addDeviceCallCount = 0
    var removeDeviceCallCount = 0
    var managedDevices: [Device] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockError.repositoryFailure

    func getManagedDevices() async throws -> [Device] {
        getManagedDevicesCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return managedDevices
    }

    func addDevice(_: DiscoveredDevice) async throws -> Device {
        addDeviceCallCount += 1
        // Not needed for GetManagedDevicesUseCase tests
        return Device.mockLight
    }

    func removeDevice(deviceId _: String) async throws {
        removeDeviceCallCount += 1
        // Not needed for GetManagedDevicesUseCase tests
    }
}

// MARK: - Mock Error

private enum MockError: Error, Equatable {
    case repositoryFailure
    case deviceNotFound
}
