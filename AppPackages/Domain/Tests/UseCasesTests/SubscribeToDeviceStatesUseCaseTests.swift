import Entities
import Foundation
import RepositoryProtocols
import Testing
@testable import UseCases

@Suite("SubscribeToDeviceStatesUseCase Tests")
struct SubscribeToDeviceStatesUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute with valid state topic should return AsyncStream")
    func executeWithValidStateTopic() async throws {
        // Given
        let stateTopic = "home/device/test/state"
        let mockDeviceState = DeviceState.mockTemperature
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [mockDeviceState]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
        #expect(mockRepository.lastStateTopic == stateTopic)

        // Verify stream yields expected state
        var receivedStates: [DeviceState] = []
        for await state in stream {
            receivedStates.append(state)
            if receivedStates.count >= 1 {
                break // Exit after receiving first state
            }
        }

        #expect(receivedStates.count == 1)
        #expect(receivedStates[0].deviceId == mockDeviceState.deviceId)
        #expect(receivedStates[0].deviceType == mockDeviceState.deviceType)
    }

    @Test("Execute with light device state topic should handle correctly")
    func executeWithLightDeviceStateTopic() async throws {
        // Given
        let stateTopic = "home/light/bedroom/state"
        let mockLightState = DeviceState.mockLight
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [mockLightState]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
        #expect(mockRepository.lastStateTopic == "home/light/bedroom/state")

        // Verify stream content
        var receivedStates: [DeviceState] = []
        for await state in stream {
            receivedStates.append(state)
            break
        }

        #expect(receivedStates[0].deviceType == .smartLight)
        #expect(receivedStates[0].lightState != nil)
    }

    @Test("Execute with multiple device states should stream all states")
    func executeWithMultipleDeviceStates() async throws {
        // Given
        let stateTopic = "home/device/multi/state"
        let temperatureState = DeviceState.mockTemperature
        let lightState = DeviceState.mockLight
        let customState = DeviceState(
            deviceId: "custom_device",
            deviceType: .smartLight,
            isOnline: false,
            lastUpdate: Date(),
            payload: "custom_payload",
            temperatureSensor: nil,
            lightState: nil
        )

        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [
            temperatureState,
            lightState,
            customState
        ]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then
        var receivedStates: [DeviceState] = []
        for await state in stream {
            receivedStates.append(state)
            if receivedStates.count >= 3 {
                break
            }
        }

        #expect(receivedStates.count == 3)
        #expect(receivedStates
            .contains { $0.deviceId == temperatureState.deviceId }
        )
        #expect(receivedStates.contains { $0.deviceId == lightState.deviceId })
        #expect(receivedStates.contains { $0.deviceId == customState.deviceId })
    }

    @Test("Execute with empty state stream should handle gracefully")
    func executeWithEmptyStateStream() async throws {
        // Given
        let stateTopic = "home/device/empty/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [] // Empty states
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)

        // Verify stream completes without yielding values
        var receivedStates: [DeviceState] = []
        for await state in stream {
            receivedStates.append(state)
        }

        #expect(receivedStates.isEmpty)
    }

    // MARK: - Error Cases

    @Test("Execute when repository throws error should propagate error")
    func executeWhenRepositoryThrowsError() async {
        // Given
        let stateTopic = "home/device/error/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = TestError.subscriptionFailure
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When/Then
        await #expect(throws: TestError.subscriptionFailure) {
            try await sut.execute(stateTopic: stateTopic)
        }
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
    }

    @Test("Execute when repository throws mqtt error should propagate error")
    func executeWhenRepositoryThrowsMQTTError() async {
        // Given
        let stateTopic = "home/device/mqtt_error/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = TestError.mqttError
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When/Then
        await #expect(throws: TestError.mqttError) {
            try await sut.execute(stateTopic: stateTopic)
        }
    }

    @Test(
        "Execute when repository throws invalid topic error should propagate error"
    )
    func executeWhenRepositoryThrowsInvalidTopicError() async {
        // Given
        let stateTopic = "invalid/topic/format"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = TestError.invalidTopic
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When/Then
        await #expect(throws: TestError.invalidTopic) {
            try await sut.execute(stateTopic: stateTopic)
        }
    }

    // MARK: - Repository Interaction Tests

    @Test("Execute should call repository with exact state topic")
    func executeShouldCallRepositoryWithExactStateTopic() async throws {
        // Given
        let stateTopic = "home/sensor/temperature/living_room/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [DeviceState.mockTemperature]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        _ = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
        #expect(mockRepository
            .lastStateTopic == "home/sensor/temperature/living_room/state"
        )
    }

    @Test("Execute multiple subscriptions should call repository each time")
    func executeMultipleSubscriptionsShouldCallRepositoryEachTime(
    ) async throws {
        // Given
        let stateTopic1 = "home/device/1/state"
        let stateTopic2 = "home/device/2/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [DeviceState.mockLight]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        _ = try await sut.execute(stateTopic: stateTopic1)
        _ = try await sut.execute(stateTopic: stateTopic2)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 2)
        #expect(mockRepository.lastStateTopic == stateTopic2)
    }

    @Test("Execute should not call other repository methods")
    func executeShouldNotCallOtherRepositoryMethods() async throws {
        // Given
        let stateTopic = "home/device/isolated/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [DeviceState.mockTemperature]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        _ = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
        #expect(mockRepository.getDeviceStateCallCount == 0)
    }

    // MARK: - State Topic Validation Tests

    @Test(
        "Execute with special characters in state topic should handle correctly"
    )
    func executeWithSpecialCharactersInStateTopic() async throws {
        // Given
        let stateTopic = "home/device-with_special.chars@123/state"
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [DeviceState.mockLight]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
        #expect(mockRepository
            .lastStateTopic == "home/device-with_special.chars@123/state"
        )

        // Verify stream works with special characters
        var receivedCount = 0
        for await _ in stream {
            receivedCount += 1
            break
        }
        #expect(receivedCount == 1)
    }

    @Test("Execute with empty state topic should still call repository")
    func executeWithEmptyStateTopic() async throws {
        // Given
        let stateTopic = ""
        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = []
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        _ = try await sut.execute(stateTopic: stateTopic)

        // Then
        #expect(mockRepository.subscribeToDeviceStateCallCount == 1)
        #expect(mockRepository.lastStateTopic == "")
    }

    // MARK: - AsyncStream Behavior Tests

    @Test("Execute should return functional AsyncStream")
    func executeShouldReturnFunctionalAsyncStream() async throws {
        // Given
        let stateTopic = "home/device/functional/state"
        let deviceState1 = DeviceState(
            deviceId: "device_1",
            deviceType: .smartLight,
            isOnline: true,
            lastUpdate: Date(),
            payload: "state_1",
            temperatureSensor: nil,
            lightState: nil
        )
        let deviceState2 = DeviceState(
            deviceId: "device_2",
            deviceType: .temperatureSensor,
            isOnline: false,
            lastUpdate: Date(),
            payload: "state_2",
            temperatureSensor: nil,
            lightState: nil
        )

        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [deviceState1, deviceState2]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then - Test async iteration
        var receivedStates: [DeviceState] = []
        for await state in stream {
            receivedStates.append(state)
            if receivedStates.count >= 2 {
                break
            }
        }

        #expect(receivedStates.count == 2)
        #expect(receivedStates[0].deviceId == deviceState1.deviceId)
        #expect(receivedStates[1].deviceId == deviceState2.deviceId)
    }

    @Test("Execute stream should preserve device state properties")
    func executeStreamShouldPreserveDeviceStateProperties() async throws {
        // Given
        let stateTopic = "home/device/properties/state"
        let originalState = DeviceState(
            deviceId: "property_test_device",
            deviceType: .temperatureSensor,
            isOnline: true,
            lastUpdate: Date(timeIntervalSince1970: 1_609_459_200),
            // Fixed date
            payload: "temperature:22.5°C",
            temperatureSensor: TemperatureSensor(
                temperature: 22.5,
                date: Date(timeIntervalSince1970: 1_609_459_200),
                battery: 85
            ),
            lightState: nil
        )

        let mockRepository = MockDeviceStateRepository()
        mockRepository.deviceStates = [originalState]
        let sut =
            SubscribeToDeviceStatesUseCase(deviceStateRepository: mockRepository
            )

        // When
        let stream = try await sut.execute(stateTopic: stateTopic)

        // Then - Verify all properties are preserved
        for await receivedState in stream {
            #expect(receivedState.deviceId == originalState.deviceId)
            #expect(receivedState.deviceType == originalState.deviceType)
            #expect(receivedState.isOnline == originalState.isOnline)
            #expect(receivedState.lastUpdate == originalState.lastUpdate)
            #expect(receivedState.payload == originalState.payload)
            #expect(receivedState.temperatureSensor?
                .temperature == originalState.temperatureSensor?.temperature
            )
            #expect(receivedState.temperatureSensor?.date == originalState
                .temperatureSensor?.date
            )
            #expect(receivedState.temperatureSensor?.battery == originalState
                .temperatureSensor?.battery
            )
            #expect(receivedState.lightState?.state == originalState.lightState?
                .state
            )
            #expect(receivedState.lightState?.brightness == originalState
                .lightState?.brightness
            )
            break
        }
    }
}

// MARK: - Mock Repository

private final class MockDeviceStateRepository: DeviceStateRepositoryProtocol {
    var subscribeToDeviceStateCallCount = 0
    var getDeviceStateCallCount = 0
    var lastStateTopic: String?
    var deviceStates: [DeviceState] = []
    var shouldThrowError = false
    var errorToThrow: Error = TestError.subscriptionFailure

    func subscribeToDeviceState(stateTopic: String) async throws
        -> AsyncStream<DeviceState> {
        subscribeToDeviceStateCallCount += 1
        lastStateTopic = stateTopic

        if shouldThrowError {
            throw errorToThrow
        }

        return AsyncStream { continuation in
            for state in deviceStates {
                continuation.yield(state)
            }
            continuation.finish()
        }
    }

    func getDeviceState(deviceId: String) async throws -> DeviceState? {
        getDeviceStateCallCount += 1
        // Not needed for SubscribeToDeviceStatesUseCase tests
        return deviceStates.first { $0.deviceId == deviceId }
    }
}
