import Entities
import SharedUI
import SwiftUI

struct DeviceSubscribedRow: View {
    let device: Device

    private var deviceDetails: String {
        "\(device.manufacturer) | \(device.type.displayName)"
    }

    var body: some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: device.type.icon)
                .foregroundColor(.accentColor)
                .frame(width: Spacing.m3, height: Spacing.m3)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(device.name)
                Text(deviceDetails)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: Icons.chevronRight)
                .foregroundColor(.secondary)
        }
    }
}

#if DEBUG

    #Preview("Light Mode") {
        List {
            DeviceSubscribedRow(device: .mockLight)
                .preferredColorScheme(.light)
        }
    }

    #Preview("Dark Mode") {
        List {
            DeviceSubscribedRow(device: .mockLight)
                .preferredColorScheme(.dark)
        }
    }

#endif
