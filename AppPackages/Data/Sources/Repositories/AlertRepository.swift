import Entities
import RepositoryProtocols

public struct AlertRepository: AlertRepositoryProtocol {
    public func fetchAlerts() async throws -> [Alert] {
        fatalError("Not Implemented")
    }

    public func acknowledgeAlert(_: Alert) async throws {
        fatalError("Not Implemented")
    }
}
