import Infrastructure
import SharedUI
import SwiftUI

public struct SettingsView: View {
    @Environment(SettingsState.self) private var settingState

    public init() {}

    public var body: some View {
        Text("🚧 SettingsView 🚧")
    }
}
