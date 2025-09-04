import SwiftUI

public struct DisconnectedView: View {
    let reconnectAction: () -> Void

    public init(reconnectAction: @escaping () -> Void) {
        self.reconnectAction = reconnectAction
    }

    public var body: some View {
        VStack(spacing: Spacing.section) {
            VStack(spacing: Spacing.s4) {
                Text("Connection Lost")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(Strings.unableToConnectToMQTTbroker)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: reconnectAction) {
                Text("Reconnect")
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

    #Preview("Light Mode") {
        DisconnectedView {
            print("Reconnect tapped")
        }
        .preferredColorScheme(.light)
    }

    #Preview("Dark Mode") {
        DisconnectedView {
            print("Reconnect tapped")
        }
        .preferredColorScheme(.dark)
    }

#endif
