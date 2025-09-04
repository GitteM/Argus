import DataUtilities
import Entities
import Foundation
import ServiceProtocols

public protocol CacheManagerProtocol: Sendable {
    func get<T: Codable>(key: String) -> Result<T?, AppError>
    func set(_ value: some Codable & Sendable, key: String, ttl: TimeInterval?)
        -> Result<Void, AppError>
    func remove(key: String)
    func clear() -> Result<Void, AppError>
    func exists(key: String) -> Bool
}

public final class CacheManager: CacheManagerProtocol, Sendable {
    private nonisolated(unsafe) let memoryCache = NSCache<NSString, CacheItem>()
    private nonisolated(unsafe) let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheQueue = DispatchQueue(
        label: "advanced.cache.queue",
        attributes: .concurrent
    )
    private let logger: LoggerProtocol

    public init(
        logger: LoggerProtocol
    ) throws {
        self.logger = logger
        guard let cachesDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            throw AppError.fileSystemError(
                operation: "locate",
                path: "caches directory"
            )
        }
        cacheDirectory = cachesDirectory.appendingPathComponent("AppCache")

        do {
            try fileManager.createCacheDirectory(at: cacheDirectory)
        } catch {
            throw AppError.fileSystemError(
                operation: "create",
                path: cacheDirectory.path
            )
        }

