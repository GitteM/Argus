import CocoaMQTT
import Entities
import Foundation
import OSLog
import RepositoryProtocols

public protocol MQTTConnectionManagerProtocol: ObservableObject {
    var connectionStatus: MQTTConnectionStatus { get }
    func connect() async throws
    func subscribe(to topic: String, handler: @escaping (MQTTMessage) -> Void)
    func publish(topic: String, payload: String) async throws
    func disconnect()
}

public final class MQTTConnectionManager: MQTTConnectionManagerProtocol, @unchecked Sendable {
    @Published public private(set) var connectionStatus: MQTTConnectionStatus = .disconnected
    private var mqtt: CocoaMQTT5?
    private var messageHandlers: [String: (MQTTMessage) -> Void] = [:]
    private let clientId: String
    private let broker: String
    private let port: UInt16
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private let logger: LoggerProtocol

    // TODO: Configure .xcconfig files for development and local schemes
    public init(
        clientId: String,
        broker: String = "localhost",
        port: UInt16 = 1883,
        logger: LoggerProtocol
    ) {
        self.clientId = clientId
        self.broker = broker
        self.port = port
        self.logger = logger
    }

    /// init for testing
    init(
        mqtt: CocoaMQTT5? = nil,
        messageHandlers: [String: (MQTTMessage) -> Void],
        clientId: String,
        broker: String,
        port: UInt16,
        connectionContinuation: CheckedContinuation<Void, Error>? = nil,
        logger: LoggerProtocol
    ) {
        self.mqtt = mqtt
        self.messageHandlers = messageHandlers
        self.clientId = clientId
        self.broker = broker
        self.port = port
        self.connectionContinuation = connectionContinuation
        self.logger = logger
    }

    public func connect() async throws {
        guard mqtt == nil else { return }

        logger.log("Starting MQTT connection to \(broker):\(port)", level: .info)
        await MainActor.run {
            connectionStatus = .connecting
        }

        mqtt = CocoaMQTT5(clientID: clientId, host: broker, port: port)
        mqtt?.delegate = self
        mqtt?.keepAlive = 60
        mqtt?.cleanSession = true

        return try await withCheckedThrowingContinuation { continuation in
            self.connectionContinuation = continuation

            guard self.mqtt?.connect() == true else {
                Task {
                    await MainActor.run {
                        self.connectionStatus = .disconnected
                    }
                }
                continuation.resume(throwing: MQTTError.connectionFailed)
                self.connectionContinuation = nil
                return
            }
        }
    }

    public func subscribe(to topic: String, handler: @escaping (MQTTMessage) -> Void) {
        messageHandlers[topic] = handler
        mqtt?.subscribe(topic, qos: .qos1)
    }

    public func publish(topic: String, payload: String) async throws {
        guard let mqtt, mqtt.connState == .connected else {
            throw MQTTError.notConnected
        }

        let properties = MqttPublishProperties()
        let messageId = mqtt.publish(
            topic,
            withString: payload,
            qos: .qos1,
            retained: false,
            properties: properties
        )

        if messageId == 0 {
            throw MQTTError.publishFailed
        }
    }

    public func disconnect() {
        mqtt?.disconnect()
        mqtt = nil
        messageHandlers.removeAll()
    }

    /**
     Helper function to match MQTT wildcards

     Note: Only supports single-level wildcards (+) but not multi-level (#)
     */
    private func topicMatches(_ pattern: String, actualTopic: String) -> Bool {
        let patternComponents = pattern.components(separatedBy: "/")
        let topicComponents = actualTopic.components(separatedBy: "/")

        guard patternComponents.count == topicComponents.count else { return false }

        for (pattern, topic) in zip(patternComponents, topicComponents) {
            if pattern != "+", pattern != topic {
                return false
            }
        }

        return true
    }
}

// MARK: - CocoaMQTT5Delegate

extension MQTTConnectionManager: CocoaMQTT5Delegate {
    // MARK: - Connection Methods

