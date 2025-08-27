import CocoaMQTT
import Entities
import Foundation
import Observation
import OSLog
import ServiceProtocols

@Observable
public final class MQTTConnectionManager: MQTTConnectionManagerProtocol, @unchecked Sendable {
    public private(set) var connectionStatus: MQTTConnectionStatus = .disconnected
    private var mqtt: CocoaMQTT5?
    private var messageHandlers: [String: @Sendable (MQTTMessage) -> Void] = [:]
    private var _pendingSubscriptions: [String: @Sendable (MQTTMessage) -> Void] = [:]
    private var pendingSubscriptions: [String: @Sendable (MQTTMessage) -> Void] {
        get { _pendingSubscriptions }
        set { _pendingSubscriptions = newValue }
    }

    private let subscriptionQueue = DispatchQueue(
        label: "mqtt.subscriptions", attributes: .concurrent
    )
    private let clientId: String
    private let broker: String
    private let port: UInt16
    private var connectionContinuation: CheckedContinuation<Void, Error>?
    private let logger: LoggerProtocol

    public init(
        clientId: String,
        broker: String,
        port: UInt16,
        logger: LoggerProtocol
    ) {
        self.clientId = clientId
        self.broker = broker
        self.port = port
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

    public func subscribe(to topic: String, handler: @escaping @Sendable (MQTTMessage) -> Void) {
        subscriptionQueue.async(flags: .barrier) {
            self.logger.log("MQTT subscribing to topic: \(topic)", level: .debug)
            self.messageHandlers[topic] = handler

            if let mqtt = self.mqtt, mqtt.connState == .connected {
                // Connection is ready, subscribe immediately
                mqtt.subscribe(topic, qos: .qos1)
                self.logger.log("MQTT subscribed immediately to: \(topic)", level: .debug)
            } else {
                // Connection not ready, queue for later
                self.logger.log("MQTT queueing subscription for: \(topic)", level: .debug)
                self._pendingSubscriptions[topic] = handler // Direct access to avoid setter
            }
        }
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
        subscriptionQueue.async(flags: .barrier) {
            let message = "MQTT disconnecting - clearing handlers and pending subscriptions"
            self.logger.log(message, level: .info)
            self.mqtt?.disconnect()
            self.mqtt = nil
            self.messageHandlers.removeAll()
            self.pendingSubscriptions.removeAll()
        }
    }

    /**
     Helper function to match MQTT wildcards

     Note: Only supports single-level wildcards (+) but not multi-level (#)
     */
    private func topicMatches(_ pattern: String, actualTopic: String) -> Bool {
        let patternComponents = pattern.components(separatedBy: "/")
        let topicComponents = actualTopic.components(separatedBy: "/")

        guard patternComponents.count == topicComponents.count else {
            return false
        }

        for (patternPart, topicPart) in zip(patternComponents, topicComponents) {
            if patternPart != "+", patternPart != topicPart {
                return false
            }
        }

        return true
    }

    private func processPendingSubscriptions() {
        subscriptionQueue.sync {
            let pendingCount = self._pendingSubscriptions.count
            guard pendingCount > 0 else { return }

            self.logger.log("MQTT processing \(pendingCount) pending subscriptions", level: .debug)

            // Make a copy to avoid modification during iteration
            let subscriptionsToProcess = self._pendingSubscriptions

            for (topic, _) in subscriptionsToProcess {
                if let mqtt = self.mqtt {
                    mqtt.subscribe(topic, qos: .qos1)
                } else {
                    let message = "MQTT failed to process pending subscription - no client"
                    self.logger.log(message, level: .error)
                }
            }

            self._pendingSubscriptions.removeAll()
            self.logger.log("MQTT pending subscriptions processed and cleared", level: .debug)
        }
    }
}

// MARK: - CocoaMQTT5Delegate

extension MQTTConnectionManager: CocoaMQTT5Delegate {
    // MARK: - Connection Methods

    public func mqtt5(
        _: CocoaMQTT5,
        didConnectAck ack: CocoaMQTTCONNACKReasonCode,
        connAckData _: MqttDecodeConnAck?
    ) {
        let isSuccess = ack == .success
        let ackDescription = String(describing: ack)
        Task {
            await MainActor.run {
                if isSuccess {
                    self.connectionStatus = .connected
                    self.logger.log("MQTT connection established", level: .info)
                } else {
                    self.connectionStatus = .disconnected
                    let message = "MQTT connection failed with ack: \(ackDescription)"
                    self.logger.log(message, level: .error)
                }
            }

            if isSuccess {
                connectionContinuation?.resume()
                // Process pending subscriptions now that we're connected
                self.processPendingSubscriptions()
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
            mqtt = nil
        }
    }

    // MARK: - Disconnect and Auth Reason Code Methods

    public func mqtt5(
        _: CocoaMQTT5,
        didReceiveDisconnectReasonCode reasonCode: CocoaMQTTDISCONNECTReasonCode
    ) {
        let logMessage = "MQTT Disconnect received with reason code: \(reasonCode.rawValue)"
        logger.log(logMessage, level: .info)
    }

    public func mqtt5(_: CocoaMQTT5, didReceiveAuthReasonCode reasonCode: CocoaMQTTAUTHReasonCode) {
        logger.log("MQTT Auth received with reason code: \(reasonCode.rawValue)", level: .info)
    }

    // MARK: - Message Methods

    public func mqtt5(
        _: CocoaMQTT5,
        didReceiveMessage message: CocoaMQTT5Message,
        id _: UInt16,
        publishData _: MqttDecodePublish?
    ) {
        logger.log("MQTT message received on topic: \(message.topic)", level: .debug)

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
        var foundHandler = false
        for (subscribedTopic, handler) in messageHandlers where topicMatches(
            subscribedTopic, actualTopic: message.topic
        ) {
            handler(mqttMessage)
            foundHandler = true
        }

        if !foundHandler {
            logger.log("MQTT no handler found for topic: \(message.topic)", level: .debug)
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

    public func mqtt5(
        _: CocoaMQTT5,
        didPublishComplete id: UInt16,
        pubCompData _: MqttDecodePubComp?
    ) {
        logger.log("MQTT Publish completed for message id: \(id)", level: .debug)
    }

    // MARK: - Subscription Methods (Using Xcode's exact signatures)

    public func mqtt5(
        _: CocoaMQTT5,
        didSubscribeTopics success: NSDictionary,
        failed: [String],
        subAckData _: MqttDecodeSubAck?
    ) {
        let logMessage = "MQTT Subscribed to topics - Success: \(success), Failed: \(failed)"
        logger.log(logMessage, level: .info)
    }

    public func mqtt5(
        _: CocoaMQTT5,
        didUnsubscribeTopics topics: [String],
        unsubAckData _: MqttDecodeUnsubAck?
    ) {
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
