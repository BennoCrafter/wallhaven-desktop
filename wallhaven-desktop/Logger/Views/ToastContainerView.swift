import SwiftUI

struct ToastContainerView: View {
    @ObservedObject private var logger = WallhavenLogger.shared
    let position: ToastPosition
    let spacing: CGFloat
    let maxWidth: CGFloat
    let showIcons: Bool

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(logger.activeToasts) { toast in
                ToastView(toast: toast, showIcon: showIcons, maxWidth: maxWidth)
                    .transition(.asymmetric(
                        insertion: .move(edge: position.edgeTransition).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(.all, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: position.alignment)
        .animation(.easeInOut, value: logger.activeToasts)
    }
}
