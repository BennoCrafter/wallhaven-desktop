import SwiftUI

extension View {
    func toast(
        position: ToastPosition = .top,
        spacing: CGFloat = 8,
        maxWidth: CGFloat = 300,
        showIcons: Bool = true
    ) -> some View {
        modifier(
            ToastModifier(
                position: position,
                spacing: spacing,
                maxWidth: maxWidth,
                showIcons: showIcons
            )
        )
    }
}
