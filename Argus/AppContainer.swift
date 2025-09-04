import Configuration
import DataSource
import DependencyInjection
import Entities
import Foundation
import Navigation
import Persistence
import Repositories
import RepositoryProtocols
import ServiceProtocols
import Services
import Stores
import UseCases

@MainActor
@Observable
public final class AppContainer {
    public let connectionManager: MQTTConnectionManager
    public let router: Router
    public private(set) var deviceStore: DeviceStore
    public private(set) var appState: AppState = .initializing
    private let clientId: String
    private var connectionObserverTask: Task<Void, Never>?

    public init() {
        appState = .loading

        // Create service dependencies
        clientId = "argus-app-\(UUID().uuidString)"
        let logger = LoggingService.shared
        let connectionManager =
            MQTTConnectionManager(
                clientId: clientId,
                broker: Bundle.mqttHost,
                port: Bundle.mqttPort,
                logger: logger
            )
        self.connectionManager = connectionManager

        // Initialize required properties first
        router = Router()
        deviceStore = DeviceStore.emptyPreview
        do {
            try createDependencies()

            Task {
                await initialize()
            }

            setupConnectionStatusObserver()

        } catch {
            let appError = error as? AppError ??
                AppError.initializationError(
                    component: "AppContainer",
                    reason: error.localizedDescription
                )
            appState = .error(appError)
        }
    }

    // MARK: - App State Management

    public func initialize() async {
        updateAppState(to: .ready)
    }

    public func retry() {
        appState = .loading
        Task {
            await reinitialize()
        }
    }

    private func reinitialize() async {
        connectionObserverTask?.cancel()
        do {
            try createDependencies()
            await initialize()
            setupConnectionStatusObserver()

        } catch {
            let appError = error as? AppError ??
                AppError.initializationError(
                    component: "AppContainer",
                    reason: error.localizedDescription
                )
            appState = .error(appError)
        }
    }

    public func handleConnectionStateChange(_ status:
        MQTTConnectionStatus
    ) {
        switch (appState, status) {
        case (.ready, .disconnected), (.ready, .error):
            updateAppState(to: .disconnected)
        case (.disconnected, .connected):
            updateAppState(to: .ready)
        case (.disconnected, .connecting):
            // Stay in disconnected state while attempting to reconnect
            break
        case (_, .connecting):
            // Don't change app state for connecting - let it stay in current
            // state
            break
        default:
            break
        }
    }

    private func updateAppState(to newState: AppState) {
        let previousState = appState
        appState = newState

        // Handle state transitions that require action
        if previousState == .disconnected, newState == .ready {
            // Restart real-time updates when reconnecting
            deviceStore.startRealtimeUpdates()
        }
    }

    private func createDependencies() throws {
        let logger = LoggingService.shared

        let serviceFactory = DefaultServiceFactory(
            logger: logger
        )

        let dataSourceFactory =
            DefaultDataSourceFactory(
                connectionManager: connectionManager,
                clientId: clientId,
                logger: logger
            )

        // Create repositories
        let repositoryFactory =
            DefaultRepositoryFactory(
                serviceFactory: serviceFactory,
                dataSourceFactory: dataSourceFactory
            )
        let deviceConnectionRepository = try repositoryFactory
            .makeDeviceConnectionRepository()
        let deviceDiscoveryRepository = repositoryFactory
            .makeDeviceDiscoveryRepository()
        let deviceStateRepository = repositoryFactory
            .makeDeviceStateRepository()
        let deviceCommandRepository = repositoryFactory
            .makeDeviceCommandRepository()

        // Create use cases
        let getManagedDevicesUseCase =
            GetManagedDevicesUseCase(
                deviceConnectionRepository:
                deviceConnectionRepository
            )

        let getDiscoveredDevicesUseCase =
            GetDiscoveredDevicesUseCase(
                deviceDiscoveryRepository:
                deviceDiscoveryRepository
            )

        let subscribeToStatesUseCase =
            SubscribeToDeviceStatesUseCase(
                deviceStateRepository:
                deviceStateRepository
            )

        let subscribeToDiscoveredDevicesUseCase =
            SubscribeToDiscoveredDevicesUseCase(
                deviceDiscoveryRepository:
                deviceDiscoveryRepository
            )

        let addDeviceUseCase = AddDeviceUseCase(
            deviceConnectionRepository:
            deviceConnectionRepository
        )

        let removeDeviceUseCase =
            RemoveDeviceUseCase(
                deviceConnectionRepository:
                deviceConnectionRepository,
                mqttConnectionManager:
                connectionManager
            )

        let sendDeviceCommandUseCase =
            SendDeviceCommandUseCase(
                deviceCommandRepository:
                deviceCommandRepository
            )

        // Create factories
        let storeFactory = DefaultStoreFactory(
            getManagedDevicesUseCase:
            getManagedDevicesUseCase,
            getDiscoveredDevicesUseCase:
            getDiscoveredDevicesUseCase,
            subscribeToStatesUseCase:
            subscribeToStatesUseCase,
            subscribeToDiscoveredDevicesUseCase:
            subscribeToDiscoveredDevicesUseCase,
            addDeviceUseCase: addDeviceUseCase,
            removeDeviceUseCase:
            removeDeviceUseCase,
            sendDeviceCommandUseCase:
            sendDeviceCommandUseCase,
            logger: logger
        )

        // Create stores
        deviceStore = storeFactory.makeDeviceStore()
    }

    private func setupConnectionStatusObserver() {
        connectionObserverTask = Task { @MainActor in
            var previousStatus = connectionManager.connectionStatus
            while !Task.isCancelled {
                let currentStatus = connectionManager.connectionStatus
                if currentStatus != previousStatus {
                    handleConnectionStateChange(currentStatus)
                    previousStatus = currentStatus
                }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    #if DEBUG
        // Preview-specific initializer
        init(previewState: AppState) {
            appState = previewState
            clientId = "preview-client"

            // Create minimal dependencies for preview
            let logger = LoggingService.shared

            connectionManager = MQTTConnectionManager(
                clientId: clientId,
                broker: "localhost",
                port: 1883,
                logger: logger
            )

            // Use preview device store
            deviceStore = DeviceStore.preview
            router = Router()

            // Don't set up connection observer for previews - they use mock
            // connections
        }
    #endif
}
