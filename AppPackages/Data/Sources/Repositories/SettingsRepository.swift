import Entities
import RepositoryProtocols

public struct SettingsRepository: SettingsRepositoryProtocol {
    public func saveSetting(_: Setting) async throws {
        fatalError("Not implemented")
    }

    public func loadSetting(forKey _: String) async throws -> Setting? {
        fatalError("Not implemented")
    }

    public func resetSettings() async throws {
        fatalError("Not implemented")
    }
}
