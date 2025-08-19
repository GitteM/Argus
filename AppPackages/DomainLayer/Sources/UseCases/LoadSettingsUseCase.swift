import Entities
import SwiftUI

public typealias LoadSettingsResult = Result<[Setting], Error>

public protocol LoadSettingsUseCase {
    func execute() async throws -> LoadSettingsResult
}
