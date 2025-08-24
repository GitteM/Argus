import CocoaMQTT
import Combine
import Entities
import Foundation

public protocol MQTTConnectionManagerProtocol: AnyObject, Sendable {
    var connectionStatus: MQTTConnectionStatus { get }
    var connectionStatusPublisher: Published<MQTTConnectionStatus>.Publisher { get }

    func connect() async throws
    func disconnect()
    func subscribe(to topic: String, handler: @escaping (MQTTMessage) -> Void)
    func publish(topic: String, payload: String) async throws
}
