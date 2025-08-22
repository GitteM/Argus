import Entities
import SwiftUI

public typealias AcknowledgeAlertResult = Result<Entities.Alert, Error>

public protocol AcknowledgeAlertUseCase {
    func execute() async throws -> AcknowledgeAlertResult
}
