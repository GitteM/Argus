import SwiftUI

public struct AppLoadingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: Spacing.section) {
            VStack(spacing: Spacing.s4) {
                Text("Argus")
                    .font(.headline)
                    .fontWeight(.medium)

                Text("Setting up your device connections")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                ProgressView()
                    .tint(.accentColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, ignoresSafeAreaEdges: .all)
    }
}

#if DEBUG

    #Preview("Light Mode") {
        AppLoadingView()
            .preferredColorScheme(.light)
    }

    #Preview("Dark Mode") {
        AppLoadingView()
            .preferredColorScheme(.dark)
    }

#endif
