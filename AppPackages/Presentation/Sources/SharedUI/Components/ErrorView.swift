import SwiftUI

// FIXME: Example replace localization, images, spacing etc
public struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    public init(message: String, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
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
        .background(Color(.systemBackground))
    }
}

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
