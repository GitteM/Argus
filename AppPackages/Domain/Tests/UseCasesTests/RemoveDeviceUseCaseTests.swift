import Entities
import Foundation
import RepositoryProtocols
import ServiceProtocols
import Testing
@testable import UseCases

@Suite("RemoveDeviceUseCase Tests")
struct RemoveDeviceUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute with valid device ID should remove device successfully")
    func executeWithValidDeviceId() async throws {
        // Given
        let deviceToRemove = Device.mockLight
        let otherDevice = Device.mockTemperatureSensor
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [deviceToRemove, otherDevice]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When
        try await sut.execute(deviceId: deviceToRemove.id)

        // Then
        #expect(mockRepository.getManagedDevicesCallCount == 1)
        #expect(mockRepository.removeDeviceCallCount == 1)
        #expect(mockRepository.lastRemovedDeviceId == deviceToRemove.id)
        #expect(mockMqttManager.unsubscribeCallCount == 1)
        #expect(mockMqttManager.lastUnsubscribedTopic == deviceToRemove
            .stateTopic
        )
    }

    @Test("Execute with temperature sensor should remove device successfully")
    func executeWithTemperatureSensor() async throws {
        // Given
        let temperatureSensor = Device.mockTemperatureSensor
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [temperatureSensor]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When
        try await sut.execute(deviceId: temperatureSensor.id)

        // Then
        #expect(mockRepository.removeDeviceCallCount == 1)
        #expect(mockRepository.lastRemovedDeviceId == temperatureSensor.id)
        #expect(mockMqttManager.lastUnsubscribedTopic == temperatureSensor
            .stateTopic
        )
    }

    @Test("Execute should unsubscribe from correct MQTT topic")
    func executeShouldUnsubscribeFromCorrectMqttTopic() async throws {
        // Given
        let device = Device(
            id: "test_device",
            name: "Test Device",
            type: .smartLight,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: true,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: "home/device/command",
            stateTopic: "home/device/state/specific"
        )

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When
        try await sut.execute(deviceId: device.id)

        // Then
        #expect(mockMqttManager.unsubscribeCallCount == 1)
        #expect(mockMqttManager
            .lastUnsubscribedTopic == "home/device/state/specific"
        )
    }

    // MARK: - Error Cases

    @Test(
        "Execute with non-existent device ID should throw deviceNotFound error"
    )
    func executeWithNonExistentDeviceId() async {
        // Given
        let nonExistentDeviceId = "non_existent_device"
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [
            Device.mockLight,
            Device.mockTemperatureSensor
        ]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When/Then
        await #expect(throws: AppError
            .deviceNotFound(deviceId: nonExistentDeviceId)
        ) {
            try await sut.execute(deviceId: nonExistentDeviceId)
        }

        // Verify no removal operations were performed
        #expect(mockRepository.removeDeviceCallCount == 0)
        #expect(mockMqttManager.unsubscribeCallCount == 0)
    }

    @Test("Execute with empty device list should throw deviceNotFound error")
    func executeWithEmptyDeviceList() async {
        // Given
        let deviceId = "any_device_id"
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = []
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When/Then
        await #expect(throws: AppError.deviceNotFound(deviceId: deviceId)) {
            try await sut.execute(deviceId: deviceId)
        }
    }

    @Test("Execute when getManagedDevices throws error should propagate error")
    func executeWhenGetManagedDevicesThrowsError() async {
        // Given
        let deviceId = "test_device"
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.shouldThrowErrorOnGet = true
        mockRepository.errorToThrow = MockError.repositoryFailure
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When/Then
        await #expect(throws: MockError.repositoryFailure) {
            try await sut.execute(deviceId: deviceId)
        }

        // Verify no removal operations were performed
        #expect(mockRepository.removeDeviceCallCount == 0)
        #expect(mockMqttManager.unsubscribeCallCount == 0)
    }

    @Test(
        "Execute when removeDevice throws error should propagate error after MQTT unsubscribe"
    )
    func executeWhenRemoveDeviceThrowsError() async {
        // Given
        let device = Device.mockLight
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device]
        mockRepository.shouldThrowErrorOnRemove = true
        mockRepository.errorToThrow = MockError.removalFailure
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When/Then
        await #expect(throws: MockError.removalFailure) {
            try await sut.execute(deviceId: device.id)
        }

        // Verify MQTT unsubscribe was called before the error
        #expect(mockMqttManager.unsubscribeCallCount == 1)
        #expect(mockMqttManager.lastUnsubscribedTopic == device.stateTopic)
        #expect(mockRepository.removeDeviceCallCount == 1)
    }

    // MARK: - Operation Order Tests

    @Test("Execute should perform operations in correct order")
    func executeShouldPerformOperationsInCorrectOrder() async throws {
        // Given
        let device = Device.mockLight
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When
        try await sut.execute(deviceId: device.id)

        // Then - verify correct order: get devices → unsubscribe → remove
        #expect(mockRepository.getManagedDevicesCallCount == 1)
        #expect(mockMqttManager.unsubscribeCallCount == 1)
        #expect(mockRepository.removeDeviceCallCount == 1)

        // Verify correct parameters were used
        #expect(mockMqttManager.lastUnsubscribedTopic == device.stateTopic)
        #expect(mockRepository.lastRemovedDeviceId == device.id)
    }

    // MARK: - Multiple Device Tests

    @Test("Execute should find correct device among multiple devices")
    func executeShouldFindCorrectDeviceAmongMultiple() async throws {
        // Given
        let device1 = Device(
            id: "device_1",
            name: "Device 1",
            type: .smartLight,
            manufacturer: "Manufacturer 1",
            model: "Model 1",
            supportsBrightness: true,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: "home/device1/command",
            stateTopic: "home/device1/state"
        )

        let device2 = Device(
            id: "device_2",
            name: "Device 2",
            type: .temperatureSensor,
            manufacturer: "Manufacturer 2",
            model: "Model 2",
            unitOfMeasurement: "C",
            supportsBrightness: false,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .disconnected,
            commandTopic: "home/device2/command",
            stateTopic: "home/device2/state"
        )

        let device3 = Device(
            id: "device_3",
            name: "Device 3",
            type: .smartLight,
            manufacturer: "Manufacturer 3",
            model: "Model 3",
            supportsBrightness: false,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: "home/device3/command",
            stateTopic: "home/device3/state"
        )

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device1, device2, device3]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When - remove device2
        try await sut.execute(deviceId: device2.id)

        // Then
        #expect(mockRepository.lastRemovedDeviceId == device2.id)
        #expect(mockMqttManager.lastUnsubscribedTopic == device2.stateTopic)
    }

    // MARK: - Edge Cases

    @Test(
        "Execute with device having empty state topic should still attempt unsubscribe"
    )
    func executeWithEmptyStateTopic() async throws {
        // Given
        let device = Device(
            id: "device_empty_topic",
            name: "Device Empty Topic",
            type: .smartLight,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: true,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: "home/device/command",
            stateTopic: "" // Empty state topic
        )

        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.managedDevices = [device]
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When
        try await sut.execute(deviceId: device.id)

        // Then
        #expect(mockMqttManager.unsubscribeCallCount == 1)
        #expect(mockMqttManager.lastUnsubscribedTopic == "")
        #expect(mockRepository.removeDeviceCallCount == 1)
    }

    @Test("Execute multiple times should work correctly")
    func executeMultipleTimes() async throws {
        // Given
        let device1 = Device.mockLight
        let device2 = Device.mockTemperatureSensor
        let mockRepository = MockDeviceConnectionRepository()
        let mockMqttManager = MockMQTTConnectionManager()
        let sut = RemoveDeviceUseCase(
            deviceConnectionRepository: mockRepository,
            mqttConnectionManager: mockMqttManager
        )

        // When - first removal
        mockRepository.managedDevices = [device1, device2]
        try await sut.execute(deviceId: device1.id)

        // Then - verify first removal
        #expect(mockRepository.removeDeviceCallCount == 1)
        #expect(mockMqttManager.unsubscribeCallCount == 1)

        // When - second removal
        mockRepository
            .managedDevices = [device2] // Simulate device1 being removed
        try await sut.execute(deviceId: device2.id)

        // Then - verify second removal
        #expect(mockRepository.removeDeviceCallCount == 2)
        #expect(mockMqttManager.unsubscribeCallCount == 2)
        #expect(mockRepository.lastRemovedDeviceId == device2.id)
        #expect(mockMqttManager.lastUnsubscribedTopic == device2.stateTopic)
    }
}

