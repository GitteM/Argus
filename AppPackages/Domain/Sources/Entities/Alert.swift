import Foundation

public struct Alert {
    let id: String
    let deviceId: String
    let sererity: Severity
    let timeStamp: Date
    let isRead: Bool
}

public enum Severity {}
