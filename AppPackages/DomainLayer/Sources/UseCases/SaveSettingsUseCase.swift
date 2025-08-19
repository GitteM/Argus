import Entities

public typealias SaveSettingsResult = Result<[Setting], Error>

public protocol SaveSettingsUseCase {
    func execute(_ settings: [Setting]) async throws -> SaveSettingsResult
}
