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
            let isStale = appConfig.configureWallpaperSavePath(wallpaperSavePathData: wallpaperSavePathData)
            if isStale {
                if let url = appConfig.wallpaperSavePath {
                    WallhavenLogger.shared.info("Wallpaper save path is stale. Try refreshing it..")
                    appConfigModel.bookmarkWallpaperSavePath(url)
                }
            }
        }
    }

    func loadAppConfigModel() -> AppConfigModel {
        if let result = try! modelContainer.mainContext.fetch(FetchDescriptor<AppConfigModel>())
            .first
        {
            return result
        } else {
            let instance = AppConfigModel()
            modelContainer.mainContext.insert(instance)
            return instance
        }
    }

    func setWallpaperSavePath(_ url: URL) {
        appConfigModel.bookmarkWallpaperSavePath(url)
        if let data = appConfigModel.wallpaperSavePathData {
            _ = appConfig.configureWallpaperSavePath(wallpaperSavePathData: data)
        }
        try? modelContainer.mainContext.save()
    }
}

@Model
class AppConfigModel {
    var wallpaperSavePathData: Data?

    init(wallpaperSavePathData: Data? = nil) {
        self.wallpaperSavePathData = wallpaperSavePathData
    }

    func bookmarkWallpaperSavePath(_ url: URL) {
        do {
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
