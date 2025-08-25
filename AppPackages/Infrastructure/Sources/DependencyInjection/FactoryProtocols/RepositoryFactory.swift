import Repositories
import RepositoryProtocols

protocol RepositoryFactory {
    func makeDeviceConnectionRepository() -> DeviceConnectionRepositoryProtocol
    func makeDeviceDiscoveryRepository() -> DeviceDiscoveryRepositoryProtocol
    func makeDeviceStateRepository() -> DeviceStateRepositoryProtocol
}

public class DefaultRepositoryFactory: RepositoryFactory {
    private let serviceFactory: ServiceFactory

    public init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    public func makeDeviceConnectionRepository() -> DeviceConnectionRepositoryProtocol {
        DeviceConnectionRepository(
            mqttDataSource: serviceFactory.makeMQTTDataSource(),
            cacheManager: serviceFactory.makeCacheManager()
        )
    }

    public func makeDeviceDiscoveryRepository() -> DeviceDiscoveryRepositoryProtocol {
        DeviceDiscoveryRepository(
            mqttDataSource: serviceFactory.makeMQTTDataSource(),
            cacheManager: serviceFactory.makeCacheManager()
        )
    }

    public func makeDeviceStateRepository() -> DeviceStateRepositoryProtocol {
        DeviceStateRepository(
            mqttDataSource: serviceFactory.makeMQTTDataSource(),
            restDataSource: serviceFactory.makeRESTDataSource()
        )
    }
}
