import Entities
import SharedUI
import Stores
import SwiftUI

struct DeviceAvailableRow: View {
    @Environment(DeviceStore.self) private var deviceStore
    @State private var isLoading = false

    let device: DiscoveredDevice

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
        .onRowTap {
            withAnimation {
                isLoading = true
            }
            deviceStore.subscribeToDevice(device)
        }
        .onDisappear {
            isLoading = false
        }
    }
}

#if DEBUG

    #Preview("Light Mode") { @MainActor in
        List {
            DeviceAvailableRow(device: .mockNew1)
                .environment(DeviceStore.preview)
                .preferredColorScheme(.light)
        }
    }

    #Preview("Dark Mode") { @MainActor in
        List {
            DeviceAvailableRow(device: .mockNew2)
                .environment(DeviceStore.preview)
                .preferredColorScheme(.dark)
        }
    }

#endif
