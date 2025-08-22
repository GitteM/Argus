import Entities

public protocol AlertRepositoryProtocol {
    func fetchAlerts() async throws -> [Alert]
    func acknowledgeAlert(_ alert: Alert) async throws
}
