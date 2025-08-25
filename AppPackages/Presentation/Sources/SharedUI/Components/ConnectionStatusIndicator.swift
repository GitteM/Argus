import Entities
import SwiftUI

// TODO: Remove magic numbers and localize
public struct ConnectionStatusIndicator: View {
    let status: MQTTConnectionStatus

    public init(status: MQTTConnectionStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: Spacing.s.value) {
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
                        .frame(width: Spacing.s4.value, height: Spacing.s4.value)
                case .disconnected:
                    Circle()
                        .fill(Color.red)
                        .frame(width: Spacing.s4.value, height: Spacing.s4.value)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: status)
        }
    }
}

struct ConnectionStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Spacing.xl2.value) {
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
