import Foundation

public struct AppAlert {
    let id: String
    let deviceId: String
    let sererity: Severity
    let timeStamp: Date
    let isRead: Bool
}

public enum Severity {}
