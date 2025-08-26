import Entities
import RepositoryProtocols

public final class GetManagedDevicesUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol

    public init(deviceConnectionRepository: DeviceConnectionRepositoryProtocol) {
        self.deviceConnectionRepository = deviceConnectionRepository
    }

    public func execute() async throws -> [Device] {
        try await deviceConnectionRepository.getManagedDevices()
    }
}
