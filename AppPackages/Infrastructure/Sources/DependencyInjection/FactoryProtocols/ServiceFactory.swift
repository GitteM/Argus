import DataSource
import Persistence
import RepositoryProtocols

public protocol ServiceFactory {
    func makeMQTTDataSource() -> MQTTDataSourceProtocol
    func makeCacheManager() -> CacheManagerProtocol
    func makeRESTDataSource() -> RESTDataSourceProtocol
}

public class DefaultServiceFactory: ServiceFactory {
    private let cacheManager: CacheManagerProtocol
    private let connectionManager: MQTTConnectionManager
    private let clientId: String
    public init(
        cacheManager: CacheManagerProtocol,
        connectionManager: MQTTConnectionManager,
        clientId: String
    ) {
        self.cacheManager = cacheManager
        self.connectionManager = connectionManager
        self.clientId = clientId
    }

    public func makeMQTTDataSource() -> MQTTDataSourceProtocol {
        MQTTDataSource(
            connectionManager: connectionManager,
            clientId: clientId
        )
    }

    public func makeRESTDataSource() -> RESTDataSourceProtocol {
        RESTDataSource()
    }

    public func makeCacheManager() -> CacheManagerProtocol {
        CacheManager()
    }
}