    public func mqtt5(_: CocoaMQTT5, didConnectAck ack: CocoaMQTTCONNACKReasonCode, connAckData _: MqttDecodeConnAck?) {
        let isSuccess = ack == .success
        let ackDescription = String(describing: ack)
        Task {
            await MainActor.run {
                if isSuccess {
                    self.connectionStatus = .connected
                    self.logger.log("MQTT connection established", level: .info)
                } else {
                    self.connectionStatus = .disconnected
                    self.logger.log("MQTT connection failed with ack: \(ackDescription)", level: .error)
                }
            }

            if isSuccess {
                connectionContinuation?.resume()
            } else {
                connectionContinuation?.resume(throwing: MQTTError.connectionFailed)
            }
            connectionContinuation = nil
        }
    }

    public func mqtt5DidDisconnect(_: CocoaMQTT5, withError err: Error?) {
        Task {
            await MainActor.run {
                self.connectionStatus = .disconnected
            }
            let errorMessage = err?.localizedDescription ?? "No error"
            self.logger.log("MQTT Disconnected: \(errorMessage)", level: .error)
            connectionContinuation?.resume(throwing: err ?? MQTTError.connectionFailed)
            connectionContinuation = nil
        }
    }

    // MARK: - Disconnect and Auth Reason Code Methods

    public func mqtt5(_: CocoaMQTT5, didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode) {
        logger.log("MQTT Disconnect received with reason code: \(reasonCode.rawValue)", level: .info)
    }

    public func mqtt5(_: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        logger.log("MQTT Auth received with reason code: \(reasonCode.rawValue)", level: .info)
    }

    // MARK: - Message Methods

    public func mqtt5(_: CocoaMQTT5, didReceiveMessage message: CocoaMQTT5Message, id _: UInt16, publishData _: MqttDecodePublish?) {
        let mqttMessage = MQTTMessage(
            topic: message.topic,
            payload: message.string ?? ""
        )

        // Check for exact topic match first
        if let handler = messageHandlers[message.topic] {
            handler(mqttMessage)
            return
        }

        // Check for wildcard matches
        for (subscribedTopic, handler) in messageHandlers {
            if topicMatches(subscribedTopic, actualTopic: message.topic) {
                handler(mqttMessage)
            }
        }
    }

    public func mqtt5(_: CocoaMQTT5, didPublishMessage message: CocoaMQTT5Message, id _: UInt16) {
        logger.log("MQTT Published message to topic: \(message.topic)", level: .debug)
    }

    public func mqtt5(_: CocoaMQTT5, didPublishAck id: UInt16, pubAckData _: MqttDecodePubAck?) {
        logger.log("MQTT Publish acknowledged for message id: \(id)", level: .debug)
    }

    public func mqtt5(_: CocoaMQTT5, didPublishRec id: UInt16, pubRecData _: MqttDecodePubRec?) {
        logger.log("MQTT Publish received for message id: \(id)", level: .debug)
    }

    public func mqtt5(_: CocoaMQTT5, didPublishComplete id: UInt16, pubCompData _: MqttDecodePubComp?) {
        logger.log("MQTT Publish completed for message id: \(id)", level: .debug)
    }

    // MARK: - Subscription Methods (Using Xcode's exact signatures)

    public func mqtt5(_: CocoaMQTT5, didSubscribeTopics success: NSDictionary, failed: [String], subAckData _: MqttDecodeSubAck?) {
        logger.log("MQTT Subscribed to topics - Success: \(success), Failed: \(failed)", level: .info)
    }

    public func mqtt5(_: CocoaMQTT5, didUnsubscribeTopics topics: [String], unsubAckData _: MqttDecodeUnsubAck?) {
        logger.log("MQTT Unsubscribed from topics: \(topics)", level: .info)
    }

    // MARK: - Ping/Pong Methods (Using Xcode's exact signatures)

    public func mqtt5DidPing(_: CocoaMQTT5) {
        logger.log("MQTT Ping", level: .debug)
    }

    public func mqtt5DidReceivePong(_: CocoaMQTT5) {
        logger.log("MQTT Pong received", level: .debug)
    }
}

// TODO: Localize
public extension MQTTError {
    var localizedDescription: String {
        switch self {
        case .connectionFailed:
            "Failed to connect to MQTT broker"
        case .notConnected:
            "MQTT client is not connected"
        case .publishFailed:
            "Failed to publish MQTT message"
        }
    }
}
