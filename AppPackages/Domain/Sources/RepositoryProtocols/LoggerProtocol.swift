import OSLog

public protocol LoggerProtocol: Sendable {
    func log(_ message: String, level: OSLogType)
}
