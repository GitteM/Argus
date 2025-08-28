import SwiftUI

public struct InfoRow: View {
    private let label: String
    private let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

#if DEBUG

    #Preview("Light Mode") {
        InfoRow(
            label: "Some label", value: "Some Value"
        )
        .preferredColorScheme(.light)
    }

    #Preview("Dark Mode") {
        InfoRow(
            label: "Some label", value: "Some Value"
        )
        .preferredColorScheme(.dark)
    }

#endif
