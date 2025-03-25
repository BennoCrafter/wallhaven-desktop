import Kingfisher
import SwiftUI

struct WallpaperDetailView: View {
    @EnvironmentObject private var dataManager: DataManager
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

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text(self.wallpaper.createdAt, format: .dateTime
                        .day(.twoDigits)
                        .month(.wide)
                        .year()
                        .hour(.twoDigits(amPM: .wide))
                        .minute())
                }

                Spacer()

                Button(action: {
                    // https://wallhaven.cc/favorites/add?wallHashid=7pd3l9&collectionId=1878962&_token=TOKEN // How to get the token?
                }) {
                    Label("Add to Favorites", systemImage: "heart.fill")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .background(.yellow.opacity(0.8))
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    downloadWallpaper { _ in
                    }
                }) {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut(.return, modifiers: .command)
                .help("Fastly download it by pressing ⌘+Enter")

                Button(action: self.applyWallpaper) {
                    Label("Apply", systemImage: "paintbrush.fill")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Wallpaper Details")
    }

    private func applyWallpaper() {
        downloadWallpaper { downloadedUrl in
            if let fileUrl = downloadedUrl {
                setDesktopWallpaper(imageURL: fileUrl)
            }
        }
    }

    private func downloadWallpaper(completion: @escaping (URL?) -> Void) {
        guard let destinationUrl = dataManager.appConfig.wallpaperSavePath?.appendingPathComponent(wallpaper.path.lastPathComponent) else {
            WallhavenLogger.shared.error("No wallpaper save path was configured", showToast: true)
            completion(nil)
            return
        }

        WallhavenLogger.shared.info("Starting download..", showToast: true)

        downloadImage(from: wallpaper.path, to: destinationUrl) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fileUrl):
                    WallhavenLogger.shared.success("Wallpaper saved to \(fileUrl)", showToast: true)
                    completion(fileUrl)
                case .failure(let error):
                    WallhavenLogger.shared.error("Failed to download wallpaper", showToast: true)
                    WallhavenLogger.shared.error("\(error)", showToast: true)
                    completion(nil)
                }
            }
        }
    }
}
