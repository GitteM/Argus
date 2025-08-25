import SwiftUI

public struct WarningRow: View {
    let message: String

    public init(message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: Spacing.s4) {
            Image(systemName: Icons.warning)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(.orange)
        .padding(.vertical)
    }
}

#Preview("Light Mode") {
    WarningRow(message: "Description of warning goes here...")
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WarningRow(message: "Description of warning goes here...")
        .preferredColorScheme(.dark)
}
