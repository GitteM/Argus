import Entities
import Foundation
import Observation
import OSLog
import RepositoryProtocols
import ServiceProtocols
import UseCases

@MainActor
@Observable
public final class DeviceStore {
    public var viewState: DeviceViewState
    public var devices: [Device] = []
    public var discoveredDevices: [DiscoveredDevice] = []
    public var deviceStates: [String: DeviceState] = [:]

    private let getManagedDevicesUseCase: GetManagedDevicesUseCase
    private let getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase
    private let subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase
    private let subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase
    private let addDeviceUseCase: AddDeviceUseCase
    private let removeDeviceUseCase: RemoveDeviceUseCase
    private let sendDeviceCommandUseCase: SendDeviceCommandUseCase
    private let logger: LoggerProtocol

    private var dashboardTask: Task<Void, Never>?
    private var stateSubscriptionTask: Task<Void, Never>?
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
        self.subscribeToDiscoveredDevicesUseCase = subscribeToDiscoveredDevicesUseCase
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
                async let discoveredDevices = getDiscoveredDevicesUseCase.execute()

                let (managed, discovered) = try await (managedDevices, discoveredDevices)

                guard !Task.isCancelled else {
                    return
                }

                self.devices = managed
                self.discoveredDevices = discovered

                // Start real-time subscriptions to get live updates
                self.startRealtimeUpdates()

                // Always set to loaded - empty discovered devices is valid state
                viewState = .loaded
                logger.log("Dashboard data loaded", level: .info)

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
        stateSubscriptionTask?.cancel()
        discoverySubscriptionTask?.cancel()
        stateSubscriptionTask = nil
        discoverySubscriptionTask = nil
    }

    public func subscribeToDevice(_ discoveredDevice: DiscoveredDevice) {
        Task { @MainActor in
            do {
                let device = try await addDeviceUseCase.execute(discoveredDevice: discoveredDevice)
                devices.append(device)
                discoveredDevices.removeAll { $0.id == discoveredDevice.id }
                logger.log("Subscribed to device: \(device.name)", level: .info)
            } catch {
                viewState = .error("Failed to subscribe to device")
                let message = "Failed to subscribe to device: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func unsubscribeFromDevice(_ device: Device) {
        Task { @MainActor in
            do {
                try await removeDeviceUseCase.execute(deviceId: device.id)
                devices.removeAll { $0.id == device.id }

                // Convert back to discovered device so it appears in available list
                let discoveredDevice = DiscoveredDevice(
                    id: device.id,
                    name: device.name,
                    type: device.type,
                    manufacturer: device.manufacturer,
                    model: device.model,
                    discoveredAt: Date(),
                    isAlreadyAdded: false
                )
                discoveredDevices.append(discoveredDevice)

                logger.log("Unsubscribed from device: \(device.name)", level: .info)
            } catch {
                let message = "Failed to unsubscribe from device: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func sendCommand(to deviceId: String, command: Command) {
        Task { @MainActor in
            do {
                try await sendDeviceCommandUseCase.execute(deviceId: deviceId, command: command)
                logger.log("Command sent to device \(deviceId)", level: .info)
            } catch {
                let message = "Failed to send command \(deviceId): \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    private func startDeviceStateSubscription() {
        stateSubscriptionTask = Task { @MainActor in
            do {
                let stateStream = try await subscribeToStatesUseCase.execute()
                for await states in stateStream {
                    guard !Task.isCancelled else { break }

                    for state in states {
                        deviceStates[state.deviceId] = state

                        if let deviceIndex = devices.firstIndex(
                            where: { $0.id == state.deviceId }
                        ) {
                            var updatedDevice = devices[deviceIndex]
                            updatedDevice.status = state.isOnline ? .connected : .disconnected
                            updatedDevice.lastSeen = state.lastUpdate
                            devices[deviceIndex] = updatedDevice
                        }
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                let message = "Device state subscription error: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    private func startDiscoverySubscription() {
        logger.log("Starting discovery subscription", level: .debug)
        discoverySubscriptionTask = Task { @MainActor in
            do {
                let discoveryStream = try await subscribeToDiscoveredDevicesUseCase.execute()

                for await newDiscoveredDevices in discoveryStream {
                    guard !Task.isCancelled else { break }

                    let filteredDevices = newDiscoveredDevices.filter { discoveredDevice in
                        !devices.contains { $0.id == discoveredDevice.id }
                    }

                    if filteredDevices.count != discoveredDevices.count {
                        logger.log("Discovered \(filteredDevices.count) new devices", level: .info)
                    }
                    discoveredDevices = filteredDevices
                }
            } catch {
                guard !Task.isCancelled else { return }
                let message = "Device discovery subscription error: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }
}
