import SwiftUI

public struct LoadingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.s4) {
            ProgressView()
            Text(Strings.loading)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview("Light Mode") {
    LoadingView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    LoadingView()
        .preferredColorScheme(.dark)
}
