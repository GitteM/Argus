import DataSource
import Entities
import Foundation
@testable import Repositories
import Testing

// MARK: - DeviceCommandRepository Tests

@Test("DeviceCommandRepository sends command successfully")
func sendDeviceCommandSuccess() async throws {
    // Given
    let mockDataSource = MockDeviceCommandDataSource()
    let repository =
        DeviceCommandRepository(deviceCommandDataSource: mockDataSource)
    let command = Command(
        type: .unknown,
        payload: Data(),
        targetDevice: "test-device"
    )

    mockDataSource.stubbedResult = .success(())

    // When
    let result = await repository.sendDeviceCommand(
        deviceId: "test-device",
        command: command
    )

    // Then
    switch result {
    case .success:
        #expect(mockDataSource.sendCommandCallCount == 1)
        #expect(mockDataSource.lastDeviceId == "test-device")
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceCommandRepository handles validation error from data source")
func sendDeviceCommandValidationError() async throws {
    // Given
    let mockDataSource = MockDeviceCommandDataSource()
    let repository =
        DeviceCommandRepository(deviceCommandDataSource: mockDataSource)
    let command = Command(
        type: .unknown,
        payload: Data(),
        targetDevice: "test-device"
    )

    mockDataSource.stubbedResult = .failure(.validationError(
        field: "deviceId",
        reason: "Device ID cannot be empty"
    ))

    // When
    let result = await repository.sendDeviceCommand(
        deviceId: "",
        command: command
    )

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

@Test("DeviceCommandRepository handles MQTT publish failure")
func sendDeviceCommandMQTTFailure() async throws {
    // Given
    let mockDataSource = MockDeviceCommandDataSource()
    let repository =
        DeviceCommandRepository(deviceCommandDataSource: mockDataSource)
    let command = Command(
        type: .unknown,
        payload: Data(),
        targetDevice: "test-device"
    )

    mockDataSource
        .stubbedResult =
        .failure(.mqttPublishFailed(topic: "devices/test-device/commands"))

    // When
    let result = await repository.sendDeviceCommand(
        deviceId: "test-device",
        command: command
    )

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .mqttPublishFailed(topic) = error {
            #expect(topic == "devices/test-device/commands")
        } else {
            Issue.record("Expected mqttPublishFailed but got: \(error)")
        }
    }
}

@Test("DeviceCommandRepository handles serialization failure")
func sendDeviceCommandSerializationError() async throws {
    // Given
    let mockDataSource = MockDeviceCommandDataSource()
    let repository =
        DeviceCommandRepository(deviceCommandDataSource: mockDataSource)
    let command = Command(
        type: .unknown,
        payload: Data(),
        targetDevice: "test-device"
    )

    mockDataSource.stubbedResult = .failure(.serializationError(
        type: "Command",
        details: "Failed to encode command"
    ))

    // When
    let result = await repository.sendDeviceCommand(
        deviceId: "test-device",
        command: command
    )

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .serializationError(type, details) = error {
            #expect(type == "Command")
            #expect(details == "Failed to encode command")
        } else {
            Issue.record("Expected serializationError but got: \(error)")
        }
    }
}

// MARK: - Mock Objects

final class MockDeviceCommandDataSource: DeviceCommandDataSourceProtocol,
    @unchecked Sendable {
    var stubbedResult: Result<Void, AppError> = .success(())
    var sendCommandCallCount = 0
    var lastDeviceId: String?
    var lastCommand: Command?

    func sendDeviceCommand(
        deviceId: String,
        command: Command
    ) async -> Result<Void, AppError> {
        sendCommandCallCount += 1
        lastDeviceId = deviceId
        lastCommand = command
        return stubbedResult
    }
}
