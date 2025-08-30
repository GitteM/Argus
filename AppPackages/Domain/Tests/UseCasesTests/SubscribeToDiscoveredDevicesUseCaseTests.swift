import Entities
import Foundation
import RepositoryProtocols
import Testing
@testable import UseCases

@Suite("SubscribeToDiscoveredDevicesUseCase Tests")
struct SubscribeToDiscoveredDevicesUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute should return AsyncStream of discovered devices")
    func executeShouldReturnAsyncStreamOfDiscoveredDevices() async throws {
        // Given
        let mockDevices = [DiscoveredDevice.mockNew1, DiscoveredDevice.mockNew2]
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [mockDevices]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 1)

        // Verify stream yields expected devices
        var receivedBatches: [[DiscoveredDevice]] = []
        for await deviceBatch in stream {
            receivedBatches.append(deviceBatch)
            if receivedBatches.count >= 1 {
                break
            }
        }

        #expect(receivedBatches.count == 1)
        #expect(receivedBatches[0].count == 2)
        #expect(receivedBatches[0][0].id == DiscoveredDevice.mockNew1.id)
        #expect(receivedBatches[0][1].id == DiscoveredDevice.mockNew2.id)
    }

    @Test("Execute with empty discovered devices should handle gracefully")
    func executeWithEmptyDiscoveredDevices() async throws {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = []
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 1)

        // Verify stream completes without yielding values
        var receivedBatches: [[DiscoveredDevice]] = []
        for await deviceBatch in stream {
            receivedBatches.append(deviceBatch)
        }

        #expect(receivedBatches.isEmpty)
    }

    @Test("Execute with single device batch should stream correctly")
    func executeWithSingleDeviceBatch() async throws {
        // Given
        let singleDevice = DiscoveredDevice.mockNew1
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[singleDevice]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 1)

        // Verify stream content
        var receivedBatches: [[DiscoveredDevice]] = []
        for await deviceBatch in stream {
            receivedBatches.append(deviceBatch)
            break
        }

        #expect(receivedBatches.count == 1)
        #expect(receivedBatches[0].count == 1)
        #expect(receivedBatches[0][0].id == singleDevice.id)
        #expect(receivedBatches[0][0].name == singleDevice.name)
        #expect(receivedBatches[0][0].type == singleDevice.type)
    }

    @Test("Execute with multiple device batches should stream all batches")
    func executeWithMultipleDeviceBatches() async throws {
        // Given
        let batch1 = [DiscoveredDevice.mockNew1]
        let batch2 = [DiscoveredDevice.mockNew2]
        let customDevice = DiscoveredDevice(
            id: "custom_discovered",
            name: "Custom Device",
            type: .smartLight,
            manufacturer: "Custom Manufacturer",
            model: "Custom Model",
            supportsBrightness: false,
            discoveredAt: Date(),
            isAlreadyAdded: true,
            commandTopic: "home/custom/set",
            stateTopic: "home/custom/state"
        )
        let batch3 = [customDevice]

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [batch1, batch2, batch3]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then
        var receivedBatches: [[DiscoveredDevice]] = []
        for await deviceBatch in stream {
            receivedBatches.append(deviceBatch)
            if receivedBatches.count >= 3 {
                break
            }
        }

        #expect(receivedBatches.count == 3)
        #expect(receivedBatches[0][0].id == DiscoveredDevice.mockNew1.id)
        #expect(receivedBatches[1][0].id == DiscoveredDevice.mockNew2.id)
        #expect(receivedBatches[2][0].id == customDevice.id)
    }

    @Test("Execute with mixed device types should preserve device properties")
    func executeWithMixedDeviceTypes() async throws {
        // Given
        let lightDevice = DiscoveredDevice(
            id: "light_device",
            name: "Smart Light",
            type: .smartLight,
            manufacturer: "Light Co",
            model: "L123",
            supportsBrightness: true,
            discoveredAt: Date(timeIntervalSince1970: 1_609_459_200),
            isAlreadyAdded: false,
            commandTopic: "home/light/set",
            stateTopic: "home/light/state"
        )
        let tempDevice = DiscoveredDevice(
            id: "temp_sensor",
            name: "Temperature Sensor",
            type: .temperatureSensor,
            manufacturer: "Sensor Inc",
            model: "T456",
            unitOfMeasurement: "°C",
            supportsBrightness: false,
            discoveredAt: Date(timeIntervalSince1970: 1_609_459_300),
            isAlreadyAdded: true,
            commandTopic: "home/sensor/set",
            stateTopic: "home/sensor/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[lightDevice, tempDevice]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then - Verify all properties are preserved
        for await deviceBatch in stream {
            #expect(deviceBatch.count == 2)

            let receivedLight = deviceBatch[0]
            #expect(receivedLight.id == lightDevice.id)
            #expect(receivedLight.name == lightDevice.name)
            #expect(receivedLight.type == lightDevice.type)
            #expect(receivedLight.manufacturer == lightDevice.manufacturer)
            #expect(receivedLight.model == lightDevice.model)
            #expect(receivedLight.supportsBrightness == lightDevice
                .supportsBrightness
            )
            #expect(receivedLight.discoveredAt == lightDevice.discoveredAt)
            #expect(receivedLight.isAlreadyAdded == lightDevice.isAlreadyAdded)
            #expect(receivedLight.commandTopic == lightDevice.commandTopic)
            #expect(receivedLight.stateTopic == lightDevice.stateTopic)

            let receivedTemp = deviceBatch[1]
            #expect(receivedTemp.id == tempDevice.id)
            #expect(receivedTemp.unitOfMeasurement == tempDevice
                .unitOfMeasurement
            )
            #expect(receivedTemp.supportsBrightness == tempDevice
                .supportsBrightness
            )
            #expect(receivedTemp.isAlreadyAdded == tempDevice.isAlreadyAdded)
            break
        }
    }

    // MARK: - Error Cases

    @Test("Execute when repository throws error should propagate error")
    func executeWhenRepositoryThrowsError() async {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = MockError.discoveryFailure
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When/Then
        await #expect(throws: MockError.discoveryFailure) {
            try await sut.execute()
        }
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 1)
    }

    @Test("Execute when repository throws mqtt error should propagate error")
    func executeWhenRepositoryThrowsMQTTError() async {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = MockError.mqttError
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When/Then
        await #expect(throws: MockError.mqttError) {
            try await sut.execute()
        }
    }

    // MARK: - Repository Interaction Tests

    @Test("Execute should call repository exactly once")
    func executeShouldCallRepositoryExactlyOnce() async throws {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[DiscoveredDevice.mockNew1]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        _ = try await sut.execute()

        // Then
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 1)
        #expect(mockRepository.getDiscoveredDevicesCallCount == 0)
    }

    @Test("Execute multiple subscriptions should call repository each time")
    func executeMultipleSubscriptionsShouldCallRepositoryEachTime(
    ) async throws {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[DiscoveredDevice.mockNew1]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        _ = try await sut.execute()
        _ = try await sut.execute()

        // Then
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 2)
    }

    @Test("Execute should not call other repository methods")
    func executeShouldNotCallOtherRepositoryMethods() async throws {
        // Given
        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[DiscoveredDevice.mockNew2]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        _ = try await sut.execute()

        // Then
        #expect(mockRepository.subscribeToDiscoveredDevicesCallCount == 1)
        #expect(mockRepository.getDiscoveredDevicesCallCount == 0)
    }

    // MARK: - AsyncStream Behavior Tests

    @Test("Execute should return functional AsyncStream")
    func executeShouldReturnFunctionalAsyncStream() async throws {
        // Given
        let device1 = DiscoveredDevice(
            id: "functional_device_1",
            name: "Functional Device 1",
            type: .smartLight,
            manufacturer: "Test Co",
            model: "F1",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: "home/functional1/set",
            stateTopic: "home/functional1/state"
        )
        let device2 = DiscoveredDevice(
            id: "functional_device_2",
            name: "Functional Device 2",
            type: .temperatureSensor,
            manufacturer: "Test Inc",
            model: "F2",
            unitOfMeasurement: "°F",
            supportsBrightness: false,
            discoveredAt: Date(),
            isAlreadyAdded: true,
            commandTopic: "home/functional2/set",
            stateTopic: "home/functional2/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[device1], [device2]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then - Test async iteration
        var receivedBatches: [[DiscoveredDevice]] = []
        for await deviceBatch in stream {
            receivedBatches.append(deviceBatch)
            if receivedBatches.count >= 2 {
                break
            }
        }

        #expect(receivedBatches.count == 2)
        #expect(receivedBatches[0][0].id == device1.id)
        #expect(receivedBatches[1][0].id == device2.id)
    }

    // MARK: - Device Discovery Patterns Tests

    @Test(
        "Execute with devices already added should preserve isAlreadyAdded flag"
    )
    func executeWithDevicesAlreadyAdded() async throws {
        // Given
        let newDevice = DiscoveredDevice(
            id: "new_device",
            name: "New Device",
            type: .smartLight,
            manufacturer: "New Co",
            model: "N123",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: "home/new/set",
            stateTopic: "home/new/state"
        )
        let existingDevice = DiscoveredDevice(
            id: "existing_device",
            name: "Existing Device",
            type: .temperatureSensor,
            manufacturer: "Existing Inc",
            model: "E456",
            supportsBrightness: false,
            discoveredAt: Date(),
            isAlreadyAdded: true,
            commandTopic: "home/existing/set",
            stateTopic: "home/existing/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[newDevice, existingDevice]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then
        for await deviceBatch in stream {
            let newDeviceReceived = deviceBatch.first { $0.id == newDevice.id }
            let existingDeviceReceived = deviceBatch
                .first { $0.id == existingDevice.id }

            #expect(newDeviceReceived?.isAlreadyAdded == false)
            #expect(existingDeviceReceived?.isAlreadyAdded == true)
            break
        }
    }

    @Test(
        "Execute with devices with special topic formats should handle correctly"
    )
    func executeWithSpecialTopicFormats() async throws {
        // Given
        let deviceWithSpecialTopics = DiscoveredDevice(
            id: "special_topics_device",
            name: "Special Topics Device",
            type: .smartLight,
            manufacturer: "Special Co",
            model: "ST789",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: "home/device-with_special.chars@123/set",
            stateTopic: "home/device-with_special.chars@123/state"
        )

        let mockRepository = MockDeviceDiscoveryRepository()
        mockRepository.discoveredDevices = [[deviceWithSpecialTopics]]
        let sut = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: mockRepository
        )

        // When
        let stream = try await sut.execute()

        // Then
        for await deviceBatch in stream {
            let receivedDevice = deviceBatch[0]
            #expect(receivedDevice
                .commandTopic == "home/device-with_special.chars@123/set"
            )
            #expect(receivedDevice
                .stateTopic == "home/device-with_special.chars@123/state"
            )
            break
        }
    }
}

// MARK: - Mock Repository

private final class MockDeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    var subscribeToDiscoveredDevicesCallCount = 0
    var getDiscoveredDevicesCallCount = 0
    var discoveredDevices: [[DiscoveredDevice]] = []
    var shouldThrowError = false
    var errorToThrow: Error = MockError.discoveryFailure

    func subscribeToDiscoveredDevices() async throws
        -> AsyncStream<[DiscoveredDevice]> {
        subscribeToDiscoveredDevicesCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }

        return AsyncStream { continuation in
            for deviceBatch in discoveredDevices {
                continuation.yield(deviceBatch)
            }
            continuation.finish()
        }
    }

    func getDiscoveredDevices() async throws -> [DiscoveredDevice] {
        getDiscoveredDevicesCallCount += 1
        // Not needed for SubscribeToDiscoveredDevicesUseCase tests
        return discoveredDevices.flatMap(\.self)
    }
}

// MARK: - Mock Error

private enum MockError: Error, Equatable {
    case discoveryFailure
    case mqttError
    case deviceNotFound
}
