import Entities
import Foundation
import OSLog
import RepositoryProtocols
import ServiceProtocols
@testable import Stores
import Testing
import UseCases

@Suite("DeviceStore Tests")
struct DeviceStoreTests {
    @MainActor
    @Test("Initial state should be loading")
    func initialState() {
        let store = createDeviceStore()

        #expect(store.viewState == .loading)
        #expect(store.devices.isEmpty)
        #expect(store.discoveredDevices.isEmpty)
        #expect(store.selectedDevice == nil)
        #expect(store.selectedDeviceState == nil)
    }

    @MainActor
    @Test("Load dashboard data with devices should set loaded state")
    func loadDashboardDataWithDevices() async throws {
        let mockDevices = [Device.mockLight, Device.mockTemperatureSensor]
        let store = createDeviceStore(managedDevices: mockDevices)

        store.loadDashboardData()

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.viewState == .loaded)
        #expect(store.devices.count == 2)
        #expect(store.devices[0].id == Device.mockLight.id)
        #expect(store.devices[1].id == Device.mockTemperatureSensor.id)
    }

    @MainActor
    @Test("Load dashboard data with no devices should set empty state")
    func loadDashboardDataEmpty() async throws {
        let store = createDeviceStore(managedDevices: [], discoveredDevices: [])

        store.loadDashboardData()

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.viewState == .empty)
        #expect(store.devices.isEmpty)
        #expect(store.discoveredDevices.isEmpty)
    }

    @MainActor
    @Test("Load dashboard data with error should set error state")
    func loadDashboardDataError() async throws {
        let store = createDeviceStore(shouldThrowError: true)

        store.loadDashboardData()

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        if case let .error(appError) = store.viewState {
            // The error message should contain our mock error description
            let errorMessage = appError.errorDescription ?? ""
            #expect(errorMessage.contains("Mock error occurred during testing"))
        } else {
            Issue.record("Expected error state, but got: \(store.viewState)")
        }
    }

    @MainActor
    @Test("Select device should update selected device")
    func testSelectDevice() async throws {
        let mockDevices = [Device.mockLight]
        let store = createDeviceStore(managedDevices: mockDevices)

        store.loadDashboardData()
        try await Task.sleep(for: .milliseconds(100))

        let device = Device.mockLight
        store.selectDevice(device)

        #expect(store.selectedDevice?.id == device.id)
    }

    @MainActor
    @Test("Clear selection should reset selected device")
    func testClearSelection() async throws {
        let store = createDeviceStore(managedDevices: [Device.mockLight])
        store.selectDevice(Device.mockLight)

        #expect(store.selectedDevice != nil)

        store.clearSelection()

        #expect(store.selectedDevice == nil)
    }

    @MainActor
    @Test("Subscribe to device should add device to managed list")
    func testSubscribeToDevice() async throws {
        let discoveredDevice = DiscoveredDevice.mockNew1
        let store = createDeviceStore()

        store.subscribeToDevice(discoveredDevice)

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.devices.count == 1)
        #expect(store.devices[0].id == discoveredDevice.id)
    }

    @MainActor
    @Test("Unsubscribe from device should remove device from managed list")
    func testUnsubscribeFromDevice() async throws {
        let mockDevices = [Device.mockLight]
        let store = createDeviceStore(managedDevices: mockDevices)

        store.loadDashboardData()
        try await Task.sleep(for: .milliseconds(100))

        store.unsubscribeFromDevice(withId: Device.mockLight.id)
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.devices.isEmpty)
    }

    @MainActor
    @Test("Selected device state should return nil when no state available")
    func testSelectedDeviceState() async throws {
        let mockDevice = Device.mockLight
        let store = createDeviceStore(managedDevices: [mockDevice])

        store.loadDashboardData()
        try await Task.sleep(for: .milliseconds(100))

        store.selectDevice(mockDevice)

        // selectedDeviceState will be nil since no device states are populated
        // through the mock state repository
        #expect(store.selectedDeviceState == nil)
    }

    @MainActor
    @Test("Load dashboard data with discovered devices should set loaded state")
    func loadDashboardDataWithDiscoveredDevices() async throws {
        let discoveredDevices = [
            DiscoveredDevice.mockNew1,
            DiscoveredDevice.mockNew2
        ]
        let store = createDeviceStore(
            managedDevices: [],
            discoveredDevices: discoveredDevices
        )

        store.loadDashboardData()

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        #expect(store.viewState == .loaded)
        #expect(store.devices.isEmpty) // No managed devices
        #expect(store.discoveredDevices.count == 2)
    }
}

