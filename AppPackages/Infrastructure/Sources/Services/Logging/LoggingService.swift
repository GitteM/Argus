import OSLog
import RepositoryProtocols
import Utilities

public final class LoggingService: LoggerProtocol, Sendable {
    enum Category: String {
        case mqtt
        case general
    }

    public static let shared = LoggingService()
    private let mqtt: Logger
    private let general: Logger

    private init() {
        mqtt = Logger(
            subsystem: Constants.logSubsystem,
            category: Category.mqtt.rawValue
        )
        general = Logger(
            subsystem: Constants.logSubsystem,
            category: Category.general.rawValue
        )
    }

    public func log(_ message: String, level: OSLogType = .info) {
        general.log(level: level, "\(message)")
    }

    public func logMQTT(_ message: String, level: OSLogType = .info) {
        mqtt.log(level: level, "\(message)")
    }
}
