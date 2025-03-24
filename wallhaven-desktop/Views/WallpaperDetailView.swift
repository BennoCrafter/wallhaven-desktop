import Kingfisher
import SwiftUI

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper

    var body: some View {
        VStack {
            KFImage.url(self.wallpaper.path)
                .resizable()
                .placeholder {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .scaledToFit()
                .frame(minWidth: 600, minHeight: 400)
                .cornerRadius(8)
                .shadow(radius: 3)
                .padding()

            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("\(self.wallpaper.favorites)")
                        .font(.title3)
                }

                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(.blue)
                    Text("\(self.wallpaper.views)")
                        .font(.title3)
                }

                Spacer()

                Button(action: {
                    // Add to favorites action
                }) {
                    Label("Add to Favorites", systemImage: "heart.fill")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .background(.yellow.opacity(0.8))
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    // Download action
                }) {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Wallpaper Details")
    }
}
