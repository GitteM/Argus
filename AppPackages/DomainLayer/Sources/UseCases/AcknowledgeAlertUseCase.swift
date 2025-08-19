import Entities
import SwiftUI

public typealias AcknowledgeAlertResult = Result<Alert, Error>

public protocol AcknowledgeAlertUseCase {
    func execute() async throws -> AcknowledgeAlertResult
}
