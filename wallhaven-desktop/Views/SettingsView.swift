import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var dataManager: DataManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Selected Folder:")
                .font(.headline)

            Text(dataManager.appConfig.wallpaperSavePath?.path ?? "No folder selected")
                .foregroundColor(.gray)
                .padding()
                .frame(maxWidth: .infinity)
                .cornerRadius(8)

            Button("Select Folder") {
                selectFolder()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            if let url = panel.urls.first {
                dataManager.setWallpaperSavePath(url)
            }
        }
    }
}

#Preview {
    SettingsView()
}
