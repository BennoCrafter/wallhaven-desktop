import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    enum Keys: String {
        case apiKeyIdentifier = "com.wallhaven-desktop.wallhavenAPIKey"
    }

    private init() {}
    
    func saveToKeychain(key: Keys, value: String) -> Bool {
        let data = value.data(using: .utf8)!
        
        _ = deleteFromKeychain(key: key)
        
        // Keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    func retrieveFromKeychain(key: Keys) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        
        return value
    }
    
    func deleteFromKeychain(key: Keys) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
