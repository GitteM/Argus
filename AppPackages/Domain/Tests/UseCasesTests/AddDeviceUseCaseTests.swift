import Entities
import Foundation
import RepositoryProtocols
import Testing
@testable import UseCases

@Suite("AddDeviceUseCase Tests")
struct AddDeviceUseCaseTests {
    // MARK: - Success Cases

    @Test("Execute with valid discovered device should return device")
    func executeWithValidDiscoveredDevice() async throws {
        // Given
        let discoveredDevice = DiscoveredDevice.mockNew1
        let expectedDevice = Device.mockLight
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.addDeviceResult = .success(expectedDevice)
        let sut = AddDeviceUseCase(deviceConnectionRepository: mockRepository)

        // When
        let result = try await sut.execute(discoveredDevice: discoveredDevice)

        // Then
        #expect(result.id == expectedDevice.id)
        #expect(result.name == expectedDevice.name)
        #expect(result.type == expectedDevice.type)
        #expect(mockRepository.addDeviceCallCount == 1)
        #expect(mockRepository.lastDiscoveredDevice?.id == discoveredDevice.id)
    }

    @Test("Execute with temperature sensor should return device")
    func executeWithTemperatureSensor() async throws {
        // Given
        let discoveredDevice = DiscoveredDevice.mockNew2
        let expectedDevice = Device.mockTemperatureSensor
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.addDeviceResult = .success(expectedDevice)
        let sut = AddDeviceUseCase(deviceConnectionRepository: mockRepository)

        // When
        let result = try await sut.execute(discoveredDevice: discoveredDevice)

        // Then
        #expect(result.id == expectedDevice.id)
        #expect(result.name == expectedDevice.name)
        #expect(result.type == .temperatureSensor)
        #expect(result.unitOfMeasurement == "C")
        #expect(mockRepository.addDeviceCallCount == 1)
    }

    // MARK: - Error Cases

    @Test("Execute when repository throws error should propagate error")
    func executeWhenRepositoryThrowsError() async {
        // Given
        let discoveredDevice = DiscoveredDevice.mockNew1
        let expectedError = AppError.TestFactory.repositoryError
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.addDeviceResult = .failure(expectedError)
        let sut = AddDeviceUseCase(deviceConnectionRepository: mockRepository)

        // When/Then
        await #expect(throws: AppError.TestFactory.repositoryError) {
            try await sut.execute(discoveredDevice: discoveredDevice)
        }
        #expect(mockRepository.addDeviceCallCount == 1)
    }

    @Test("Execute when device already exists should throw error")
    func executeWhenDeviceAlreadyExists() async {
        // Given
        let discoveredDevice = DiscoveredDevice.mockNew1
        let expectedError = AppError.TestFactory.deviceAlreadyExists
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.addDeviceResult = .failure(expectedError)
        let sut = AddDeviceUseCase(deviceConnectionRepository: mockRepository)

        // When/Then
        await #expect(throws: AppError.TestFactory.deviceAlreadyExists) {
            try await sut.execute(discoveredDevice: discoveredDevice)
        }
    }

    // MARK: - Repository Interaction Tests

    @Test("Execute should call repository with correct parameters")
    func executeShouldCallRepositoryWithCorrectParameters() async throws {
        // Given
        let discoveredDevice = DiscoveredDevice(
            id: "test_device",
            name: "Test Device",
            type: .smartLight,
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            supportsBrightness: true,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: "test/command",
            stateTopic: "test/state"
        )
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.addDeviceResult = .success(Device.mockLight)
        let sut = AddDeviceUseCase(deviceConnectionRepository: mockRepository)

        // When
        _ = try await sut.execute(discoveredDevice: discoveredDevice)

        // Then
        #expect(mockRepository.addDeviceCallCount == 1)
        #expect(mockRepository.lastDiscoveredDevice?.id == "test_device")
        #expect(mockRepository.lastDiscoveredDevice?.name == "Test Device")
        #expect(mockRepository.lastDiscoveredDevice?
            .manufacturer == "Test Manufacturer"
        )
        #expect(mockRepository.lastDiscoveredDevice?.model == "Test Model")
        #expect(mockRepository.lastDiscoveredDevice?
            .commandTopic == "test/command"
        )
        #expect(mockRepository.lastDiscoveredDevice?.stateTopic == "test/state")
    }

    @Test("Execute multiple invocations should call repository each time")
    func executeMultipleInvocations() async throws {
        // Given
        let device1 = DiscoveredDevice.mockNew1
        let device2 = DiscoveredDevice.mockNew2
        let mockRepository = MockDeviceConnectionRepository()
        mockRepository.addDeviceResult = .success(Device.mockLight)
        let sut = AddDeviceUseCase(deviceConnectionRepository: mockRepository)

        // When
        _ = try await sut.execute(discoveredDevice: device1)
        _ = try await sut.execute(discoveredDevice: device2)

        // Then
        #expect(mockRepository.addDeviceCallCount == 2)
        #expect(mockRepository.lastDiscoveredDevice?.id == device2.id)
    }
}

// MARK: - Mock Repository

private final class MockDeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    var addDeviceCallCount = 0
    var lastDiscoveredDevice: DiscoveredDevice?
    var addDeviceResult: Result<Device, Error> = .success(Device.mockLight)

    func addDevice(_ discoveredDevice: DiscoveredDevice) async throws
        -> Device {
        addDeviceCallCount += 1
        lastDiscoveredDevice = discoveredDevice

        switch addDeviceResult {
        case let .success(device):
            return device
        case let .failure(error):
            throw error
        }
    }

    func removeDevice(deviceId _: String) async throws {
        // Not needed for AddDeviceUseCase tests
    }

    func getManagedDevices() async throws -> [Device] {
        // Not needed for AddDeviceUseCase tests
        []
    }
}
