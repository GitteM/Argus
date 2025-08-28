import Entities
import Foundation
import Observation
import OSLog
import RepositoryProtocols
import ServiceProtocols
import UseCases

@MainActor
public protocol DeviceStoreProtocol: Observable {
    var viewState: DeviceViewState { get }
    var devices: [Device] { get }
    var discoveredDevices: [DiscoveredDevice] { get }
    var deviceStates: [String: DeviceState] { get }

    var selectedDevice: Device? { get }
    var selectedDeviceState: DeviceState? { get }

    func loadDashboardData()
    func subscribeToDevice(_ device: DiscoveredDevice)
    func unsubscribeFromDevice(withId deviceId: String)
    func sendCommand(to deviceId: String, command: Command)
    func selectDevice(_ device: Device)
    func clearSelection()
}

@MainActor
@Observable
public final class DeviceStore: DeviceStoreProtocol {
    public private(set) var viewState: DeviceViewState
    public private(set) var devices: [Device] = []
    public private(set) var discoveredDevices: [DiscoveredDevice] = []
    public private(set) var deviceStates: [String: DeviceState] = [:]
    public private(set) var selectedDevice: Device?

    public var selectedDeviceState: DeviceState? {
        guard let selectedDevice else { return nil }
        return deviceStates[selectedDevice.id]
    }

    private let getManagedDevicesUseCase: GetManagedDevicesUseCase
    private let getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase
    private let subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase
    private let subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase
    private let addDeviceUseCase: AddDeviceUseCase
    private let removeDeviceUseCase: RemoveDeviceUseCase
    private let sendDeviceCommandUseCase: SendDeviceCommandUseCase
    private let logger: LoggerProtocol

    private var dashboardTask: Task<Void, Never>?
    private var stateSubscriptionTasks: [String: Task<Void, Never>] = [:]
    private var discoverySubscriptionTask: Task<Void, Never>?

    public init(
        getManagedDevicesUseCase: GetManagedDevicesUseCase,
        getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase,
        subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase,
        subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase,
        addDeviceUseCase: AddDeviceUseCase,
        removeDeviceUseCase: RemoveDeviceUseCase,
        sendDeviceCommandUseCase: SendDeviceCommandUseCase,
        logger: LoggerProtocol
    ) {
        self.getManagedDevicesUseCase = getManagedDevicesUseCase
        self.getDiscoveredDevicesUseCase = getDiscoveredDevicesUseCase
        self.subscribeToStatesUseCase = subscribeToStatesUseCase
        self.subscribeToDiscoveredDevicesUseCase =
            subscribeToDiscoveredDevicesUseCase
        self.addDeviceUseCase = addDeviceUseCase
        self.removeDeviceUseCase = removeDeviceUseCase
        self.sendDeviceCommandUseCase = sendDeviceCommandUseCase
        self.logger = logger
        viewState = .loading
    }

    public func loadDashboardData() {
        logger.log("Loading dashboard data", level: .info)
        dashboardTask?.cancel()
        viewState = .loading

        dashboardTask = Task { @MainActor in
            do {
                async let managedDevices = getManagedDevicesUseCase.execute()
                async let discoveredDevices = getDiscoveredDevicesUseCase
                    .execute()

                let (managed, discovered) = try await (
                    managedDevices,
                    discoveredDevices
                )

                guard !Task.isCancelled else {
                    return
                }

                self.devices = managed
                self.discoveredDevices = discovered

                // Start real-time subscriptions to get live updates
                self.startRealtimeUpdates()

                // Set view state based on whether we have any devices
                if managed.isEmpty, discovered.isEmpty {
                    viewState = .empty
                    logger.log(
                        "Dashboard data loaded - no devices loaded yet",
                        level: .info
                    )
                } else {
                    viewState = .loaded
                    logger.log("Dashboard data loaded", level: .info)
                }

            } catch {
                guard let dashboardTask else { return }
                if !dashboardTask.isCancelled {
                    viewState = .error(error.localizedDescription)
                }
            }
        }
    }

    public func startRealtimeUpdates() {
        startDeviceStateSubscription()
        startDiscoverySubscription()
    }

    public func stopRealtimeUpdates() {
        for task in stateSubscriptionTasks.values {
            task.cancel()
        }
        stateSubscriptionTasks.removeAll()
        discoverySubscriptionTask?.cancel()
        discoverySubscriptionTask = nil
    }

