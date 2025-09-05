import Entities
import Foundation
import RepositoryProtocols
import Testing
@testable import UseCases

@Suite("SendDeviceCommandUseCase Tests")
struct SendDeviceCommandUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute with valid device ID and command should send successfully")
    func executeWithValidDeviceIdAndCommand() async throws {
        // Given
        let deviceId = "test_device_123"
        let command = Command(
            type: .unknown,
            payload: "test_payload".data(using: .utf8)!,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastDeviceId == deviceId)
        #expect(await mockRepository.lastCommand?.type == command.type)
        #expect(await mockRepository.lastCommand?.payload == command.payload)
        #expect(await mockRepository.lastCommand?.targetDevice == command
            .targetDevice
        )
    }

    @Test(
        "Execute with different device ID should send command to correct device"
    )
    func executeWithDifferentDeviceId() async throws {
        // Given
        let deviceId = "bedroom_light_456"
        let command = Command(
            type: .unknown,
            payload: "turn_on".data(using: .utf8)!,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastDeviceId == "bedroom_light_456")
        #expect(await mockRepository.lastCommand?.targetDevice == deviceId)
    }

    @Test("Execute with empty payload should still send command")
    func executeWithEmptyPayload() async throws {
        // Given
        let deviceId = "test_device"
        let command = Command(
            type: .unknown,
            payload: Data(),
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastCommand?.payload.isEmpty == true)
    }

    @Test("Execute with large payload should handle correctly")
    func executeWithLargePayload() async throws {
        // Given
        let deviceId = "test_device"
        let largePayload = String(repeating: "data", count: 1000)
            .data(using: .utf8)!
        let command = Command(
            type: .unknown,
            payload: largePayload,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastCommand?.payload == largePayload)
        #expect(await mockRepository.lastCommand?.payload.count == largePayload
            .count
        )
    }

    // MARK: - Error Cases

    @Test("Execute when repository throws error should propagate error")
    func executeWhenRepositoryThrowsError() async {
        // Given
        let deviceId = "test_device"
        let command = Command(
            type: .unknown,
            payload: "test".data(using: .utf8)!,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        await mockRepository.setShouldThrowError(true)
        await mockRepository
            .setErrorToThrow(AppError.TestFactory.commandSendFailure)
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When/Then
        await #expect(throws: AppError.TestFactory.commandSendFailure) {
            try await sut.execute(deviceId: deviceId, command: command)
        }
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
    }

    @Test(
        "Execute when repository throws device not found error should propagate error"
    )
    func executeWhenRepositoryThrowsDeviceNotFoundError() async {
        // Given
        let deviceId = "non_existent_device"
        let command = Command(
            type: .unknown,
            payload: "test".data(using: .utf8)!,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        await mockRepository.setShouldThrowError(true)
        await mockRepository
            .setErrorToThrow(AppError.TestFactory.deviceNotFound)
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When/Then
        await #expect(throws: AppError.TestFactory.deviceNotFound) {
            try await sut.execute(deviceId: deviceId, command: command)
        }
    }

    @Test("Execute when repository throws mqtt error should propagate error")
    func executeWhenRepositoryThrowsMQTTError() async {
        // Given
        let deviceId = "test_device"
        let command = Command(
            type: .unknown,
            payload: "test".data(using: .utf8)!,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        await mockRepository.setShouldThrowError(true)
        await mockRepository.setErrorToThrow(AppError.TestFactory.mqttError)
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When/Then
        await #expect(throws: AppError.TestFactory.mqttError) {
            try await sut.execute(deviceId: deviceId, command: command)
        }
    }

    // MARK: - Repository Interaction Tests

    @Test("Execute should call repository with exact parameters")
    func executeShouldCallRepositoryWithExactParameters() async throws {
        // Given
        let deviceId = "precise_device_id"
        let payload = "specific_command_data".data(using: .utf8)!
        let command = Command(
            type: .unknown,
            payload: payload,
            targetDevice: "target_device"
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastDeviceId == "precise_device_id")
        #expect(await mockRepository.lastCommand?.type == .unknown)
        #expect(await mockRepository.lastCommand?.payload == payload)
        #expect(await mockRepository.lastCommand?
            .targetDevice == "target_device"
        )
    }

    @Test("Execute multiple commands should call repository each time")
    func executeMultipleCommandsShouldCallRepositoryEachTime() async throws {
        // Given
        let deviceId1 = "device_1"
        let deviceId2 = "device_2"
        let command1 = Command(
            type: .unknown,
            payload: "command_1".data(using: .utf8)!,
            targetDevice: deviceId1
        )
        let command2 = Command(
            type: .unknown,
            payload: "command_2".data(using: .utf8)!,
            targetDevice: deviceId2
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId1, command: command1)
        try await sut.execute(deviceId: deviceId2, command: command2)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 2)
        #expect(await mockRepository.lastDeviceId == deviceId2)
        #expect(await mockRepository.lastCommand?.targetDevice == deviceId2)
    }

    @Test("Execute should preserve command data integrity")
    func executeShouldPreserveCommandDataIntegrity() async throws {
        // Given
        let deviceId = "integrity_test_device"
        let originalData = "complex_json_payload{\"brightness\":75,\"color\":\"red\"}"
            .data(using: .utf8)!
        let command = Command(
            type: .unknown,
            payload: originalData,
            targetDevice: "target_123"
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.lastCommand?.payload == originalData)

        // Verify data integrity by converting back to string
        let receivedString = await String(
            data: (mockRepository.lastCommand!).payload,
            encoding: .utf8
        )
        let originalString = String(data: originalData, encoding: .utf8)
        #expect(receivedString == originalString)
    }

    // MARK: - Command Validation Tests

    @Test(
        "Execute with mismatched device ID and command target should still send"
    )
    func executeWithMismatchedDeviceIdAndCommandTarget() async throws {
        // Given
        let deviceId = "actual_device_id"
        let command = Command(
            type: .unknown,
            payload: "test".data(using: .utf8)!,
            targetDevice: "different_target_id"
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastDeviceId == "actual_device_id")
        #expect(await mockRepository.lastCommand?
            .targetDevice == "different_target_id"
        )
    }

    // MARK: - Edge Cases

    @Test("Execute with special characters in device ID should handle correctly"
    )
    func executeWithSpecialCharactersInDeviceId() async throws {
        // Given
        let deviceId = "device-with_special.chars@123"
        let command = Command(
            type: .unknown,
            payload: "test".data(using: .utf8)!,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository
            .lastDeviceId == "device-with_special.chars@123"
        )
    }

    @Test("Execute with binary payload should handle correctly")
    func executeWithBinaryPayload() async throws {
        // Given
        let deviceId = "binary_test_device"
        let binaryData = Data([0x01, 0x02, 0x03, 0xFF, 0xAB, 0xCD, 0xEF])
        let command = Command(
            type: .unknown,
            payload: binaryData,
            targetDevice: deviceId
        )
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        // When
        try await sut.execute(deviceId: deviceId, command: command)

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 1)
        #expect(await mockRepository.lastCommand?.payload == binaryData)
        #expect(await mockRepository.lastCommand?.payload.count == 7)
    }

    @Test("Execute with concurrent commands should handle correctly")
    func executeWithConcurrentCommands() async throws {
        // Given
        let mockRepository = MockDeviceCommandRepository()
        let sut =
            SendDeviceCommandUseCase(deviceCommandRepository: mockRepository)

        let commands = (1 ... 10).map { index in
            (
                deviceId: "device_\(index)",
                command: Command(
                    type: .unknown,
                    payload: "command_\(index)".data(using: .utf8)!,
                    targetDevice: "device_\(index)"
                )
            )
        }

        // When - Execute commands concurrently
        await withTaskGroup(of: Void.self) { group in
            for (deviceId, command) in commands {
                group.addTask {
                    try? await sut.execute(deviceId: deviceId, command: command)
                }
            }
        }

        // Then
        #expect(await mockRepository.sendDeviceCommandCallCount == 10)
    }
}

// MARK: - Mock Repository

private actor MockDeviceCommandRepository: DeviceCommandRepositoryProtocol {
    var sendDeviceCommandCallCount = 0
    var lastDeviceId: String?
    var lastCommand: Command?
    var shouldThrowError = false
    var errorToThrow: Error = AppError.TestFactory.commandSendFailure

    func sendDeviceCommand(deviceId: String, command: Command) async throws {
        sendDeviceCommandCallCount += 1
        lastDeviceId = deviceId
        lastCommand = command

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }

    func setErrorToThrow(_ error: Error) {
        errorToThrow = error
    }
}
