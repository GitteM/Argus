import DataSource
import Persistence
import RepositoryProtocols
import ServiceProtocols

public protocol ServiceFactory {
    func makeCacheManager() throws -> CacheManagerProtocol
}

public class DefaultServiceFactory: ServiceFactory {
    private let logger: LoggerProtocol

    public init(logger: LoggerProtocol) {
        self.logger = logger
    }

    public func makeCacheManager() throws -> CacheManagerProtocol {
        try CacheManager(logger: logger)
    }
}
