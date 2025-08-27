import Configuration
import DataSource
import Foundation
import Infrastructure
import Navigation
import Persistence
import Repositories
import RepositoryProtocols
import ServiceProtocols
import Services
import Stores
import UseCases

public struct AppContainer {
    public let deviceStore: DeviceStore
    public let connectionManager: MQTTConnectionManager
    public let router: Router

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
            cacheManager: cacheManager
        )

        let dataSourceFactory = DefaultDataSourceFactory(
            connectionManager: connectionManager,
            clientId: clientId
        )

        // Create repositories
        let repositoryFactory = DefaultRepositoryFactory(
            serviceFactory: serviceFactory,
            dataSourceFactory: dataSourceFactory
        )
        let deviceConnectionRepository = repositoryFactory.makeDeviceConnectionRepository()
        let deviceDiscoveryRepository = repositoryFactory.makeDeviceDiscoveryRepository()
        let deviceStateRepository = repositoryFactory.makeDeviceStateRepository()
        let deviceCommandRepository = repositoryFactory.makeDeviceCommandRepository()

        // Create use cases
        let getManagedDevicesUseCase = GetManagedDevicesUseCase(
            deviceConnectionRepository: deviceConnectionRepository
        )

        let getDiscoveredDevicesUseCase = GetDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: deviceDiscoveryRepository
        )

        let subscribeToStatesUseCase = SubscribeToDeviceStatesUseCase(
            deviceStateRepository: deviceStateRepository
        )

        let subscribeToDiscoveredDevicesUseCase = SubscribeToDiscoveredDevicesUseCase(
            deviceDiscoveryRepository: deviceDiscoveryRepository
        )

        let addDeviceUseCase = AddDeviceUseCase(
            deviceConnectionRepository: deviceConnectionRepository
        )

        let removeDeviceUseCase = RemoveDeviceUseCase(
            deviceConnectionRepository: deviceConnectionRepository
        )

        let sendDeviceCommandUseCase = SendDeviceCommandUseCase(
            deviceCommandRepository: deviceCommandRepository
        )

        // Create factories
        let storeFactory = DefaultStoreFactory(
            getManagedDevicesUseCase: getManagedDevicesUseCase,
            getDiscoveredDevicesUseCase: getDiscoveredDevicesUseCase,
            subscribeToStatesUseCase: subscribeToStatesUseCase,
            subscribeToDiscoveredDevicesUseCase: subscribeToDiscoveredDevicesUseCase,
            addDeviceUseCase: addDeviceUseCase,
            removeDeviceUseCase: removeDeviceUseCase,
            sendDeviceCommandUseCase: sendDeviceCommandUseCase,
            logger: logger
        )

        // Create stores
        deviceStore = storeFactory.makeDeviceStore()

        // Create navigation
        router = Router()
    }
}
