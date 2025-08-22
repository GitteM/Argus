import Entities

public protocol SettingsRepositoryProtocol {
    func saveSetting(_ setting: Setting) async throws
    func loadSetting(forKey key: String) async throws -> Setting?
    func resetSettings() async throws
}
