import Foundation

public final class CacheItem: NSObject, Sendable {
    public let data: Data
    public let expirationDate: Date?
    public let createdAt: Date
    public let typeIdentifier: String

    public init(
        data: Data,
        expirationDate: Date?,
        createdAt: Date,
        typeIdentifier: String = ""
    ) {
        self.data = data
        self.expirationDate = expirationDate
        self.createdAt = createdAt
        self.typeIdentifier = typeIdentifier
        super.init()
    }
}

public extension CacheItem {
    var isExpired: Bool {
        guard let expirationDate else { return false }
        return Date() > expirationDate
    }
}
