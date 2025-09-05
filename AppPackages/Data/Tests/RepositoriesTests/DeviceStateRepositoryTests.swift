import DataSource
import Entities
import Foundation
@testable import Repositories
import Testing

// MARK: - DeviceStateRepository Tests

@Test("DeviceStateRepository gets device state successfully")
func getDeviceStateSuccess() async throws {
    // Given
    let mockDataSource = MockDeviceStateDataSource()
    let repository =
        DeviceStateRepository(deviceStateDataSource: mockDataSource)
    let expectedDeviceState = createMockDeviceState(deviceId: "test-device")

    mockDataSource.stubbedGetResult = .success(expectedDeviceState)

    // When
    let result = await repository.getDeviceState(deviceId: "test-device")

    // Then
    switch result {
    case let .success(deviceState):
        #expect(deviceState?.deviceId == "test-device")
        #expect(deviceState?.isOnline == true)
        #expect(mockDataSource.getDeviceStateCallCount == 1)
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceStateRepository handles validation error for empty device ID")
func getDeviceStateValidationError() async throws {
    // Given
    let mockDataSource = MockDeviceStateDataSource()
    let repository =
        DeviceStateRepository(deviceStateDataSource: mockDataSource)

    mockDataSource.stubbedGetResult = .failure(.validationError(
        field: "deviceId",
        reason: "Device ID cannot be empty"
    ))

    // When
    let result = await repository.getDeviceState(deviceId: "")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .validationError(field, reason) = error {
            #expect(field == "deviceId")
            #expect(reason == "Device ID cannot be empty")
        } else {
            Issue.record("Expected validationError but got: \(error)")
        }
    }
}

@Test("DeviceStateRepository returns nil for non-existent device")
func getDeviceStateNotFound() async throws {
    // Given
    let mockDataSource = MockDeviceStateDataSource()
    let repository =
        DeviceStateRepository(deviceStateDataSource: mockDataSource)

    mockDataSource.stubbedGetResult = .success(nil)

    // When
    let result = await repository
        .getDeviceState(deviceId: "non-existent-device")

    // Then
    switch result {
    case let .success(deviceState):
        #expect(deviceState == nil)
    case let .failure(error):
        Issue.record("Expected success with nil but got error: \(error)")
    }
}

@Test("DeviceStateRepository subscribes to device state successfully")
@available(macOS 10.15, iOS 13, *)
func subscribeToDeviceStateSuccess() async throws {
    // Given
    let mockDataSource = MockDeviceStateDataSource()
    let repository =
        DeviceStateRepository(deviceStateDataSource: mockDataSource)
    let mockStream = AsyncStream<DeviceState> { _ in }

    mockDataSource.stubbedSubscribeResult = .success(mockStream)

    // When
    let result = await repository
        .subscribeToDeviceState(stateTopic: "home/sensor/test-device")

    // Then
    switch result {
    case .success:
        #expect(mockDataSource.subscribeToDeviceStateCallCount == 1)
        #expect(mockDataSource.lastStateTopic == "home/sensor/test-device")
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceStateRepository handles validation error for empty state topic")
@available(macOS 10.15, iOS 13, *)
func subscribeToDeviceStateValidationError() async throws {
    // Given
    let mockDataSource = MockDeviceStateDataSource()
    let repository =
        DeviceStateRepository(deviceStateDataSource: mockDataSource)

    mockDataSource.stubbedSubscribeResult = .failure(.validationError(
        field: "stateTopic",
        reason: "State topic cannot be empty"
    ))

    // When
    let result = await repository.subscribeToDeviceState(stateTopic: "")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .validationError(field, reason) = error {
            #expect(field == "stateTopic")
            #expect(reason == "State topic cannot be empty")
        } else {
            Issue.record("Expected validationError but got: \(error)")
        }
    }
}

@Test("DeviceStateRepository handles MQTT subscription failure")
@available(macOS 10.15, iOS 13, *)
func subscribeToDeviceStateMQTTFailure() async throws {
    // Given
    let mockDataSource = MockDeviceStateDataSource()
    let repository =
        DeviceStateRepository(deviceStateDataSource: mockDataSource)

    mockDataSource
        .stubbedSubscribeResult =
        .failure(.mqttSubscriptionFailed(topic: "invalid/topic"))

    // When
    let result = await repository
        .subscribeToDeviceState(stateTopic: "invalid/topic")

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .mqttSubscriptionFailed(topic) = error {
            #expect(topic == "invalid/topic")
        } else {
            Issue.record("Expected mqttSubscriptionFailed but got: \(error)")
        }
    }
}

// MARK: - Mock Objects and Helpers

@available(macOS 10.15, iOS 13, *)
final class MockDeviceStateDataSource: DeviceStateDataSourceProtocol,
    @unchecked Sendable {
    var stubbedGetResult: Result<DeviceState?, AppError> = .success(nil)
    var stubbedSubscribeResult: Result<AsyncStream<DeviceState>, AppError> =
        .success(AsyncStream { _ in })
    var getDeviceStateCallCount = 0
    var subscribeToDeviceStateCallCount = 0
    var lastDeviceId: String?
    var lastStateTopic: String?

    func getDeviceState(deviceId: String) async
        -> Result<DeviceState?, AppError> {
        getDeviceStateCallCount += 1
        lastDeviceId = deviceId
        return stubbedGetResult
    }

    func subscribeToDeviceState(stateTopic: String) async
        -> Result<AsyncStream<DeviceState>, AppError> {
        subscribeToDeviceStateCallCount += 1
        lastStateTopic = stateTopic
        return stubbedSubscribeResult
    }
}

private func createMockDeviceState(deviceId: String) -> DeviceState {
    DeviceState(
        deviceId: deviceId,
        deviceType: .smartLight,
        isOnline: true,
        lastUpdate: Date(),
        payload: "{\"state\":\"ON\"}",
        temperatureSensor: nil,
        lightState: LightState(
            state: true,
            brightness: 100,
            date: Date()
        )
    )
}
