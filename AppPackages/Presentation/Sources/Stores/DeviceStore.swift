import Entities
import Foundation
import Observation
import OSLog
import RepositoryProtocols
import ServiceProtocols
import UseCases

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
                    handleUnknownError(
                        error,
                        fallbackAppError: AppError.unknown(underlying: error),
                        context: "dashboard loading"
                    )
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
                convertAvailableDeviceToDevice(
                    discoveredDevice,
                    device: device
                )

                // Restart state subscription to include new device
                restartDeviceStateSubscription()

                logger.log("Subscribed to device: \(device.name)", level: .info)
            } catch {
                handleUnknownError(
                    error,
                    fallbackAppError: AppError
                        .deviceConnectionFailed(deviceId: discoveredDevice.id),
                    context: "device subscription",
                    entityName: discoveredDevice.name
                )
            }
        }
    }

    public func unsubscribeFromDevice(withId deviceId: String) {
        Task { @MainActor in
            do {
                guard let device = findDevice(withId: deviceId)
                else {
                    handleError(
                        AppError.deviceNotFound(deviceId: deviceId),
                        context: "device removal"
                    )
                    return
                }

                try await removeDeviceUseCase.execute(deviceId: device.id)

                convertDeviceToAvailableDevice(device)

                // Restart state subscription to exclude removed device
                restartDeviceStateSubscription()

                logger.log(
                    "Unsubscribed from device: \(device.name)",
                    level: .info
                )
            } catch {
                let deviceName = findDevice(withId: deviceId)?.name ?? "Unknown"
                handleUnknownError(
                    error,
                    fallbackAppError: AppError.unknown(underlying: error),
                    context: "device removal",
                    entityName: deviceName
                )
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
                handleUnknownError(
                    error,
                    fallbackAppError: AppError.deviceCommandFailed(
                        deviceId: deviceId,
                        command: String(describing: command.type)
                    ),
                    context: "command execution",
                    shouldUpdateViewState: false // Commands shouldn't change
                    // main view state
                )
            }
        }
    }

    public func selectDevice(_ device: Device) {
        selectedDevice = device
        logger.log("Selected device: \(device.name)", level: .info)
    }

    public func clearSelection() {
        selectedDevice = nil
        logger.log("Clear Selected device", level: .info)
    }
}

// MARK: Private methods

private extension DeviceStore {
    func startDiscoverySubscription() {
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
                handleUnknownError(
                    error,
                    fallbackAppError: AppError
                        .discoveryFailed(reason: error.localizedDescription),
                    context: "device discovery",
                    shouldUpdateViewState: false // Background discovery
                    // shouldn't change main view state
                )
            }
        }
    }

    func startDeviceStateSubscription() {
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
                    handleUnknownError(
                        error,
                        fallbackAppError: AppError
                            .mqttSubscriptionFailed(topic: device.stateTopic),
                        context: "device state subscription",
                        entityName: device.name,
                        shouldUpdateViewState: false
                        // Background subscriptions shouldn't change main view
                        // state
                    )
                }
            }

            stateSubscriptionTasks[device.id] = task
        }
    }

    func restartDeviceStateSubscription() {
        // Cancel existing subscriptions
        for task in stateSubscriptionTasks.values {
            task.cancel()
        }
        stateSubscriptionTasks.removeAll()

        // Start new subscriptions with current device list
        startDeviceStateSubscription()
    }

    func findDevice(withId deviceId: String) -> Device? {
        devices.first(where: { $0.id == deviceId })
    }

    func convertDeviceToAvailableDevice(_ device: Device) {
        devices.removeAll { $0.id == device.id }
        discoveredDevices.append(DiscoveredDevice(device: device))
    }

    func convertAvailableDeviceToDevice(
        _ discoveredDevice: DiscoveredDevice,
        device: Device
    ) {
        discoveredDevices.removeAll { $0.id == discoveredDevice.id }
        devices.append(device)
    }
}

// MARK: AppError and Error Logging

private extension DeviceStore {
    func handleError(
        _ error: AppError,
        context: String,
        entityName: String? = nil,
        shouldUpdateViewState: Bool = true
    ) {
        // Set the AppError directly to viewState for rich error information
        if shouldUpdateViewState {
            viewState = .error(error)
        }

        // Use AppError's structured information for consistent logging
        logAppError(error, context: context, entityName: entityName)
    }

    func handleUnknownError(
        _ error: Error,
        fallbackAppError: AppError,
        context: String,
        entityName: String? = nil,
        shouldUpdateViewState: Bool = true
    ) {
        let appError = error as? AppError ?? fallbackAppError
        handleError(
            appError,
            context: context,
            entityName: entityName,
            shouldUpdateViewState: shouldUpdateViewState
        )
    }

    func logAppError(
        _ error: AppError,
        context: String,
        entityName: String? = nil
    ) {
        let entityContext = entityName.map { " (entity: \($0))" } ?? ""
        let baseMessage =
            """
            [\(context.uppercased())]
            \(error.errorDescription ?? "Unknown error")
            \(entityContext)
            """

        let technicalDetails = buildTechnicalDetails(for: error)
        let fullMessage = technicalDetails.isEmpty
            ? baseMessage
            : "\(baseMessage) - \(technicalDetails)"

        logger.log(fullMessage, level: .error)

        if let recoverySuggestion = error.recoverySuggestion {
            logger.log(
                "💡 Recovery suggestion: \(recoverySuggestion)",
                level: .info
            )
        }
    }

    func buildTechnicalDetails(for error: AppError) -> String {
        switch error {
        case let .deviceNotFound(deviceId):
            return "deviceId=\(deviceId)"

        case let .mqttConnectionFailed(details):
            return "mqtt_details=\(details ?? "connection_failed")"

        case let .persistenceError(operation, details):
            let detailsString = details.map { ", details=\($0)" } ?? ""
            return "operation=\(operation)\(detailsString)"

        case let .deviceConnectionFailed(deviceId):
            return "target_device=\(deviceId)"

        case let .deviceCommandFailed(deviceId, command):
            return "target_device=\(deviceId), command=\(command)"

        case let .timeout(operation, duration):
            return "operation=\(operation), timeout_duration=\(String(describing: duration))s"

        case let .unknown(underlying):
            return "underlying_error=\(underlying?.localizedDescription ?? "nil")"

        default:
            return ""
        }
    }
}
