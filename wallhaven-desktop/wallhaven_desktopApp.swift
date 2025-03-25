import Combine
import SwiftData
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    private lazy var modelContainer: ModelContainer = {
        fatalError("ModelContainer must be set using configure(context:)")
    }()

    @Published var appConfig: AppConfig = .init()
    private var appConfigModel: AppConfigModel!

    var currentStorageUsed: Int = 0
    private var cancellable: AnyCancellable?

    private init() {
        // https://rhonabwy.com/2021/02/13/nested-observable-objects-in-swiftui/
        self.cancellable = objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send()
            }
    }

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
            guard url.startAccessingSecurityScopedResource() else {
                WallhavenLogger.shared.error("Failed to start accessing security-scoped resource", showToast: true)
                return
            }

            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            appConfigModel.wallpaperSavePathData = bookmarkData
            DispatchQueue.main.async { [weak self] in
                self?.appConfig.wallpaperSavePath = url

                self?.objectWillChange.send()
            }
            try modelContainer.mainContext.save()

            url.stopAccessingSecurityScopedResource()
        } catch {
            WallhavenLogger.shared.error("Failed to set wallpaper save path: \(error.localizedDescription)", showToast: true)
        }
    }
}

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
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

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
