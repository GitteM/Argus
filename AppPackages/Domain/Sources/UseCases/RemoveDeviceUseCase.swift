import Entities
import RepositoryProtocols

public final class RemoveDeviceUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol

    public init(
        deviceConnectionRepository: DeviceConnectionRepositoryProtocol
    ) {
        self.deviceConnectionRepository = deviceConnectionRepository
    }

    public func execute(deviceId: String) async throws {
        try await deviceConnectionRepository.removeDevice(deviceId: deviceId)
    }
}
