import Entities
import Foundation
import OSLog
import RepositoryProtocols
import ServiceProtocols
import UseCases

// MARK: - Mock Repositories for Preview

private final class MockDeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    private let devices: [Device]
    private let shouldThrowError: Bool
    private let shouldNeverComplete: Bool

    init(
        devices: [Device] = [],
        shouldThrowError: Bool = false,
        shouldNeverComplete: Bool = false
    ) {
        self.devices = devices
        self.shouldThrowError = shouldThrowError
        self.shouldNeverComplete = shouldNeverComplete
    }

    func addDevice(_ discoveredDevice: DiscoveredDevice) async
        -> Result<Device, AppError> {
        let device = Device(
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
        return .success(device)
    }

    func removeDevice(deviceId _: String) async -> Result<Void, AppError> {
        .success(())
    }

    func getManagedDevices() async -> Result<[Device], AppError> {
        if shouldNeverComplete {
            // Suspend indefinitely to simulate loading
            try? await Task.sleep(for: .seconds(3600)) // 1 hour
            return .success(devices) // In case sleep gets cancelled
        }

        // Add a small delay to simulate real network loading
        try? await Task.sleep(for: .milliseconds(500))

        if shouldThrowError {
            return .failure(
                .mqttConnectionFailed("Failed to connect to MQTT broker")
            )
        }
        return .success(devices)
    }
}

private final class MockDeviceDiscoveryRepository: DeviceDiscoveryRepositoryProtocol {
    private let devices: [DiscoveredDevice]

    init(devices: [DiscoveredDevice] = []) {
        self.devices = devices
    }

    func getDiscoveredDevices() async -> Result<[DiscoveredDevice], AppError> {
        // Add a small delay to simulate real network loading
        try? await Task.sleep(for: .milliseconds(300))
        return .success(devices)
    }

    @available(macOS 10.15, iOS 13, *)
    func subscribeToDiscoveredDevices() async
        -> Result<AsyncStream<[DiscoveredDevice]>, AppError> {
        let stream = AsyncStream<[DiscoveredDevice]> { continuation in
            continuation.yield(devices)
            continuation.finish()
        }
        return .success(stream)
    }
}

private final class MockDeviceStateRepository: DeviceStateRepositoryProtocol {
    private let deviceState: DeviceState?

    init(deviceState: DeviceState? = nil) {
        self.deviceState = deviceState
    }

    func getDeviceState(deviceId _: String) async
        -> Result<DeviceState?, AppError> {
        .success(deviceState)
    }

    @available(macOS 10.15, iOS 13, *)
    func subscribeToDeviceState(stateTopic _: String) async
        -> Result<AsyncStream<DeviceState>, AppError> {
        let stream = AsyncStream<DeviceState> { continuation in
            if let deviceState {
                continuation.yield(deviceState)
            }
            continuation.finish()
        }
        return .success(stream)
    }
}

private final class MockDeviceCommandRepository: DeviceCommandRepositoryProtocol {
    func sendDeviceCommand(
        deviceId _: String,
        command _: Command
    ) async -> Result<Void, AppError> {
        .success(())
    }
}

private final class MockLogger: LoggerProtocol {
    func log(_: String, level _: OSLogType) {}
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

// MARK: - DeviceStore Preview Extension

@MainActor
public extension DeviceStore {
    static var preview: DeviceStore {
        let previewDevices = Device.mockDefaults
        let previewDeviceState: DeviceState = .mockLight
        let previewDiscoveredDevices = DiscoveredDevice
            .mockDefaults

        // Create mock repositories
        let connectionRepo =
            MockDeviceConnectionRepository(devices: previewDevices)
        let discoveryRepo = MockDeviceDiscoveryRepository(
            devices: previewDiscoveredDevices
        )
        let stateRepo =
            MockDeviceStateRepository(deviceState: previewDeviceState)
        let commandRepo = MockDeviceCommandRepository()
        let mqttManager = MockMQTTConnectionManager()
        let logger = MockLogger()

        // Create real use cases with mock repositories
        let store = DeviceStore(
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

        return store
    }

    static var emptyPreview: DeviceStore {
        let connectionRepo = MockDeviceConnectionRepository()
        let discoveryRepo = MockDeviceDiscoveryRepository()
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

    static var loadingPreview: DeviceStore {
        // Create a store with repositories that never complete
        let connectionRepo =
            MockDeviceConnectionRepository(shouldNeverComplete: true)
        let discoveryRepo = MockDeviceDiscoveryRepository()
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

    static var errorPreview: DeviceStore {
        let connectionRepo =
            MockDeviceConnectionRepository(shouldThrowError: true)
        let discoveryRepo = MockDeviceDiscoveryRepository()
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
}
