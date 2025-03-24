import Kingfisher
import SwiftUI

struct ImageThumbnailWithTooltip: View {
    let wallpaper: Wallpaper
    let isHovered: Bool
    let onHover: (Bool) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            KFImage.url(self.wallpaper.thumbs.small)
                .resizable()
                .placeholder {
                    ProgressView()
                        .frame(width: 200, height: 150)
                }
                .scaledToFill()
                .frame(width: 200, height: 150)
                .cornerRadius(6)
                .shadow(radius: 2)
                .clipped()
                .padding(4)
                .background(Color(.windowBackgroundColor))
                .cornerRadius(8)
                .overlay(alignment: .bottom) {
                    if self.isHovered {
                        HStack {
                            HStack(spacing: 2) {
                                Text("\(self.wallpaper.favorites)")
                                Image(systemName: "star.fill")
                            }
                            HStack(spacing: 2) {
                                Text("\(self.wallpaper.views)")
                                Image(systemName: "eye.fill")
                            }
                            Spacer()
                        }
                        .padding(6)
                        .background(Color(.windowBackgroundColor).opacity(0.85))
                        .cornerRadius(6)
                        .shadow(radius: 1)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                    }
                }
                .onHover { isHovered in
                    self.onHover(isHovered)
                }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}
