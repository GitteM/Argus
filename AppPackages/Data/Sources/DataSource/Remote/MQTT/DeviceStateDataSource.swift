import DataUtilities
import Entities
import Foundation
import ServiceProtocols

public protocol DeviceStateDataSourceProtocol: Sendable {
    func subscribeToDeviceState(stateTopic: String) async
        -> AsyncStream<DeviceState>
    func getDeviceState(deviceId: String) async throws -> DeviceState?
}

public actor DeviceStateDataSource: DeviceStateDataSourceProtocol {
    private let subscriptionManager: MQTTSubscriptionManagerProtocol
    private var deviceStatesCache: [String: DeviceState] = [:]
    private let logger: LoggerProtocol

    public init(
        subscriptionManager: MQTTSubscriptionManagerProtocol,
        logger: LoggerProtocol
    ) {
        self.subscriptionManager = subscriptionManager
        self.logger = logger
    }

    public func subscribeToDeviceState(stateTopic: String) async
        -> AsyncStream<DeviceState> {
        AsyncStream { continuation in
            // Subscribe to the specific state topic
            subscriptionManager
                .subscribe(to: stateTopic) { [weak self] message in
                    guard let self else { return }

                    Task {
                        if let deviceState = await self.parseMessage(message) {
                            await self.updateDeviceState(deviceState)
                            continuation.yield(deviceState)
                        }
                    }
                }

            // Handle cleanup when the stream is terminated
            continuation.onTermination = { @Sendable _ in
                // Optional: Unsubscribe from topic if needed
            }
        }
    }

    public func getDeviceState(deviceId: String) -> DeviceState? {
        deviceStatesCache[deviceId]
    }

    private func updateDeviceState(_ deviceState: DeviceState) {
        deviceStatesCache[deviceState.deviceId] = deviceState
    }

    private func parseMessage(_ message: MQTTMessage) async -> DeviceState? {
        let topicComponents = message.topic.components(separatedBy: "/")
        let payload = message.payload

        // Extract device ID based on topic pattern
        guard topicComponents.count >= 3,
              topicComponents[0] == "home" else {
            return nil
        }

        let deviceTypeString = topicComponents[1]
        let deviceId = topicComponents[2]

        let isOnline = !payload.isEmpty && payload.lowercased() != "unavailable"

        let deviceType: DeviceType = switch deviceTypeString {
        case "sensor":
            .temperatureSensor
        case "light":
            .smartLight
        default:
            .unknown
        }

        // Decode based on device type
        let temperatureSensor = deviceType == .temperatureSensor ?
            await decodeTemperatureSensor(from: payload, topic: message.topic) :
            nil

        let lightState = deviceType == .smartLight ?
            await decodeLightState(from: payload, topic: message.topic) : nil

        let deviceState = DeviceState(
            deviceId: deviceId,
            deviceType: deviceType,
            isOnline: isOnline,
            lastUpdate: Date(),
            payload: payload,
            temperatureSensor: temperatureSensor,
            lightState: lightState
        )

        #if DEBUG
            dump(deviceState)
        #endif
        return deviceState
    }

    // MARK: - Temperature Sensor Decoding

    private func decodeTemperatureSensor(
        from payload: String,
        topic: String
    ) async -> TemperatureSensor? {
        guard let data = payload.data(using: .utf8) else {
            logger.log(
                "Failed to convert payload to data for topic: \(topic)",
                level: .error
            )
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso)
        return decoder.decode(
            TemperatureSensor.self,
            from: data,
            logger: logger,
            context: "from MQTT topic: \(topic)"
        )
    }

    // MARK: - Light State Decoding

    private func decodeLightState(
        from payload: String,
        topic: String
    ) async -> LightState? {
        guard let data = payload.data(using: .utf8) else {
            logger.log(
                "Failed to convert payload to data for topic: \(topic)",
                level: .error
            )
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso)
        return decoder.decode(
            LightState.self,
            from: data,
            logger: logger,
            context: "from MQTT topic: \(topic)"
        )
    }
}
