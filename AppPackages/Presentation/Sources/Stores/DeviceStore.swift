import Entities
import Foundation
import OSLog
import RepositoryProtocols
import ServiceProtocols
import UseCases

@MainActor
public final class DeviceStore: ObservableObject {
    @Published public var viewState: DeviceViewState
    @Published public var devices: [Device] = []
    @Published public var discoveredDevices: [DiscoveredDevice] = []
    @Published public var deviceStates: [String: DeviceState] = [:]

    private let getManagedDevicesUseCase: GetManagedDevicesUseCase
    private let getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase
    private let startDiscoveryUseCase: StartDeviceDiscoveryUseCase
    private let stopDiscoveryUseCase: StopDeviceDiscoveryUseCase
    private let subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase
    private let subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase
    private let addDeviceUseCase: AddDeviceUseCase
    private let sendDeviceCommandUseCase: SendDeviceCommandUseCase
    private let logger: LoggerProtocol

    private var dashboardTask: Task<Void, Never>?
    private var stateSubscriptionTask: Task<Void, Never>?
    private var discoverySubscriptionTask: Task<Void, Never>?

    public init(
        getManagedDevicesUseCase: GetManagedDevicesUseCase,
        getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase,
        startDiscoveryUseCase: StartDeviceDiscoveryUseCase,
        stopDiscoveryUseCase: StopDeviceDiscoveryUseCase,
        subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase,
        subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase,
        addDeviceUseCase: AddDeviceUseCase,
        sendDeviceCommandUseCase: SendDeviceCommandUseCase,
        logger: LoggerProtocol
    ) {
        self.getManagedDevicesUseCase = getManagedDevicesUseCase
        self.getDiscoveredDevicesUseCase = getDiscoveredDevicesUseCase
        self.startDiscoveryUseCase = startDiscoveryUseCase
        self.stopDiscoveryUseCase = stopDiscoveryUseCase
        self.subscribeToStatesUseCase = subscribeToStatesUseCase
        self.subscribeToDiscoveredDevicesUseCase = subscribeToDiscoveredDevicesUseCase
        self.addDeviceUseCase = addDeviceUseCase
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

                guard !(discovered.isEmpty && managed.isEmpty) else {
                    viewState = .empty
                    return
                }

                self.devices = managed
                self.discoveredDevices = discovered

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

    public func startDeviceDiscovery() {
        Task { @MainActor in
            do {
                try await startDiscoveryUseCase.execute()
                logger.log("Device discovery started", level: .info)
            } catch {
                let message = "Failed to start device discovery: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func stopDeviceDiscovery() {
        Task { @MainActor in
            do {
                try await stopDiscoveryUseCase.execute()
                logger.log("Device discovery stopped", level: .info)
            } catch {
                let message = "Failed to stop device discovery: \(error.localizedDescription)"
                logger.log(message, level: .error)
            }
        }
    }

    public func addDevice(_ discoveredDevice: DiscoveredDevice) {
        Task { @MainActor in
            do {
                let device = try await addDeviceUseCase.execute(discoveredDevice: discoveredDevice)
                devices.append(device)
                discoveredDevices.removeAll { $0.id == discoveredDevice.id }
                logger.log("Device added: \(device.name)", level: .info)
            } catch {
                logger.log("Failed to add device: \(error.localizedDescription)", level: .error)
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
        discoverySubscriptionTask = Task { @MainActor in
            do {
                let discoveryStream = try await subscribeToDiscoveredDevicesUseCase.execute()
                for await newDiscoveredDevices in discoveryStream {
                    guard !Task.isCancelled else { break }

                    let filteredDevices = newDiscoveredDevices.filter { discoveredDevice in
                        !devices.contains { $0.id == discoveredDevice.id }
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

    deinit {
        dashboardTask?.cancel()
        stateSubscriptionTask?.cancel()
        discoverySubscriptionTask?.cancel()
    }
}
