import Kingfisher
import SwiftUI

struct WallpaperResponse: Codable {
    let data: [Wallpaper]
}

func loadDataFromURL(url: URL, completion: @escaping ([Wallpaper]?, Error?) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(nil, error)
            return
        }

        guard let data = data else {
            completion(nil, NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data found"]))
            return
        }

        do {
            let decoder = JSONDecoder()
            let wallpapers = try decoder.decode(WallpaperResponse.self, from: data).data
            completion(wallpapers, nil)
        } catch let decodingError {
            completion(nil, decodingError)
        }
    }
    task.resume()
}

enum MenuItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case favorites = "Favorites"
    case recent = "Recent"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .favorites: return "heart"
        case .recent: return "clock"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedMenuItem: MenuItem = .home
    @State private var hoveredImageID: String? = nil
    @FocusState private var searchBarIsFocused: Bool
    @State private var wallpapers: [Wallpaper] = []

    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var canLoadMore = true

    var body: some View {
        NavigationSplitView {
            List(MenuItem.allCases, id: \.self, selection: self.$selectedMenuItem) { item in
                HStack {
                    Image(systemName: item.icon)
                        .frame(width: 24, height: 24)
                    Text(item.rawValue)
                        .font(.system(size: 14))
                }
                .padding(.vertical, 2)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
        } detail: {
            detailContent()
        }
    }

    @ViewBuilder
    private func detailContent() -> some View {
        switch selectedMenuItem {
        case .home:
            NavigationStack {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search wallpapers...", text: self.$searchText)
                            .textFieldStyle(.plain)
                            .focused(self.$searchBarIsFocused)
                            .onSubmit {
                                triggerSearch()
                                self.searchBarIsFocused = false
                            }

                        if !self.searchText.isEmpty {
                            Button(action: {
                                self.searchText = ""
                                self.searchBarIsFocused = true
                                triggerSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    if !isLoading && wallpapers.isEmpty {
                        emptyResultsState
                        Spacer()
                    } else {
                        wallpaperResultsGrid
                    }
                }
                .navigationTitle(self.selectedMenuItem.rawValue)
                .onAppear {
                    loadWallpapers(page: currentPage)
                }
            }
        case .favorites:
            EmptyView()
        case .recent:
            EmptyView()
        case .settings:
            SettingsView()
        }
    }

    private var emptyResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)

            Text("No queries found")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()

            Text("Try a different search term")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var wallpaperResultsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
            ], spacing: 16) {
                ForEach(self.wallpapers) { wallpaper in
                    NavigationLink(destination: WallpaperDetailView(wallpaper: wallpaper)) {
                        ImageThumbnailWithTooltip(
                            wallpaper: wallpaper,
                            isHovered: self.hoveredImageID == wallpaper.id,
                            onHover: { isHovering in
                                self.hoveredImageID = isHovering ? wallpaper.id : nil
                            }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        loadMoreContentIfNeeded(currentItem: wallpaper)
                    }
                }
            }
            .padding()

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
    }

    private func triggerSearch() {
        wallpapers = []
        currentPage = 1
        canLoadMore = true
        loadWallpapers(page: currentPage)
    }

    func loadWallpapers(page: Int) {
        guard !isLoading && canLoadMore else { return }

        isLoading = true
        let urlString = "https://wallhaven.cc/api/v1/search?q=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&page=\(page)"

        if let url = URL(string: urlString) {
            loadDataFromURL(url: url) { wallpapers, error in
                if let error = error {
                    WallhavenLogger.shared.error("Failed to load wallpapers data: \(error)", showToast: true)
                    self.isLoading = false
                } else if let wallpapers = wallpapers {
                    self.wallpapers.append(contentsOf: wallpapers)
                    self.currentPage += 1
                    self.isLoading = false
                    self.canLoadMore = wallpapers.count > 0
                }
            }
        }
    }

    func loadMoreContentIfNeeded(currentItem item: Wallpaper) {
        let thresholdIndex = wallpapers.index(wallpapers.endIndex, offsetBy: -5)
        if let currentItemIndex = wallpapers.firstIndex(where: { $0.id == item.id }), currentItemIndex >= thresholdIndex {
            loadWallpapers(page: currentPage) // Load next page when we reach the threshold
        }
    }

    func iconForMenuItem(_ item: String) -> String {
        switch item {
        case "Home": return "house"
        case "Favorites": return "heart"
        case "Recent": return "clock"
        case "Settings": return "gear"
        default: return "circle"
        }
    }
}

#Preview {
    ContentView()
}

extension String {
    func clean() -> String {
        return replacingOccurrences(of: "\\/", with: "/")
    }
}
