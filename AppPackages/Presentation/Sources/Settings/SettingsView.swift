import Infrastructure
import SharedUI
import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var settingState: SettingsState

    public init() {}

    public var body: some View {
        Text("🚧 SettingsView 🚧")
    }
}

// MARK: - Factory Extension

public extension SettingsView {
    @MainActor
    static func create(from _: SettingsContainer) -> some View {
        SettingsView()
            .environmentObject(SettingsState())
    }
}
