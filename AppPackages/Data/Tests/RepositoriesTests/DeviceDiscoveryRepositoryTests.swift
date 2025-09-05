import DataSource
import Entities
import Foundation
@testable import Repositories
import Testing

// MARK: - DeviceDiscoveryRepository Tests

@Test("DeviceDiscoveryRepository gets discovered devices successfully")
func getDiscoveredDevicesSuccess() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)
    let expectedDevices = [
        createMockDiscoveredDevice(id: "device1"),
        createMockDiscoveredDevice(id: "device2")
    ]

    mockDataSource.stubbedGetResult = .success(expectedDevices)

    // When
    let result = await repository.getDiscoveredDevices()

    // Then
    switch result {
    case let .success(devices):
        #expect(devices.count == 2)
        #expect(devices.first?.id == "device1")
        #expect(mockDataSource.getDiscoveredDevicesCallCount == 1)
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test("DeviceDiscoveryRepository handles cache persistence error")
func getDiscoveredDevicesPersistenceError() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)

    mockDataSource.stubbedGetResult = .failure(.persistenceError(
        operation: "get_discovered_devices",
        details: "Failed to retrieve discovered devices from cache"
    ))

    // When
    let result = await repository.getDiscoveredDevices()

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .persistenceError(operation, details) = error {
            #expect(operation == "get_discovered_devices")
            #expect(details?.contains("cache") == true)
        } else {
            Issue.record("Expected persistenceError but got: \(error)")
        }
    }
}

@Test("DeviceDiscoveryRepository returns empty list when no devices discovered")
func getDiscoveredDevicesEmpty() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)

    mockDataSource.stubbedGetResult = .success([])

    // When
    let result = await repository.getDiscoveredDevices()

    // Then
    switch result {
    case let .success(devices):
        #expect(devices.isEmpty)
    case let .failure(error):
        Issue
            .record("Expected success with empty array but got error: \(error)")
    }
}

@Test("DeviceDiscoveryRepository subscribes to device discovery successfully")
@available(macOS 10.15, iOS 13, *)
func subscribeToDiscoveredDevicesSuccess() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)
    let mockStream = AsyncStream<[DiscoveredDevice]> { _ in }

    mockDataSource.stubbedSubscribeResult = .success(mockStream)

    // When
    let result = await repository.subscribeToDiscoveredDevices()

    // Then
    switch result {
    case .success:
        #expect(mockDataSource.subscribeToDeviceDiscoveryCallCount == 1)
    case let .failure(error):
        Issue.record("Expected success but got error: \(error)")
    }
}

@Test(
    "DeviceDiscoveryRepository handles MQTT connection failure during subscription"
)
@available(macOS 10.15, iOS 13, *)
func subscribeToDiscoveredDevicesConnectionFailure() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)

    mockDataSource.stubbedSubscribeResult = .failure(.mqttConnectionFailed(
        "Failed to connect to MQTT broker for device discovery"
    ))

    // When
    let result = await repository.subscribeToDiscoveredDevices()

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .mqttConnectionFailed(details) = error {
            #expect(details?.contains("device discovery") == true)
        } else {
            Issue.record("Expected mqttConnectionFailed but got: \(error)")
        }
    }
}

@Test("DeviceDiscoveryRepository handles discovery timeout")
@available(macOS 10.15, iOS 13, *)
func subscribeToDiscoveredDevicesTimeout() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)

    mockDataSource.stubbedSubscribeResult = .failure(.discoveryTimeout)

    // When
    let result = await repository.subscribeToDiscoveredDevices()

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case .discoveryTimeout = error {
            // Expected error type
        } else {
            Issue.record("Expected discoveryTimeout but got: \(error)")
        }
    }
}

@Test("DeviceDiscoveryRepository handles MQTT subscription failure")
@available(macOS 10.15, iOS 13, *)
func subscribeToDiscoveredDevicesSubscriptionFailure() async throws {
    // Given
    let mockDataSource = MockDeviceDiscoveryDataSource()
    let repository =
        DeviceDiscoveryRepository(deviceDiscoveryDataSource: mockDataSource)

    mockDataSource
        .stubbedSubscribeResult =
        .failure(.mqttSubscriptionFailed(topic: "homeassistant/+/+/config"))

    // When
    let result = await repository.subscribeToDiscoveredDevices()

    // Then
    switch result {
    case .success:
        Issue.record("Expected failure but got success")
    case let .failure(error):
        if case let .mqttSubscriptionFailed(topic) = error {
            #expect(topic == "homeassistant/+/+/config")
        } else {
            Issue.record("Expected mqttSubscriptionFailed but got: \(error)")
        }
    }
}

// MARK: - Mock Objects and Helpers

@available(macOS 10.15, iOS 13, *)
final class MockDeviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol,
    @unchecked Sendable {
    var stubbedGetResult: Result<[DiscoveredDevice], AppError> = .success([])
    var stubbedSubscribeResult: Result<
        AsyncStream<[DiscoveredDevice]>,
        AppError
    > = .success(AsyncStream { _ in })
    var getDiscoveredDevicesCallCount = 0
    var subscribeToDeviceDiscoveryCallCount = 0

    func getDiscoveredDevices() async -> Result<[DiscoveredDevice], AppError> {
        getDiscoveredDevicesCallCount += 1
        return stubbedGetResult
    }

    func subscribeToDeviceDiscovery() async
        -> Result<AsyncStream<[DiscoveredDevice]>, AppError> {
        subscribeToDeviceDiscoveryCallCount += 1
        return stubbedSubscribeResult
    }
}

private func createMockDiscoveredDevice(id: String) -> DiscoveredDevice {
    DiscoveredDevice(
        id: id,
        name: "Test Device \(id)",
        type: .smartLight,
        manufacturer: "Test Manufacturer",
        model: "Test Model",
        unitOfMeasurement: nil,
        supportsBrightness: true,
        discoveredAt: Date(),
        isAlreadyAdded: false,
        commandTopic: "test/\(id)/commands",
        stateTopic: "test/\(id)/state"
    )
}
