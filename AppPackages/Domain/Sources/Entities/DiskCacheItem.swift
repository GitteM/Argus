import Foundation

public struct DiskCacheItem: Codable {
    public let data: Data
    public let expirationDate: Date?
    public let createdAt: Date

    public init(from cacheItem: CacheItem) {
        data = cacheItem.data
        expirationDate = cacheItem.expirationDate
        createdAt = cacheItem.createdAt
    }
}
