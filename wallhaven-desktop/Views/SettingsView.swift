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
                
                Section(header: Text("Wallhaven API Key").font(.headline)) {
                    APIKeySettingsView()
                }
                
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

struct APIKeySettingsView: View {
    @State private var apiKey = ""
    @State private var isAPIKeyVisible = false
    
    private let keychainManager = KeychainManager.shared
    private let apiKeyIdentifier = "com.wallhaven-desktop.wallhavenAPIKey"
    @FocusState private var apiKeyFieldFocused: Bool
    
    var body: some View {
        HStack {
            Group {
                if isAPIKeyVisible {
                    TextField("Enter API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            saveAPIKey()
                        }
                        .focused($apiKeyFieldFocused)
                } else {
                    SecureField("Enter API Key", text: $apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            saveAPIKey()
                        }
                        .focused($apiKeyFieldFocused)
                }
            }
            
            Button(action: {
                saveAPIKey()
            }) {
                Image(systemName: "checkmark")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
                    
            Button(action: { isAPIKeyVisible.toggle() }) {
                Image(systemName: isAPIKeyVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear(perform: checkAPIKey)
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else {
            WallhavenLogger.shared.error("API Key cannot be empty!", showToast: true)
            return
        }
        
        let success = keychainManager.saveToKeychain(key: apiKeyIdentifier, value: apiKey)
        
        if success {
            apiKeyFieldFocused = false
            isAPIKeyVisible = false
            WallhavenLogger.shared.success("API Key saved successfully", showToast: true)
        } else {
            WallhavenLogger.shared.error("Failed to save API Key", showToast: true)
        }
    }
    
    private func checkAPIKey() {
        apiKey = getAPIKey() ?? ""
    }
    
    // Method to retrieve the API key when needed
    func getAPIKey() -> String? {
        return keychainManager.retrieveFromKeychain(key: apiKeyIdentifier)
    }
}

#Preview {
    APIKeySettingsView()
        .frame(width: 500, height: 200)
}
