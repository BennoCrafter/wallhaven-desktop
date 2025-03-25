import Cocoa

func setDesktopWallpaper(imagePath: String) {
    guard let imageURL = URL(string: "file://\(imagePath)") else {
        WallhavenLogger.shared.error("Invalid wallpaper file paht", showToast: true)
        return
    }
    setDesktopWallpaper(imageURL: imageURL)
}

func setDesktopWallpaper(imageURL: URL) {
    let workspace = NSWorkspace.shared
    let screens = NSScreen.screens

    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
        .allowClipping: true,
        .fillColor: NSColor.clear,
    ]

    for screen in screens {
        do {
            try workspace.setDesktopImageURL(imageURL, for: screen, options: options)
            WallhavenLogger.shared.success("Wallpaper set successfully on screen: \(screen)", showToast: true)
        } catch {
            WallhavenLogger.shared.error("Failed to set wallpaper: \(error)", showToast: true)
        }
    }
}
