import Entities

public typealias GetAlertsResult = Result<[Alert], Error>

public protocol GetAlertsUseCase {
    func execute() async throws -> GetAlertsResult
}
