import Entities
import SwiftUI

struct DeviceInfoSection: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Device Information")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text("Type: \(device.type.displayName)")
                Text("Manufacturer: \(device.manufacturer)")
                Text("Model: \(device.model)")
                Text("Status: \(device.status.rawValue.capitalized)")
            }
            .font(.caption)
        }
    }
}

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

#Preview("Using Mock Data") {
    DeviceInfoSection(device: .mockLight)
        .padding()
}
