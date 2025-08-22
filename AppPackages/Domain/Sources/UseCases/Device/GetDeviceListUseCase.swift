import Entities

public typealias DashboardResult = Result<[Device], Error>

public protocol GetDeviceListUseCaseProtocol {
    func execute() async throws -> DashboardResult
}
