import AppKit
import SwiftUI

struct SettingsView: View {
    @State private var selectedFolder: URL?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Selected Folder:")
                .font(.headline)
            
            Text(selectedFolder?.path ?? "No folder selected")
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
            selectedFolder = panel.urls.first
        }
    }
}

#Preview {
    SettingsView()
}
