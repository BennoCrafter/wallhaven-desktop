import SwiftUI

struct WallpaperResponse: Codable {
    let data: [Wallpaper]
}

func loadDataFromURL(url: URL, completion: @escaping ([Wallpaper]?, Error?) -> Void) {
    // Create a URLSession data task to load data
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        // Handle errors
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
    @State private var hoveredImageID: String? = nil // Track which image is being hovered

    @FocusState private var searchBarIsFocused: Bool

    @State var wallpapers: [Wallpaper] = []

    // Sidebar menu items
    let menuItems = ["Home", "Favorites", "Recent", "Albums", "Settings"]

    var body: some View {
        NavigationSplitView {
            // Sidebar
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
                // Main content
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search wallpapers...", text: self.$searchText)
                            .textFieldStyle(.plain)
                            .focused(self.$searchBarIsFocused)

                        if !self.searchText.isEmpty {
                            Button(action: {
                                self.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // Image gallery with hover tooltips
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
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle(self.selectedMenuItem)
                .onAppear {
                    if let url = URL(string: "https://wallhaven.cc/api/v1/search") {
                        loadDataFromURL(url: url) { wallpapers, error in
                            if let error = error {
                                print("Failed to load data:", error)
                                self.wallpapers = []
                            } else if let wallpapers = wallpapers {
                                print("Loaded wallpapers:", wallpapers)
                                self.wallpapers = wallpapers
                            }
                        }
                    }
                }
            }
        }
    }

    // Function to return appropriate system icons for menu items
    func iconForMenuItem(_ item: String) -> String {
        switch item {
        case "Home": return "house"
        case "Favorites": return "heart"
        case "Recent": return "clock"
        case "Albums": return "folder"
        case "Settings": return "gear"
        default: return "circle"
        }
    }
}

// Detail view that will be displayed when a thumbnail is clicked
struct WallpaperDetailView: View {
    let wallpaper: Wallpaper

    var body: some View {
        VStack {
            AsyncImage(url: self.wallpaper.path) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .shadow(radius: 3)
                        .padding()
                case .failure:
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                        Text("Failed to load image")
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    Text("Unknown state")
                }
            }
            .frame(minWidth: 600, minHeight: 400)

            // Wallpaper information
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(self.wallpaper.favorites)")
                        .font(.title3)
                }

                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.blue)
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
            // Image
            AsyncImage(url: self.wallpaper.thumbs.small) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 200, height: 150)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 150)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .clipped()
                case .failure:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .frame(width: 200, height: 150)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                @unknown default:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .frame(width: 200, height: 150)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding(4)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .onHover { isHovered in
                self.onHover(isHovered)
            }

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
        .animation(.easeInOut(duration: 0.2), value: self.isHovered)
    }
}

// macOS specific Preview
#Preview {
    ContentView()
}

extension String {
    func clean() -> String {
        return self.replacingOccurrences(of: "\\/", with: "/")
    }
}