    public func subscribeToDevice(_ discoveredDevice: DiscoveredDevice) {
        Task { @MainActor in
            do {
                let device = try await addDeviceUseCase
                    .execute(discoveredDevice: discoveredDevice)
                devices.append(device)
                discoveredDevices.removeAll { $0.id == discoveredDevice.id }

                // Restart state subscription to include new device
                restartDeviceStateSubscription()

                logger.log("Subscribed to device: \(device.name)", level: .info)
            } catch {
                viewState = .error("Failed to subscribe to device")
                let message = "Failed to subscribe to device: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func unsubscribeFromDevice(withId deviceId: String) {
        Task { @MainActor in
            do {
                guard let device = devices.first(where: { $0.id == deviceId })
                else { return }

                try await removeDeviceUseCase.execute(deviceId: device.id)
                devices.removeAll { $0.id == device.id }

                // Convert back to discovered device so it appears in available
                // list
                let discoveredDevice = DiscoveredDevice(
                    id: device.id,
                    name: device.name,
                    type: device.type,
                    manufacturer: device.manufacturer,
                    model: device.model,
                    unitOfMeasurement: device.unitOfMeasurement,
                    supportsBrightness: device.supportsBrightness,
                    discoveredAt: Date(),
                    isAlreadyAdded: false,
                    commandTopic: device.commandTopic,
                    stateTopic: device.stateTopic
                )
                discoveredDevices.append(discoveredDevice)

                // Restart state subscription to exclude removed device
                restartDeviceStateSubscription()

                logger.log(
                    "Unsubscribed from device: \(device.name)",
                    level: .info
                )
            } catch {
                let message = "Failed to unsubscribe from device: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func sendCommand(to deviceId: String, command: Command) {
        Task { @MainActor in
            do {
                try await sendDeviceCommandUseCase.execute(
                    deviceId: deviceId,
                    command: command
                )
                logger.log("Command sent to device \(deviceId)", level: .info)
            } catch {
                let message = "Failed to send command \(deviceId): \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func selectDevice(_ device: Device) {
        selectedDevice = device
        logger.log("Selected device: \(device.name)", level: .info)
    }

    public func clearSelection() {
        selectedDevice = nil
    }

    private func restartDeviceStateSubscription() {
        // Cancel existing subscriptions
        for task in stateSubscriptionTasks.values {
            task.cancel()
        }
        stateSubscriptionTasks.removeAll()

        // Start new subscriptions with current device list
        startDeviceStateSubscription()
    }

    private func startDeviceStateSubscription() {
        // Only start subscriptions if there are devices to monitor
        guard !devices.isEmpty else {
            logger.log(
                "No devices to monitor, skipping state subscription",
                level: .debug
            )
            return
        }

        // Create individual subscription for each device
        for device in devices {
            let task = Task { @MainActor in
                do {
                    let stateStream = try await subscribeToStatesUseCase
                        .execute(stateTopic: device.stateTopic)

                    for await deviceState in stateStream {
                        guard !Task.isCancelled else { break }

                        deviceStates[deviceState.deviceId] = deviceState

                        if let deviceIndex = devices.firstIndex(
                            where: { $0.id == deviceState.deviceId }
                        ) {
                            var updatedDevice = devices[deviceIndex]
                            updatedDevice.status = deviceState
                                .isOnline ? .connected : .disconnected
                            updatedDevice.lastSeen = deviceState.lastUpdate
                            devices[deviceIndex] = updatedDevice
                        }
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    let message = "Device state subscription error for :"
                    let topic = device.stateTopic
                    let errorDescription = error.localizedDescription
                    logger.log(
                        "\(message) \(topic) \(errorDescription)",
                        level: .error
                    )
                }
            }

            stateSubscriptionTasks[device.id] = task
        }
    }

    private func startDiscoverySubscription() {
        logger.log("Starting discovery subscription", level: .debug)
        discoverySubscriptionTask = Task { @MainActor in
            do {
                let discoveryStream =
                    try await subscribeToDiscoveredDevicesUseCase.execute()

                for await newDiscoveredDevices in discoveryStream {
                    guard !Task.isCancelled else { break }

                    let filteredDevices = newDiscoveredDevices
                        .filter { discoveredDevice in
                            !devices.contains { $0.id == discoveredDevice.id }
                        }

                    if filteredDevices.count != discoveredDevices.count {
                        logger.log(
                            "Discovered \(filteredDevices.count) new devices",
                            level: .info
                        )
                    }
                    discoveredDevices = filteredDevices

                    // Update view state if we went from empty to having devices
                    if viewState == .empty,
                       !devices.isEmpty || !discoveredDevices.isEmpty {
                        viewState = .loaded
                        logger.log(
                            "View state changed from empty to loaded",
                            level: .info
                        )
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                let message = "Device discovery subscription error: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }
}
