import Entities
import RepositoryProtocols

public final class GetManagedDevicesUseCase: @unchecked Sendable {
    private let deviceConnectionRepository: DeviceConnectionRepositoryProtocol

    public init(deviceConnectionRepository: DeviceConnectionRepositoryProtocol) {
        self.deviceConnectionRepository = deviceConnectionRepository
    }

    public func execute() async throws -> [Device] {
        let result = await deviceConnectionRepository.getManagedDevices()
        switch result {
        case let .success(devices):
            return devices
        case let .failure(error):
            throw error
        }
    }
}
