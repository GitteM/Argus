import SwiftUI

public extension View {
    func onRowTap(action: @escaping () -> Void) -> some View {
        accessibility(addTraits: [.isButton])
            .accessibility(removeTraits: .isStaticText)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    func backButton(action: @escaping () -> Void) -> some View {
        toolbar {
            BackToolbarItem(action: action)
        }
    }
}
