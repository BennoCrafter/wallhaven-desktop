import Foundation
import SwiftUI

class Wallpaper: Codable, Identifiable {
    var id: String
    var url: URL
    var shortUrl: URL
    var views: Int
    var source: String
    var purity: WallpaperPurity
    var category: String
    var createdAt: Date
    var fileType: String
    var fileSize: Int // in bytes
    var colors: [String] // hex codes
    var path: URL
    var uploader: User?
    var thumbs: WallpaperThumbs

    // Custom DateFormatter to decode the createdAt field
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // matching your date string format
        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case shortUrl = "short_url"
        case views
        case source
        case purity
        case category
        case createdAt = "created_at"
        case fileType = "file_type"
        case fileSize = "file_size"
        case colors
        case path
        case uploader
        case thumbs
    }

    required init(id: String, url: URL, shortUrl: URL, views: Int, source: String, purity: WallpaperPurity, category: String, createdAt: Date, fileType: String, fileSize: Int, colors: [String], path: URL, uploader: User?, thumbs: WallpaperThumbs) {
        self.id = id
        self.url = url
        self.shortUrl = shortUrl
        self.views = views
        self.source = source
        self.purity = purity
        self.category = category
        self.createdAt = createdAt
        self.fileType = fileType
        self.fileSize = fileSize
        self.colors = colors
        self.path = path
        self.uploader = uploader
        self.thumbs = thumbs
    }

    // Custom decoding to handle the createdAt date format
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.url = try container.decode(URL.self, forKey: .url)
        self.shortUrl = try container.decode(URL.self, forKey: .shortUrl)
        self.views = try container.decode(Int.self, forKey: .views)
        self.source = try container.decode(String.self, forKey: .source)
        self.purity = try container.decode(WallpaperPurity.self, forKey: .purity)
        self.category = try container.decode(String.self, forKey: .category)

        // Decode the createdAt date using the custom DateFormatter
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let date = Wallpaper.dateFormatter.date(from: createdAtString) {
            self.createdAt = date
        } else {
            // If the date format is not correct, handle it as needed (e.g., throw an error or set a default value)
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format")
        }

        self.fileType = try container.decode(String.self, forKey: .fileType)
        self.fileSize = try container.decode(Int.self, forKey: .fileSize)
        self.colors = try container.decode([String].self, forKey: .colors)
        self.path = try container.decode(URL.self, forKey: .path)
        self.uploader = try container.decodeIfPresent(User.self, forKey: .uploader)
        self.thumbs = try container.decode(WallpaperThumbs.self, forKey: .thumbs)
    }
}

enum WallpaperPurity: String, Codable {
    case sfw
    case sketchy
    case nsfw
}

class WallpaperThumbs: Codable {
    let large: URL
    let original: URL
    let small: URL

    init(large: URL, original: URL, small: URL) {
        self.large = large
        self.original = original
        self.small = small
    }
}

extension Int {
    func bytesToMB() -> Double {
        return Double(self) / (1024.0 * 1024.0)
    }
}