// MARK: - Mock Repository

private final class MockDeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    var getManagedDevicesCallCount = 0
    var removeDeviceCallCount = 0
    var managedDevices: [Device] = []
    var shouldThrowErrorOnGet = false
    var shouldThrowErrorOnRemove = false
    var errorToThrow: Error = MockError.repositoryFailure
    var lastRemovedDeviceId: String?

    func getManagedDevices() async throws -> [Device] {
        getManagedDevicesCallCount += 1

        if shouldThrowErrorOnGet {
            throw errorToThrow
        }

        return managedDevices
    }

    func removeDevice(deviceId: String) async throws {
        removeDeviceCallCount += 1
        lastRemovedDeviceId = deviceId

        if shouldThrowErrorOnRemove {
            throw errorToThrow
        }
    }

    func addDevice(_: DiscoveredDevice) async throws -> Device {
        // Not needed for RemoveDeviceUseCase tests
        Device.mockLight
    }
}

// MARK: - Mock MQTT Connection Manager

private final class MockMQTTConnectionManager: MQTTConnectionManagerProtocol {
    var connectionStatus: MQTTConnectionStatus = .connected
    var unsubscribeCallCount = 0
    var lastUnsubscribedTopic: String?

    func connect() async throws {
        // Not needed for RemoveDeviceUseCase tests
    }

    func disconnect() {
        // Not needed for RemoveDeviceUseCase tests
    }

    func subscribe(
        to _: String,
        handler _: @escaping @Sendable (MQTTMessage) -> Void
    ) {
        // Not needed for RemoveDeviceUseCase tests
    }

    func unsubscribe(from topic: String) {
        unsubscribeCallCount += 1
        lastUnsubscribedTopic = topic
    }

    func publish(topic _: String, payload _: String) async throws {
        // Not needed for RemoveDeviceUseCase tests
    }
}

// MARK: - Mock Error

private enum MockError: Error, Equatable {
    case repositoryFailure
    case removalFailure
    case deviceNotFound
}
