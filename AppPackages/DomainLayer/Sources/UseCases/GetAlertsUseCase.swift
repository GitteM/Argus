import Entities

public typealias GetAlertsResult = Result<[AppAlert], Error>

public protocol GetAlertsUseCase {
    func execute() async throws -> GetAlertsResult
}
