import Entities
import Foundation
import OSLog
import RepositoryProtocols
import ServiceProtocols
import UseCases

// MARK: - Mock Repositories for Preview

private final class MockDeviceConnectionRepository: DeviceConnectionRepositoryProtocol {
    private let devices: [Device]

    init(devices: [Device] = []) {
        self.devices = devices
    }

    func addDevice(_ discoveredDevice: DiscoveredDevice) async throws
        -> Device {
        Device(
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

    func removeDevice(deviceId _: String) async throws {}

    func getManagedDevices() async throws -> [Device] {
        devices
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

    func subscribeToDiscoveredDevices() async throws
        -> AsyncStream<[DiscoveredDevice]> {
        AsyncStream { continuation in
            continuation.yield(devices)
            continuation.finish()
        }
    }
}

private final class MockDeviceStateRepository: DeviceStateRepositoryProtocol {
    private let deviceState: DeviceState?

    init(deviceState: DeviceState? = nil) {
        self.deviceState = deviceState
    }

    func getDeviceState(deviceId _: String) async throws -> DeviceState? {
        deviceState
    }

    func subscribeToDeviceState(stateTopic _: String) async throws
        -> AsyncStream<DeviceState> {
        AsyncStream { continuation in
            if let deviceState {
                continuation.yield(deviceState)
            }
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

private final class MockLogger: LoggerProtocol {
    func log(_: String, level _: OSLogType) {}
}

// MARK: - DeviceStore Preview Extension

@MainActor
public extension DeviceStore {
    static var preview: DeviceStore {
        let previewDevices = Device.mockDefaults

        let previewDeviceState: DeviceState = .mockLight

        // Create mock repositories
        let connectionRepo =
            MockDeviceConnectionRepository(devices: previewDevices)
        let discoveryRepo = MockDeviceDiscoveryRepository()
        let stateRepo =
            MockDeviceStateRepository(deviceState: previewDeviceState)
        let commandRepo = MockDeviceCommandRepository()
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
                deviceConnectionRepository: connectionRepo
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
                deviceConnectionRepository: connectionRepo
            ),
            sendDeviceCommandUseCase: SendDeviceCommandUseCase(
                deviceCommandRepository: commandRepo
            ),
            logger: logger
        )
    }

    static var loadingPreview: DeviceStore {
        let store = emptyPreview
        // The store starts in loading state by default
        return store
    }
}
