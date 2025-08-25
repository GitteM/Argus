import SwiftUI

// TODO: Incomplete
public struct EmptyStateView: View {
    let message: String
    let icon: String

    public init(message: String, icon: String) {
        self.message = message
        self.icon = icon
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
