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

struct ContentView: View {
    @State private var searchText = ""
    @State private var selectedMenuItem = "Home"
    @State private var hoveredImageID: String? = nil
    @FocusState private var searchBarIsFocused: Bool
    @State private var wallpapers: [Wallpaper] = []

    @State private var currentPage = 1
    @State private var isLoading = false
    @State private var canLoadMore = true

    let menuItems = ["Home", "Favorites", "Recent", "Settings"]

    var body: some View {
        NavigationSplitView {
            List(self.menuItems, id: \.self, selection: self.$selectedMenuItem) { item in
                HStack {
                    Image(systemName: self.iconForMenuItem(item))
                        .frame(width: 24, height: 24)
                    Text(item)
                        .font(.system(size: 14))
                }
                .padding(.vertical, 2)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 200)
        } detail: {
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
                        Spacer()
                    } else {
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
                }
                .navigationTitle(self.selectedMenuItem)
                .onAppear {
                    loadWallpapers(page: currentPage)
                }
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
                    print("Failed to load data:", error)
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

#Preview {
    ContentView()
}

extension String {
    func clean() -> String {
        return replacingOccurrences(of: "\\/", with: "/")
    }
}
