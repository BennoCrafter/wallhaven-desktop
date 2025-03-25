import Foundation

class SearchSettings: ObservableObject, Equatable {
    enum Sorting: String, CaseIterable, Identifiable, Equatable {
        case dateAdded = "date_added"
        case relevance, random, views, favorites, toplist
        
        var name: String { rawValue }
        var id: String { rawValue }
    }
    
    enum Order: String, Equatable {
        case descending = "desc"
        case ascending = "asc"
    }
    
    enum TopRange: String, Equatable, CaseIterable, Identifiable {
        case oneDay = "1d"
        case threeDays = "3d"
        case oneWeek = "1w"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1y"
        
        var name: String { rawValue }
        var id: String { rawValue }
    }
    
    struct Filters: Equatable {
        var tags: [String] = []
        var excludedTags: [String] = []
        var requiredTags: [String] = []
        var username: String?
        var exactTagID: Int?
        var fileType: String?
        var similarTo: Int?
    }
    
    struct Category: Equatable {
        var general: Bool = true
        var anime: Bool = true
        var people: Bool = true
    }
    
    struct Purity: Equatable {
        var sfw: Bool = true
        var sketchy: Bool = false
        var nsfw: Bool = false
    }
    
    @Published var sorting: Sorting = .dateAdded
    @Published var order: Order = .descending
    @Published var topRange: TopRange? = .oneMonth
    @Published var minimumResolution: String?
    @Published var resolutions: [String] = []
    @Published var ratios: [String] = []
    @Published var colors: [String] = []
    @Published var seed: String?
    @Published var filters = Filters()
    @Published var categories = Category()
    @Published var purity = Purity()

    // Equatable conformance for SearchSettings
    static func == (lhs: SearchSettings, rhs: SearchSettings) -> Bool {
        return lhs.sorting == rhs.sorting &&
            lhs.order == rhs.order &&
            lhs.topRange == rhs.topRange &&
            lhs.minimumResolution == rhs.minimumResolution &&
            lhs.resolutions == rhs.resolutions &&
            lhs.ratios == rhs.ratios &&
            lhs.colors == rhs.colors &&
            lhs.seed == rhs.seed &&
            lhs.filters == rhs.filters &&
            lhs.categories == rhs.categories &&
            lhs.purity == rhs.purity
    }
    
    func buildURL(query: String, page: Int) -> String {
        var components = URLComponents(string: "https://wallhaven.cc/api/v1/search")!
        var queryItems: [URLQueryItem] = []
        
        queryItems.append(URLQueryItem(name: "q", value: query))
        
        let queryParts = filters.tags.map { "\($0)" } +
            filters.excludedTags.map { "-\($0)" } +
            filters.requiredTags.map { "+\($0)" }
        
        if let username = filters.username {
            queryItems.append(URLQueryItem(name: "q", value: "@\(username)"))
        } else if let exactTagID = filters.exactTagID {
            queryItems.append(URLQueryItem(name: "q", value: "id:\(exactTagID)"))
        } else if !queryParts.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: queryParts.joined(separator: " ")))
        }
        
        if let fileType = filters.fileType {
            queryItems.append(URLQueryItem(name: "q", value: "type:\(fileType)"))
        }
        
        if let similarTo = filters.similarTo {
            queryItems.append(URLQueryItem(name: "q", value: "like:\(similarTo)"))
        }
        
        let categoriesValue = "\(categories.general ? "1" : "0")\(categories.anime ? "1" : "0")\(categories.people ? "1" : "0")"
        queryItems.append(URLQueryItem(name: "categories", value: categoriesValue))
        
        let purityValue = "\(purity.sfw ? "1" : "0")\(purity.sketchy ? "1" : "0")\(purity.nsfw ? "1" : "0")"
        queryItems.append(URLQueryItem(name: "purity", value: purityValue))
        
        queryItems.append(URLQueryItem(name: "sorting", value: sorting.rawValue))
        queryItems.append(URLQueryItem(name: "order", value: order.rawValue))
        
        if let topRange = topRange, sorting == .toplist {
            queryItems.append(URLQueryItem(name: "topRange", value: topRange.rawValue))
        }
        
        if let minimumResolution = minimumResolution {
            queryItems.append(URLQueryItem(name: "atleast", value: minimumResolution))
        }
        
        if !resolutions.isEmpty {
            queryItems.append(URLQueryItem(name: "resolutions", value: resolutions.joined(separator: ",")))
        }
        
        if !ratios.isEmpty {
            queryItems.append(URLQueryItem(name: "ratios", value: ratios.joined(separator: ",")))
        }
        
        if !colors.isEmpty {
            queryItems.append(URLQueryItem(name: "colors", value: colors.joined(separator: ",")))
        }
        
        queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        
        if let seed = seed {
            queryItems.append(URLQueryItem(name: "seed", value: seed))
        }
        
        components.queryItems = queryItems
        return components.url?.absoluteString ?? ""
    }
}
