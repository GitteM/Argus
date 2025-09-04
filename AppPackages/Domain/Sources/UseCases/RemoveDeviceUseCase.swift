import Entities
import Foundation
import RepositoryProtocols
import ServiceProtocols

public final class RemoveDeviceUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol
    private let mqttConnectionManager: MQTTConnectionManagerProtocol

    public init(
        deviceConnectionRepository: DeviceConnectionRepositoryProtocol,
        mqttConnectionManager: MQTTConnectionManagerProtocol
    ) {
        self.deviceConnectionRepository = deviceConnectionRepository
        self.mqttConnectionManager = mqttConnectionManager
    }

    public func execute(deviceId: String) async throws {
        // Get device details before removing (to access stateTopic)
        let devices = try await deviceConnectionRepository
            .getManagedDevices()
        guard let device = devices.first(where: { $0.id == deviceId })
        else {
            throw AppError.deviceNotFound(deviceId: deviceId)
        }

        // Unsubscribe from MQTT topic
        mqttConnectionManager.unsubscribe(from: device.stateTopic)

        // Remove device from persistence
        try await deviceConnectionRepository
            .removeDevice(deviceId: deviceId)
    }
}
