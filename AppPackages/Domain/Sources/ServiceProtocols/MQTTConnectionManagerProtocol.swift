import CocoaMQTT
import Combine
import Entities
import Foundation

public protocol MQTTConnectionManagerProtocol {
    var connectionStatus: MQTTConnectionStatus { get }

    func connect() async throws
    func disconnect()
    func subscribe(
        to topic: String,
        handler: @escaping @Sendable (MQTTMessage) -> Void
    )
    func unsubscribe(from topic: String)
    func publish(topic: String, payload: String) async throws
}
