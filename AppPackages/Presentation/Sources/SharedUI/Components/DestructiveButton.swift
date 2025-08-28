import SwiftUI

public struct DestructiveButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .padding()
    }
}

#Preview {
    DestructiveButton(
        title: "Unsubscribe from Device"
    ) {
        print("Unsubscribe from Device tapped")
    }
}
