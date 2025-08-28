import Entities
import SharedUI
import SwiftUI

struct TemperatureSensorView: View {
    let device: Device
    let temperatureSensor: TemperatureSensor?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l2) {
            Text(Strings.temperatureSensor)
                .font(.headline)

            if let temperatureSensor {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    HStack {
                        Text("\(Strings.temperature):")
                        Text(
                            "\(temperatureSensor.temperature, specifier: "%.1f")"
                        )
                        .fontWeight(.semibold)
                        if let unit = device.unitOfMeasurement {
                            Text(unit)
                        }
                    }

                    HStack {
                        Text("\(Strings.battery):")
                        Text("\(temperatureSensor.battery)%")
                            .foregroundColor(temperatureSensor.batteryColor)
                            .fontWeight(.semibold)
                    }

                    Text(
                        "\(Strings.lastReading): \(temperatureSensor.date.abbreviatedDateTime)"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                Text(Strings.noTemperatureDataAvailable)
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

private extension TemperatureSensor {
    var batteryColor: Color {
        switch battery {
        case 0 ... 20:
            .red
        case 21 ... 50:
            .orange
        default:
            .green
        }
    }
}

#if DEBUG

    #Preview("Temperature Sensor with Data") {
        TemperatureSensorView(
            device: .mockTemperatureSensor,
            temperatureSensor: .mockTemperature
        )
        .padding()
    }

    #Preview("Low Battery") {
        TemperatureSensorView(
            device: .mockTemperatureSensor,
            temperatureSensor: .mockLowBattery
        )
        .padding()
    }

    #Preview("No Temperature Data") {
        TemperatureSensorView(
            device: .mockTemperatureSensor,
            temperatureSensor: nil
        )
        .padding()
    }

#endif
