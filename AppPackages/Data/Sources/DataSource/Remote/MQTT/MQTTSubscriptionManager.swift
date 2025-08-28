import Entities
import Foundation
import ServiceProtocols

public protocol MQTTSubscriptionManagerProtocol: Sendable {
    func subscribe(
        to topic: String,
        handler: @escaping @Sendable (MQTTMessage) -> Void
    )
    func publish(topic: String, payload: String) async throws
    func connect() async throws
    func disconnect()
}

public final class MQTTSubscriptionManager: MQTTSubscriptionManagerProtocol,
    @unchecked Sendable {
    private let connectionManager: any MQTTConnectionManagerProtocol

    public init(connectionManager: any MQTTConnectionManagerProtocol) {
        self.connectionManager = connectionManager
    }

    public func subscribe(
        to topic: String,
        handler: @escaping @Sendable (MQTTMessage) -> Void
    ) {
        connectionManager.subscribe(to: topic, handler: handler)
    }

    public func publish(topic: String, payload: String) async throws {
        try await connectionManager.publish(topic: topic, payload: payload)
    }

    public func connect() async throws {
        try await connectionManager.connect()
    }

    public func disconnect() {
        connectionManager.disconnect()
    }
}
