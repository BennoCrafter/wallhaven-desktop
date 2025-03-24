import Cocoa

func setDesktopWallpaper(imagePath: String) {
    guard let imageURL = URL(string: "file://\(imagePath)") else {
        print("Invalid file path")
        return
    }
    setDesktopWallpaper(imageURL: imageURL)
}

func setDesktopWallpaper(imageURL: URL) {
    let workspace = NSWorkspace.shared
    let screens = NSScreen.screens

    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue, // Scales image while maintaining aspect ratio
        .allowClipping: false, // Prevents cropping; entire image is shown even if it doesn't fill the screen
        .fillColor: NSColor.clear, // Transparent background if image doesn't cover the full screen
    ]

    for screen in screens {
        do {
            try workspace.setDesktopImageURL(imageURL, for: screen, options: options)
            print("Wallpaper set successfully on screen: \(screen)")
        } catch {
            print("Failed to set wallpaper: \(error)")
        }
    }
}
