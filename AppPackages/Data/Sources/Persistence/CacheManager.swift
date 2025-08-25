import Entities
import Foundation

public protocol CacheManagerProtocol: Sendable {
    func get<T: Codable>(key: String) -> T?
    func set(_ value: some Codable & Sendable, key: String, ttl: TimeInterval?)
    func remove(key: String)
    func clear()
    func exists(key: String) -> Bool
}

public final class CacheManager: CacheManagerProtocol, Sendable {
    private nonisolated(unsafe) let memoryCache = NSCache<NSString, CacheItem>()
    private nonisolated(unsafe) let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let cacheQueue = DispatchQueue(label: "advanced.cache.queue", attributes: .concurrent)

    public init() {
        // swiftlint:disable:next force_unwrapping
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("AppCache")

        try? fileManager.createCacheDirectory(at: cacheDirectory)
        setupCache()
    }

    private func setupCache() {
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 25 * 1024 * 1024 // 25MB

        loadCriticalItemsFromDisk()
    }

    public func get<T: Codable>(key: String) -> T? {
        cacheQueue.sync {
            // Try memory cache first
            if let memoryItem = memoryCache.object(forKey: NSString(string: key)) {
                if !memoryItem.isExpired {
                    return try? JSONDecoder().decode(T.self, from: memoryItem.data)
                } else {
                    memoryCache.removeObject(forKey: NSString(string: key))
                }
            }

            // Try disk cache
            return loadFromDisk(key: key)
        }
    }

    public func set(_ value: some Codable & Sendable, key: String, ttl: TimeInterval? = nil) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

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
                    saveToDisk(key: key, item: cacheItem)
                }

            } catch {
                print("Cache encode error for key '\(key)': \(error)")
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

    public func clear() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            memoryCache.removeAllObjects()

            // Also clear disk cache
            do {
                try fileManager.clearCacheFiles(in: cacheDirectory)
            } catch {
                print("Failed to clear disk cache: \(error)")
            }
        }
    }

    public func exists(key: String) -> Bool {
        cacheQueue.sync {
            // Check memory cache first
            if let memoryItem = memoryCache.object(forKey: NSString(string: key)) {
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
            print("Failed to save cache item to disk: \(error)")
        }
    }

    private func loadFromDisk<T: Codable>(key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")

        do {
            let data = try Data(contentsOf: fileURL)
            let diskItem = try JSONDecoder().decode(DiskCacheItem.self, from: data)

            if let expirationDate = diskItem.expirationDate, Date() > expirationDate {
                fileManager.removeItemSafely(at: fileURL)
                return nil
            }

            return try JSONDecoder().decode(T.self, from: diskItem.data)
        } catch {
            return nil
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
                let diskItem = try JSONDecoder().decode(DiskCacheItem.self, from: data)

                // Check if not expired
                if let expirationDate = diskItem.expirationDate, Date() > expirationDate {
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
}
