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
    case favorites = "Collections"
    case recent = "Downloads"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .favorites: return "heart"
        case .recent: return "arrow.down.circle.fill"
        case .settings: return "gear"
        }
    }
}

struct ContentView: View {
    @StateObject private var searchSettings: SearchSettings = .init()
    @State private var searchText = ""
    @State private var selectedMenuItem: MenuItem = .home
    @State private var hoveredImageID: String? = nil
    @FocusState private var searchBarIsFocused: Bool
    @State private var wallpapers: [Wallpaper] = []

    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var canLoadMore = true

    private var wallhavenAPIKey: String? { KeychainManager.shared.retrieveFromKeychain(key: .apiKeyIdentifier) }

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
                    searchBar
                    filterMenu

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

    private var searchBar: some View {
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

    private var filterMenu: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Sorting Picker
                Picker("Sort", selection: $searchSettings.sorting) {
                    ForEach(SearchSettings.Sorting.allCases, id: \.self) { sort in
                        Text(sort.name).tag(sort)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Order Picker
                Picker("Order", selection: $searchSettings.order) {
                    Text("Descending").tag(SearchSettings.Order.descending)
                    Text("Ascending").tag(SearchSettings.Order.ascending)
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Top Range Picker (conditional)
                if searchSettings.sorting == .toplist {
                    Picker("Top Range", selection: $searchSettings.topRange) {
                        ForEach(SearchSettings.TopRange.allCases, id: \.self) { range in
                            Text(range.name).tag(range)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                // Purity Picker
                Picker("Purity", selection: $searchSettings.purity) {
                    ForEach(SearchSettings.Purity.allCases, id: \.self) { purity in
                        Text(purity.name).tag(purity)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .onChange(of: searchSettings.sorting) { triggerSearch() }
        .onChange(of: searchSettings.order) { triggerSearch() }
        .onChange(of: searchSettings.topRange) { triggerSearch() }
        .onChange(of: searchSettings.purity) { triggerSearch() }
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

        if let url = URL(string: searchSettings.buildURL(query: searchText, page: currentPage, apiKey: wallhavenAPIKey)) {
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
}

#Preview {
    ContentView()
}

extension String {
    func clean() -> String {
        return replacingOccurrences(of: "\\/", with: "/")
    }
}
