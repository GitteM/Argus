import Entities
import SwiftUI

public struct ConnectionStatusIndicator: View {
    let status: MQTTConnectionStatus
    var onTapWhenDisconnected: (() -> Void)?

    public init(
        status: MQTTConnectionStatus,
        onTapWhenDisconnected: (() -> Void)? = nil
    ) {
        self.status = status
        self.onTapWhenDisconnected = onTapWhenDisconnected
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            Text(Strings.mqtt)
                .font(.caption2)
                .foregroundColor(.secondary)
            Group {
                switch status {
                case .connecting:
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle())
                case .connected:
                    Circle()
                        .fill(Color.green)
                        .frame(width: Spacing.s4, height: Spacing.s4)
                case .disconnected:
                    Circle()
                        .fill(Color.red)
                        .frame(width: Spacing.s4, height: Spacing.s4)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: status)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if status == .disconnected {
                onTapWhenDisconnected?()
            }
        }
    }
}

struct ConnectionStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.xl2) {
            VStack {
                Text("Connected")
                    .font(.caption2)
                ConnectionStatusIndicator(status: .connected)
            }

            VStack {
                Text("Connecting")
                    .font(.caption2)
                ConnectionStatusIndicator(status: .connecting)
            }

            VStack {
                Text("Disconnected")
                    .font(.caption2)
                ConnectionStatusIndicator(status: .disconnected)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Status Indicators")
    }
}
