import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Section(header: Text("Wallpaper Storage").font(.headline)) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.accentColor)
                        
                        Text(dataManager.appConfig.wallpaperSavePath?.path ?? "No folder selected")
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Change Folder") {
                        selectFolder()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Section(header: Text("Preferences").font(.headline)) {}
                
                Section(header: Text("Storage Management").font(.headline)) {
                    HStack {
                        Text("Current Storage Used")
                        Spacer()
                        Text(formatStorageSize(dataManager.currentStorageUsed))
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Clear Cached Wallpapers") {
                        // dataManager.clearCachedWallpapers()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to save wallpapers"
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        if panel.runModal() == .OK {
            if let url = panel.urls.first {
                dataManager.setWallpaperSavePath(url)
            }
        }
    }
    
    private func formatStorageSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    SettingsView()
        .environmentObject(DataManager.shared)
        .frame(width: 500, height: 600)
}
