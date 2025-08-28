import SwiftUI

public struct BackToolbarItem: ToolbarContent {
    private let action: () -> Void
    private let icon: String
    private let placement: ToolbarItemPlacement

    public init(action: @escaping () -> Void) {
        self.action = action
        icon = Icons.chevronLeft
        #if os(iOS)
            placement = .navigationBarLeading
        #elseif os(macOS)
            placement = .navigation
        #endif
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            Button(action: action) {
                Image(systemName: icon)
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel(Strings.back)
        }
    }
}
