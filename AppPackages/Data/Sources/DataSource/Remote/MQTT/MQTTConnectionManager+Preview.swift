import Foundation
import OSLog
import ServiceProtocols

@MainActor
public extension MQTTConnectionManager {
    static var preview: MQTTConnectionManager {
        MQTTConnectionManager(
            clientId: "preview-client",
            broker: "preview-broker",
            port: 1883,
            logger: MockLogger()
        )
    }

    static var disconnectedPreview: MQTTConnectionManager {
        MQTTConnectionManager(
            clientId: "preview-client",
            broker: "preview-broker",
            port: 1883,
            logger: MockLogger()
        )
    }
}

private final class MockLogger: LoggerProtocol {
    func log(_: String, level _: OSLogType) {}
}