// MARK: - Test Helpers

// TODO: Attempt to reuse DeviceStore+Preview

@MainActor
private func createDeviceStore(
    managedDevices: [Device] = [],
    discoveredDevices: [DiscoveredDevice] = [],
    shouldThrowError: Bool = false
) -> DeviceStore {
    let connectionRepo = MockDeviceConnectionRepository(
        devices: managedDevices,
        shouldThrowError: shouldThrowError
    )
    let discoveryRepo =
        MockDeviceDiscoveryRepository(devices: discoveredDevices)
    let stateRepo = MockDeviceStateRepository()
    let commandRepo = MockDeviceCommandRepository()
    let mqttManager = MockMQTTConnectionManager()
    let logger = MockLogger()

    return DeviceStore(
        getManagedDevicesUseCase: GetManagedDevicesUseCase(
            deviceConnectionRepository: connectionRepo
        ),
        getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: discoveryRepo
        ),
        subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase(
            deviceStateRepository: stateRepo
        ),
        subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: discoveryRepo
        ),
        addDeviceUseCase: AddDeviceUseCase(
            deviceConnectionRepository: connectionRepo
        ),
        removeDeviceUseCase: RemoveDeviceUseCase(
            deviceConnectionRepository: connectionRepo,
            mqttConnectionManager: mqttManager
        ),
        sendDeviceCommandUseCase: SendDeviceCommandUseCase(
            deviceCommandRepository: commandRepo
        ),
        logger: logger
    )
}

// MARK: - Mock Classes

private final class MockDeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    private let devices: [Device]
    private let shouldThrowError: Bool

    init(devices: [Device] = [], shouldThrowError: Bool = false) {
        self.devices = devices
        self.shouldThrowError = shouldThrowError
    }

    func addDevice(_ discoveredDevice: DiscoveredDevice) async throws
        -> Device {
        if shouldThrowError {
            throw MockError.testError
        }
        return Device(
            id: discoveredDevice.id,
            name: discoveredDevice.name,
            type: discoveredDevice.type,
            manufacturer: discoveredDevice.manufacturer,
            model: discoveredDevice.model,
            unitOfMeasurement: discoveredDevice.unitOfMeasurement,
            supportsBrightness: discoveredDevice.supportsBrightness,
            isManaged: true,
            addedDate: Date(),
            lastSeen: Date(),
            status: .connected,
            commandTopic: discoveredDevice.commandTopic,
            stateTopic: discoveredDevice.stateTopic
        )
    }

    func removeDevice(deviceId _: String) async throws {
        if shouldThrowError {
            throw MockError.testError
        }
    }

    func getManagedDevices() async throws -> [Device] {
        if shouldThrowError {
            throw MockError.testError
        }
        return devices
    }
}

private final class MockDeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    private let devices: [DiscoveredDevice]

    init(devices: [DiscoveredDevice] = []) {
        self.devices = devices
    }

    func getDiscoveredDevices() async throws -> [DiscoveredDevice] {
        devices
    }

    @available(macOS 10.15, iOS 13, *)
    func subscribeToDiscoveredDevices() async throws
        -> AsyncStream<[DiscoveredDevice]> {
        AsyncStream { continuation in
            continuation.yield(devices)
            continuation.finish()
        }
    }
}

private final class MockDeviceStateRepository: DeviceStateRepositoryProtocol {
    func getDeviceState(deviceId _: String) async throws -> DeviceState? {
        nil
    }

    @available(macOS 10.15, iOS 13, *)
    func subscribeToDeviceState(stateTopic _: String) async throws
        -> AsyncStream<DeviceState> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private final class MockDeviceCommandRepository: DeviceCommandRepositoryProtocol {
    func sendDeviceCommand(
        deviceId _: String,
        command _: Command
    ) async throws {}
}

private final class MockMQTTConnectionManager: MQTTConnectionManagerProtocol {
    var connectionStatus: MQTTConnectionStatus = .connected

    func connect() async throws {}
    func disconnect() {}
    func subscribe(
        to _: String,
        handler _: @escaping @Sendable (MQTTMessage) -> Void
    ) {}
    func unsubscribe(from _: String) {}
    func publish(topic _: String, payload _: String) async throws {}
}

private final class MockLogger: LoggerProtocol {
    func log(_: String, level _: OSLogType) {}
}

private enum MockError: Error, LocalizedError {
    case testError

    var errorDescription: String? {
        "Mock error occurred during testing"
    }

    var localizedDescription: String {
        errorDescription ?? "Unknown mock error"
    }
}
