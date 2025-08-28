import Entities
import SwiftUI

struct SmartLightView: View {
    let device: Device
    let lightState: LightState?

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Light Controls")
                .font(.headline)

            if let lightState {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Status:")
                        Text(lightState.state ? "On" : "Off")
                            .foregroundColor(lightState.state ? .green : .red)
                            .fontWeight(.semibold)
                    }

                    if let brightness = lightState.brightness {
                        HStack {
                            Text("Brightness:")
                            Text("\(brightness)%")
                                .bold()
                        }
                    }

                    Text("Last Updated: \(lightState.date.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No light state data available")
                    .foregroundColor(.secondary)
            }

            DeviceInfoSection(device: device)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

#Preview("Light On with Brightness") {
    SmartLightView(
        device: .mockLight,
        lightState: .mockOnWithBrightness
    )
    .padding()
}

#Preview("Light Off") {
    SmartLightView(
        device: .mockLight,
        lightState: .mockOff
    )
    .padding()
}

#Preview("No Light State") {
    SmartLightView(
        device: .mockLight,
        lightState: nil
    )
    .padding()
}
