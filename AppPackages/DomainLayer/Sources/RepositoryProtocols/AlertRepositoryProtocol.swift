import Entities

public protocol AlertRepositoryProtocol {
    func fetchAlerts() async throws -> [AppAlert]
    func acknowledgeAlert(_ alert: AppAlert) async throws
}
