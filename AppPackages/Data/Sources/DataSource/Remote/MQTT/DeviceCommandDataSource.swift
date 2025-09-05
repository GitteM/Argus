import Entities
import Foundation

public protocol DeviceCommandDataSourceProtocol: Sendable {
    func sendDeviceCommand(deviceId: String, command: Command) async
        -> Result<Void, AppError>
}

public struct DeviceCommandDataSource: DeviceCommandDataSourceProtocol {
    private let subscriptionManager: MQTTSubscriptionManagerProtocol

    public init(subscriptionManager: MQTTSubscriptionManagerProtocol) {
        self.subscriptionManager = subscriptionManager
    }

    public func sendDeviceCommand(
        deviceId: String,
        command: Command
    ) async -> Result<Void, AppError> {
        do {
            // Validate inputs
            guard !deviceId.isEmpty else {
                return .failure(.validationError(
                    field: "deviceId",
                    reason: "Device ID cannot be empty"
                ))
            }

            let topic = "devices/\(deviceId)/commands"
            let payload = try JSONEncoder().encode(command)

            guard let payloadString = String(data: payload, encoding: .utf8)
            else {
                return .failure(.serializationError(
                    type: "Command",
                    details: "Failed to convert command payload to UTF-8 string"
                ))
            }

            try await subscriptionManager.publish(
                topic: topic,
                payload: payloadString
            )
            return .success(())
        } catch let appError as AppError {
            return .failure(appError)
        } catch {
            return .failure(.deviceCommandFailed(
                deviceId: deviceId,
                command: String(describing: command.type)
            ))
        }
    }
}
