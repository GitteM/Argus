import Entities
import SharedUI
import SwiftUI

struct DeviceAvailableRow: View {
    let device: DiscoveredDevice
    @State private var isLoading = false

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: device.type.icon)
                .foregroundColor(.accentColor)
                .frame(width: Spacing.m3, height: Spacing.m3)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(device.name)
                Text(device.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: Icons.plusCircle)
                    .foregroundColor(.green)
            }
        }
        .onTapGesture {
            withAnimation {
                isLoading.toggle()
            }
        }
    }
}

#Preview("Light Mode") {
    List {
        DeviceAvailableRow(device: .mockAdded1)
            .preferredColorScheme(.light)
    }
}

#Preview("Dark Mode") {
    List {
        DeviceAvailableRow(device: .mockAdded1)
            .preferredColorScheme(.dark)
    }
}
