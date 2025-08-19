import Entities

public typealias GetDeviceMetricsResult = Result<Device, Error>

public protocol GetDeviceMetricsUseCase {
    func execute(id: String) async throws -> GetDeviceMetricsResult
}
