import SwiftUI

struct ToastView: View {
    let toast: ToastMessage
    var showIcon: Bool = true
    var maxWidth: CGFloat = 300
    
    var body: some View {
        HStack(spacing: 12) {
            if showIcon {
                Image(systemName: toast.level.icon)
                    .foregroundColor(.white)
            }
            
            Text(toast.message)
                .foregroundColor(.white)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(toast.level.color.opacity(0.9))
        )
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        .frame(maxWidth: maxWidth)
    }
}
