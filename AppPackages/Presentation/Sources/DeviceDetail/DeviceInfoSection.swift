import Entities
import SharedUI
import SwiftUI

struct DeviceInfoSection: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            Text(Strings.deviceInformation)
                .font(.headline)

            VStack(alignment: .leading, spacing: Spacing.s3) {
                InfoRow(label: Strings.type, value: device.type.displayName)
                InfoRow(label: Strings.manufacturer, value: device.manufacturer)
                InfoRow(label: Strings.model, value: device.model)
                InfoRow(
                    label: Strings.status,
                    value: device.status.rawValue.capitalized
                )
            }
            .font(.caption)
        }
    }
}

#if DEBUG

    #Preview("Connected Device") {
        DeviceInfoSection(
            device: .mockLight
        )
        .padding()
    }

    #Preview("Disconnected Device") {
        DeviceInfoSection(
            device: .mockTemperatureSensor
        )
        .padding()
    }

#endif
