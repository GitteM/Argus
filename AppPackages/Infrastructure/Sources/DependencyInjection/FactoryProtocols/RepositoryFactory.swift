import Repositories
import RepositoryProtocols

protocol RepositoryFactory {
    func makeDeviceConnectionRepository() -> DeviceConnectionRepositoryProtocol
    func makeDeviceDiscoveryRepository() -> DeviceDiscoveryRepositoryProtocol
    func makeDeviceStateRepository() -> DeviceStateRepositoryProtocol
    func makeDeviceCommandRepository() -> DeviceCommandRepositoryProtocol
}

public class DefaultRepositoryFactory: RepositoryFactory {
    private let serviceFactory: ServiceFactory
    private let dataSourceFactory: DataSourceFactory

    public init(
        serviceFactory: ServiceFactory,
        dataSourceFactory: DataSourceFactory
    ) {
        self.serviceFactory = serviceFactory
        self.dataSourceFactory = dataSourceFactory
    }

    public func makeDeviceConnectionRepository() -> DeviceConnectionRepositoryProtocol {
        DeviceConnectionRepository(
            cacheManager: serviceFactory.makeCacheManager()
        )
    }

    public func makeDeviceDiscoveryRepository() -> DeviceDiscoveryRepositoryProtocol {
        DeviceDiscoveryRepository(
            deviceDiscoveryDataSource: dataSourceFactory.makeDeviceDiscoveryDataSource(),
            cacheManager: serviceFactory.makeCacheManager()
        )
    }

    public func makeDeviceStateRepository() -> DeviceStateRepositoryProtocol {
        DeviceStateRepository(
            deviceStateDataSource: dataSourceFactory.makeDeviceStateDataSource()
        )
    }

    public func makeDeviceCommandRepository() -> DeviceCommandRepositoryProtocol {
        DeviceCommandRepository(
            deviceCommandDataSource: dataSourceFactory.makeDeviceCommandDataSource()
        )
    }
}
