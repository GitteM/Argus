import Entities
import Foundation

public protocol DeviceCommandDataSourceProtocol: Sendable {
    func sendDeviceCommand(deviceId: String, command: Command) async throws
}

public struct DeviceCommandDataSource: DeviceCommandDataSourceProtocol {
    private let subscriptionManager: MQTTSubscriptionManagerProtocol

    public init(subscriptionManager: MQTTSubscriptionManagerProtocol) {
        self.subscriptionManager = subscriptionManager
    }

    public func sendDeviceCommand(
        deviceId: String,
        command: Command
    ) async throws {
        let topic = "devices/\(deviceId)/commands"
        let payload = try JSONEncoder().encode(command)
        try await subscriptionManager.publish(
            topic: topic,
            payload: String(data: payload, encoding: .utf8) ?? ""
        )
    }
}
