import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    enum Keys: String {
        case wallpaperSavePath
    }
    
    func setValue<T>(_ value: T, forKey key: Keys) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    func getValue<T>(forKey key: Keys) -> T? {
        return defaults.value(forKey: key.rawValue) as? T
    }
    
    func removeValue(forKey key: Keys) {
        defaults.removeObject(forKey: key.rawValue)
    }
    
    func clearAll() {
        if let domain = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: domain)
        }
    }
}
