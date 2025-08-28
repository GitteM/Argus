import SwiftUI

public struct EmptyStateView: View {
    let message: String
    let icon: String

    public init(message: String, icon: String) {
        self.message = message
        self.icon = icon
    }

    public var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: Spacing.l))
                .foregroundColor(.secondary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#if DEBUG

    #Preview {
        EmptyStateView(
            message: "Nothing to see here",
            icon: Icons.noData
        )
    }

#endif
