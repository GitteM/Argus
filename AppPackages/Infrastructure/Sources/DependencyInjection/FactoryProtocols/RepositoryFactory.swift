import Repositories
import RepositoryProtocols

protocol RepositoryFactory {
    func makeDeviceConnectionRepository() -> DeviceConnectionRepositoryProtocol
    func makeDeviceDiscoveryRepository() -> DeviceDiscoveryRepositoryProtocol
    func makeDeviceStateRepository() -> DeviceStateRepositoryProtocol
}

class DefaultRepositoryFactory: RepositoryFactory {
    private let serviceFactory: ServiceFactory

    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    func makeDeviceConnectionRepository() -> DeviceConnectionRepositoryProtocol {
        DeviceConnectionRepository(
            mqttDataSource: serviceFactory.makeMQTTDataSource(),
            cacheManager: serviceFactory.makeCacheManager()
        )
    }

    func makeDeviceDiscoveryRepository() -> DeviceDiscoveryRepositoryProtocol {
        DeviceDiscoveryRepository(
            mqttDataSource: serviceFactory.makeMQTTDataSource(),
            cacheManager: serviceFactory.makeCacheManager()
        )
    }

    func makeDeviceStateRepository() -> DeviceStateRepositoryProtocol {
        DeviceStateRepository(
            mqttDataSource: serviceFactory.makeMQTTDataSource(),
            restDataSource: serviceFactory.makeRESTDataSource()
        )
    }
}
