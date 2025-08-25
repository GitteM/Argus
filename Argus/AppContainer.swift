import Configuration
import Dashboard
import DataSource
import Foundation
import Infrastructure
import Persistence
import Repositories
import RepositoryProtocols
import Services
import UseCases

public struct AppContainer {
    public let dashboardContainer: DashboardContainer
    public let dashboardStore: DashboardStore
    public let settingsContainer: SettingsContainer
    public let connectionManager: MQTTConnectionManager

    @MainActor public init() {
        // Create service dependencies
        let logger = LoggingService.shared
        let clientId = "argus-app-\(UUID().uuidString)"

        let connectionManager = MQTTConnectionManager(
            clientId: clientId,
            broker: Bundle.mqttHost,
            port: Bundle.mqttPort,
            logger: logger
        )
        self.connectionManager = connectionManager
        let cacheManager = CacheManager()
        let serviceFactory = DefaultServiceFactory(
            cacheManager: cacheManager,
            connectionManager: connectionManager,
            clientId: clientId
        )
        let repositoryFactory = DefaultRepositoryFactory(serviceFactory: serviceFactory)

        // Create use cases
        let getDashboardDataUseCase = GetDashboardDataUseCase(
            deviceConnectionRepository: repositoryFactory.makeDeviceConnectionRepository(),
            deviceDiscoveryRepository: repositoryFactory.makeDeviceDiscoveryRepository(),
            deviceStateRepository: repositoryFactory.makeDeviceStateRepository()
        )

        // Create module containers
        dashboardContainer = DashboardContainer(
            getDashboardDataUseCase: getDashboardDataUseCase
        )

        // Create stores
        dashboardStore = DashboardStore(
            getDashboardDataUseCase: getDashboardDataUseCase,
            logger: logger
        )

        settingsContainer = SettingsContainer()
    }
}