        setupCache()
    }

    private func setupCache() {
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 25 * 1024 * 1024 // 25MB

        loadCriticalItemsFromDisk()
    }

    public func get<T: Codable>(key: String) -> Result<T?, AppError> {
        cacheQueue.sync {
            // Try memory cache first
            if let memoryItem = memoryCache
                .object(forKey: NSString(string: key)) {
                if !memoryItem.isExpired {
                    if let decoded: T = JSONDecoder().decode(
                        T.self,
                        from: memoryItem.data,
                        logger: logger,
                        context: "get Cached value"
                    ) {
                        return .success(decoded)
                    } else {
                        return .failure(AppError.deserializationError(
                            type: String(describing: T.self),
                            details: "Failed to decode cached value"
                        ))
                    }
                } else {
                    memoryCache.removeObject(forKey: NSString(string: key))
                }
            }

            // Try disk cache
            return loadFromDisk(key: key)
        }
    }

    public func set(
        _ value: some Codable & Sendable,
        key: String,
        ttl: TimeInterval? = nil
    ) -> Result<Void, AppError> {
        cacheQueue.sync(flags: .barrier) { [weak self] in
            guard let self else {
                return .failure(AppError.unknown(underlying: nil))
            }

            do {
                let data = try JSONEncoder().encode(value)
                let expirationDate = ttl.map { Date().addingTimeInterval($0) }

                let cacheItem = CacheItem(
                    data: data,
                    expirationDate: expirationDate,
                    createdAt: Date()
                )

                // Store in memory
                memoryCache.setObject(cacheItem, forKey: NSString(string: key))

                // Store on disk for persistence (for important items)
                if shouldPersistToDisk(key: key) {
                    return saveToDiskWithResult(key: key, item: cacheItem)
                }

                return .success(())

            } catch {
                return .failure(AppError.serializationError(
                    type: "cache_item",
                    details: error.localizedDescription
                ))
            }
        }
    }

    public func remove(key: String) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            memoryCache.removeObject(forKey: NSString(string: key))

            // Also remove from disk if it exists
            let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
            fileManager.removeItemSafely(at: fileURL)
        }
    }

    public func clear() -> Result<Void, AppError> {
        cacheQueue.sync(flags: .barrier) { [weak self] in
            guard let self else {
                return .failure(AppError.unknown(underlying: nil))
            }

            memoryCache.removeAllObjects()

            // Also clear disk cache
            do {
                try fileManager.clearCacheFiles(in: cacheDirectory)
                return .success(())
            } catch {
                return .failure(AppError.fileSystemError(
                    operation: "clear",
                    path: cacheDirectory.path
                ))
            }
        }
    }

    public func exists(key: String) -> Bool {
        cacheQueue.sync {
            // Check memory cache first
            if let memoryItem = memoryCache
                .object(forKey: NSString(string: key)) {
                if !memoryItem.isExpired {
                    return true
                } else {
                    memoryCache.removeObject(forKey: NSString(string: key))
                }
            }

            // Check disk cache
            let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
            return fileManager.cacheFileExists(at: fileURL)
        }
    }

    private func shouldPersistToDisk(key: String) -> Bool {
        // Persist important data like device lists, user preferences
        key.contains("devices") ||
            key.contains("settings") ||
            key.contains("user_profile")
    }

    private func saveToDisk(key: String, item: CacheItem) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        do {
            let cacheData = try JSONEncoder().encode(DiskCacheItem(from: item))
            try cacheData.write(to: fileURL)
        } catch {
            let appError = error as? AppError ?? AppError.fileSystemError(
                operation: "save",
                path: fileURL.path
            )
            logCacheError(appError, context: "disk cache save", key: key)
        }
    }

    private func saveToDiskWithResult(
        key: String,
        item: CacheItem
    ) -> Result<Void, AppError> {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        do {
            let cacheData = try JSONEncoder().encode(DiskCacheItem(from: item))
            try cacheData.write(to: fileURL)
            return .success(())
        } catch {
            let appError = error as? AppError ?? AppError.fileSystemError(
                operation: "save",
                path: fileURL.path
            )
            return .failure(appError)
        }
    }

    private func loadFromDisk<T: Codable>(key: String) -> Result<T?, AppError> {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")

        do {
            let data = try Data(contentsOf: fileURL)
            guard let diskItem = JSONDecoder().decode(
                DiskCacheItem.self,
                from: data,
                logger: logger,
                context: "from load from disk"
            ) else {
                return .failure(AppError.deserializationError(
                    type: "DiskCacheItem",
                    details: "Failed to decode disk cache item"
                ))
            }

            if let expirationDate = diskItem.expirationDate,
               Date() > expirationDate {
                fileManager.removeItemSafely(at: fileURL)
                return .success(nil)
            }

            if let decoded: T = JSONDecoder().decode(
                T.self,
                from: diskItem.data,
                logger: logger,
                context: "from load from disk not expired"
            ) {
                return .success(decoded)
            } else {
                return .failure(AppError.deserializationError(
                    type: String(describing: T.self),
                    details: "Failed to decode cached value from disk"
                ))
            }
        } catch {
            if error is DecodingError {
                return .failure(AppError.deserializationError(
                    type: String(describing: T.self),
                    details: error.localizedDescription
                ))
            } else if let nsError = error as NSError?,
                      nsError.domain == NSCocoaErrorDomain,
                      nsError.code == NSFileReadNoSuchFileError {
                // File doesn't exist - this is normal for cache misses
                return .success(nil)
            } else {
                return .failure(AppError.fileSystemError(
                    operation: "read",
                    path: fileURL.path
                ))
            }
        }
    }

    private func loadCriticalItemsFromDisk() {
        // Load important cached items back into memory on app startup
        let criticalKeys = ["devices", "user_settings", "device_states"]

        for key in criticalKeys {
            let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
            guard fileManager.cacheFileExists(at: fileURL) else { continue }

            do {
                let data = try Data(contentsOf: fileURL)
                guard let diskItem = JSONDecoder().decode(
                    DiskCacheItem.self,
                    from: data,
                    logger: logger,
                    context: "from load cached items back into memory on startup"
                ) else {
                    continue
                }

                // Check if not expired
                if let expirationDate = diskItem.expirationDate,
                   Date() > expirationDate {
                    fileManager.removeItemSafely(at: fileURL)
                    continue
                }

                let cacheItem = CacheItem(
                    data: diskItem.data,
                    expirationDate: diskItem.expirationDate,
                    createdAt: diskItem.createdAt
                )

                memoryCache.setObject(cacheItem, forKey: NSString(string: key))
            } catch {
                // Ignore errors and continue with next key
                continue
            }
        }
    }

    // MARK: - Error Logging

    /// Centralized cache error logging using AppError structured information
    private func logCacheError(
        _ error: AppError,
        context: String,
        key: String? = nil
    ) {
        let keyContext = key.map { " (key: \($0))" } ?? ""
        let baseMessage =
            """
                [CACHE \(context.uppercased())]:
                \(error.errorDescription ?? "Unknown error")
                \(keyContext)
            """

        // Add technical details based on error type
        let technicalDetails = buildCacheTechnicalDetails(for: error)
        let fullMessage = technicalDetails.isEmpty
            ? baseMessage

            : "\(baseMessage) - \(technicalDetails)"

        logger.log(fullMessage, level: .error)

        // Log recovery suggestion if available
        if let recoverySuggestion = error.recoverySuggestion {
            logger.log(
                "💡 Recovery suggestion: \(recoverySuggestion)",
                level: .info
            )
        }
    }

    /// Build technical details string from AppError for cache operations
    private func buildCacheTechnicalDetails(for error: AppError) -> String {
        switch error {
        case let .fileSystemError(operation, path):
            "operation=\(operation), path=\(path ?? "unknown")"

        case let .serializationError(type, details):
            "type=\(type), details=\(details ?? "unknown")"

        case let .deserializationError(type, details):
            "type=\(type), details=\(details ?? "unknown")"

        case let .cacheError(key, operation):
            "cache_key=\(key), operation=\(operation)"

        default:
            ""
        }
    }
}
