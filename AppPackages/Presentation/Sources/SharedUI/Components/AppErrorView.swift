import Entities
import SwiftUI

public struct AppErrorView: View {
    let error: AppError
    let retryAction: () -> Void

    public init(error: AppError, retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: Spacing.section) {
            VStack(spacing: Spacing.s4) {
                Image(systemName: Icons.warning)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.red)

                Text("App Error")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(error.errorDescription ?? Strings.somethingWentWrong)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let recoverySuggestion = error.recoverySuggestion {
                VStack(spacing: Spacing.s2) {
                    Text("Suggestion")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)

                    Text(recoverySuggestion)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Spacing.s4)
            }

            Button(action: retryAction) {
                Text(Strings.retry)
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .controlSize(.large)
        }
        .padding(Spacing.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, ignoresSafeAreaEdges: .all)
    }
}

#if DEBUG

    #Preview("App Error with Recovery Suggestion") {
        let error = AppError.initializationError(
            component: "AppContainer",
            reason: "Failed to create cache directory"
        )

        AppErrorView(error: error) {
            print("Retry tapped")
        }
        .preferredColorScheme(.light)
    }

    #Preview("App Error without Recovery Suggestion") {
        let error = AppError.fileSystemError(
            operation: "create",
            path: "/invalid/path"
        )

        AppErrorView(error: error) {
            print("Retry tapped")
        }
        .preferredColorScheme(.dark)
    }

#endif
