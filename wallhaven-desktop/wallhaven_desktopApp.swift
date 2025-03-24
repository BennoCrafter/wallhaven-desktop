import SwiftData
import SwiftUI

@MainActor
class DataManager: ObservableObject {
    static let shared = DataManager()

    private lazy var modelContainer: ModelContainer = {
        fatalError("ModelContainer must be set using configure(context:)")
    }()

    var appConfig: AppConfig!

    private init() {}

    func configure(with modelContainer: ModelContainer) {
        self.modelContainer = modelContainer

        appConfig = loadAppConfig()
    }

    func loadAppConfig() -> AppConfig {
        if let result = try! modelContainer.mainContext.fetch(FetchDescriptor<AppConfig>())
            .first
        {
            return result
        } else {
            let instance = AppConfig()
            modelContainer.mainContext.insert(instance)
            return instance
        }
    }
}

@Model
class AppConfig {
    var wallpaperSavePath: URL?

    init(wallpaperSavePath: URL? = nil) {
        self.wallpaperSavePath = wallpaperSavePath
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
            for: [AppConfig.self], isUndoEnabled: true, onSetup: handleSetup)
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
