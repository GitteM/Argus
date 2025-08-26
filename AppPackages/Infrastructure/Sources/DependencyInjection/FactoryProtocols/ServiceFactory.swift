import DataSource
import Persistence
import RepositoryProtocols

public protocol ServiceFactory {
    func makeCacheManager() -> CacheManagerProtocol
}

public class DefaultServiceFactory: ServiceFactory {
    private let cacheManager: CacheManagerProtocol

    public init(
        cacheManager: CacheManagerProtocol,
    ) {
        self.cacheManager = cacheManager
    }

    public func makeCacheManager() -> CacheManagerProtocol {
        CacheManager()
    }
}
