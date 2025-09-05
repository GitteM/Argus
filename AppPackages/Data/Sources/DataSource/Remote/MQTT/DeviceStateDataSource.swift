import DataUtilities
import Entities
import Foundation
import ServiceProtocols

@available(macOS 10.15, iOS 13, *)
public protocol DeviceStateDataSourceProtocol: Sendable {
    func subscribeToDeviceState(stateTopic: String) async
        -> Result<AsyncStream<DeviceState>, AppError>
    func getDeviceState(deviceId: String) async
        -> Result<DeviceState?, AppError>
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

    @available(macOS 10.15, iOS 13, *)
    public func subscribeToDeviceState(stateTopic: String) async
        -> Result<AsyncStream<DeviceState>, AppError> {
        // Validate topic
        guard !stateTopic.isEmpty else {
            return .failure(.validationError(
                field: "stateTopic",
                reason: "State topic cannot be empty"
            ))
        }

        let stream = AsyncStream<DeviceState> { continuation in
            // Subscribe to the specific state topic
            subscriptionManager
                .subscribe(to: stateTopic) { [weak self] message in
                    guard let self else { return }

                    Task {
                        if let deviceState = await self.parseMessage(message) {
                            await self.updateDeviceState(deviceState)
                            continuation.yield(deviceState)
                        } else {
                            self.logger.log(
                                "Failed to parse message from topic: \(message.topic)",
                                level: .info
                            )
                        }
                    }
                }

            // Handle cleanup when the stream is terminated
            continuation.onTermination = { @Sendable _ in
                // Optional: Unsubscribe from topic if needed
            }
        }

        return .success(stream)
    }

    public func getDeviceState(deviceId: String) async
        -> Result<DeviceState?, AppError> {
        // Validate device ID
        guard !deviceId.isEmpty else {
            return .failure(.validationError(
                field: "deviceId",
                reason: "Device ID cannot be empty"
            ))
        }

        let deviceState = deviceStatesCache[deviceId]
        return .success(deviceState)
    }

    private func updateDeviceState(_ deviceState: DeviceState) {
        deviceStatesCache[deviceState.deviceId] = deviceState
    }

    func parseMessage(_ message: MQTTMessage) async -> DeviceState? {
        let topicComponents = message.topic.components(separatedBy: "/")
        let payload = message.payload

        // Extract device ID based on topic pattern
        guard topicComponents.count >= 3,
              topicComponents[0] == "home" else {
            let logMessage =
                """
                Invalid topic format: \(message.topic).
                Expected format: home/{deviceType}/{deviceId}
                """
            logger.log(
                logMessage,
                level: .info
            )
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

        updateDeviceState(deviceState)
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
        do {
            return try decoder.decode(
                TemperatureSensor.self,
                from: data,
                logger: logger,
                context: "from MQTT topic: \(topic)"
            )
        } catch {
            logger.log(
                "Failed to decode TemperatureSensor from MQTT topic: \(topic). Error: \(error)",
                level: .error
            )
            return nil
        }
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
        do {
            return try decoder.decode(
                LightState.self,
                from: data,
                logger: logger,
                context: "from MQTT topic: \(topic)"
            )
        } catch {
            logger.log(
                "Failed to decode LightState from MQTT topic: \(topic). Error: \(error)",
                level: .error
            )
            return nil
        }
    }
}
