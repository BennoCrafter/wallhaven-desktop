import SwiftData
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    private lazy var modelContainer: ModelContainer = {
        fatalError("ModelContainer must be set using configure(context:)")
    }()

    var appConfig: AppConfig = .init()
    private var appConfigModel: AppConfigModel!

    private init() {}

    func configure(with modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        appConfigModel = loadAppConfigModel()
        if let wallpaperSavePathData = appConfigModel.wallpaperSavePathData {
            do {
                var bookmarkDataIsStale = false
                let url = try URL(
                    resolvingBookmarkData: wallpaperSavePathData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &bookmarkDataIsStale
                )

                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    WallhavenLogger.shared.error("Failed to access security-scoped resource", showToast: true)
                    return
                }

                // Check if the bookmark is stale and update if necessary
                if bookmarkDataIsStale {
                    WallhavenLogger.shared.info("Bookmark is stale. Updating...")
                    setWallpaperSavePath(url)
                }

                appConfig.wallpaperSavePath = url
            } catch {
                WallhavenLogger.shared.error("Failed to resolve bookmark: \(error.localizedDescription)", showToast: true)
            }
        }
    }

    func loadAppConfigModel() -> AppConfigModel {
        if let result = try? modelContainer.mainContext.fetch(FetchDescriptor<AppConfigModel>()).first {
            return result
        } else {
            let instance = AppConfigModel()
            modelContainer.mainContext.insert(instance)
            return instance
        }
    }

    func setWallpaperSavePath(_ url: URL) {
        do {
            // Ensure we can access the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                WallhavenLogger.shared.error("Failed to start accessing security-scoped resource", showToast: true)
                return
            }

            // Create bookmark data
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            // Update the model
            appConfigModel.wallpaperSavePathData = bookmarkData
            appConfig.wallpaperSavePath = url

            // Save the context
            try modelContainer.mainContext.save()

            // Stop accessing the security-scoped resource when done
            url.stopAccessingSecurityScopedResource()
        } catch {
            WallhavenLogger.shared.error("Failed to set wallpaper save path: \(error.localizedDescription)", showToast: true)
        }
    }

    // Utility method to safely access the bookmarked URL
    func withBookmarkedURL<T>(perform action: (URL) throws -> T) rethrows -> T? {
        guard let bookmarkData = appConfigModel.wallpaperSavePathData else {
            WallhavenLogger.shared.error("No bookmark data available", showToast: true)
            return nil
        }

        do {
            var bookmarkDataIsStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &bookmarkDataIsStale
            )

            // Start accessing the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                WallhavenLogger.shared.error("Failed to access security-scoped resource", showToast: true)
                return nil
            }

            // Perform the action
            defer { url.stopAccessingSecurityScopedResource() }
            return try action(url)
        } catch {
            WallhavenLogger.shared.error("Error accessing bookmarked URL: \(error.localizedDescription)", showToast: true)
            return nil
        }
    }
}

// Utility download function
func downloadImage(from sourceURL: URL, to destinationURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
    let task = URLSession.shared.dataTask(with: sourceURL) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NSError(domain: "DownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            return
        }

        do {
            // Ensure the destination directory exists
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // Write the data
            try data.write(to: destinationURL)
            completion(.success(destinationURL))
        } catch {
            completion(.failure(error))
        }
    }

    task.resume()
}

@Model
class AppConfigModel {
    var wallpaperSavePathData: Data?

    init(wallpaperSavePathData: Data? = nil) {
        self.wallpaperSavePathData = wallpaperSavePathData
    }

    func bookmarkWallpaperSavePath(_ url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                // Handle the failure here.
                return
            }

            // Make sure you release the security-scoped resource when you finish.
            defer { url.stopAccessingSecurityScopedResource() }

            wallpaperSavePathData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            WallhavenLogger.shared.error("Failed to bookmakr wallpaper save path url", showToast: true)
        }
    }
}

class AppConfig: ObservableObject {
    @Published var wallpaperSavePath: URL?

    func configureWallpaperSavePath(wallpaperSavePathData: Data) -> Bool {
        var bookmarkDataIsStale = false
        do {
            let bookmarkDataURL = try URL(
                resolvingBookmarkData: wallpaperSavePathData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &bookmarkDataIsStale
            )
            wallpaperSavePath = bookmarkDataURL
            return bookmarkDataIsStale
        } catch {
            WallhavenLogger.shared.error("Failed to load wallpaper save path", showToast: true)
            return true
        }
    }
}

@main
struct wallhaven_desktopApp: App {
    @StateObject private var dataManager: DataManager = .shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .toast(position: .topTrailing)
        }
        .modelContainer(
            for: [AppConfigModel.self], isUndoEnabled: true, onSetup: handleSetup
        )
    }

    func handleSetup(result: Result<ModelContainer, Error>) {
        switch result {
        case .success(let modelContainer):
            dataManager.configure(with: modelContainer)
        case .failure(let error):
            WallhavenLogger.shared.error("Model Container setup: \(error.localizedDescription)")
        }
    }
}
