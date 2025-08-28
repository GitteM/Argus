import SwiftUI

public struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    public init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: Spacing.m2) {
            Image(systemName: Icons.warning)
                .font(.system(size: Spacing.l4))
                .foregroundColor(.orange)

            Text(Strings.somethingWentWrong)
                .font(.headline)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if let retryAction {
                Button(Strings.retry, action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG

    #Preview("Error with Retry") {
        let message = "Failed to load data. Check connection and try again."
        ErrorView(
            message: message,
            retryAction: { print("Retry tapped") }
        )
    }

    #Preview("Error without Retry") {
        ErrorView(message: "Unable to connect to server")
    }

#endif
