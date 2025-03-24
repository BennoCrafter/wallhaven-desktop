import SwiftUI

struct ToastModifier: ViewModifier {
    let position: ToastPosition
    let spacing: CGFloat
    let maxWidth: CGFloat
    let showIcons: Bool

    func body(content: Content) -> some View {
        ZStack {
            content

            ToastContainerView(
                position: position,
                spacing: spacing,
                maxWidth: maxWidth,
                showIcons: showIcons
            )
        }
    }
}
