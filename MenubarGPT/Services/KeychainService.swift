import Foundation
import Security

/// Service for securely storing and retrieving API keys using macOS Keychain
final class KeychainService {
    
    /// Errors that can occur during keychain operations
    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
        
        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "The API key was not found in the keychain."
            case .duplicateItem:
                return "An API key already exists in the keychain."
            case .invalidItemFormat:
                return "The keychain item format is invalid."
            case .unexpectedPasswordData:
                return "The password data format is unexpected."
            case .unhandledError(let status):
                return "Keychain error: \(status)"
            }
        }
    }
    
    private let service = "com.menubargpt.api"
    private let account = "OPENAI_API_KEY"
    
    static let shared = KeychainService()
    
    private init() {}
    
    /// Save API key to keychain
    func saveApiKey(_ apiKey: String) throws {
        let data = apiKey.data(using: .utf8)!
        
        // First, try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return // Successfully updated existing item
        }
        
        // If update failed, try to add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard addStatus == errSecSuccess else {
            throw KeychainError.unhandledError(status: addStatus)
        }
    }
    
    /// Retrieve API key from keychain
    func getApiKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            } else {
                throw KeychainError.unhandledError(status: status)
            }
        }
        
        guard let data = dataTypeRef as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedPasswordData
        }
        
        return apiKey
    }
    
    /// Delete API key from keychain
    func deleteApiKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Check if API key exists in keychain
    func hasApiKey() -> Bool {
        do {
            return try getApiKey() != nil
        } catch {
            return false
        }
    }
    
    /// Validate API key format - relaxed validation
    static func isValidApiKeyFormat(_ apiKey: String) -> Bool {
        // OpenAI API keys start with "sk-" and are at least 20 characters
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("sk-") && trimmed.count >= 20
    }
}

// MARK: - Convenience Methods
extension KeychainService {
    
    /// Save API key with validation
    func saveValidatedApiKey(_ apiKey: String) throws {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else {
            throw ValidationError.emptyApiKey
        }
        
        guard Self.isValidApiKeyFormat(trimmedKey) else {
            throw ValidationError.invalidApiKeyFormat
        }
        
        try saveApiKey(trimmedKey)
    }
    
    enum ValidationError: Error, LocalizedError {
        case emptyApiKey
        case invalidApiKeyFormat
        
        var errorDescription: String? {
            switch self {
            case .emptyApiKey:
                return "API key cannot be empty."
            case .invalidApiKeyFormat:
                return "API key format is invalid. OpenAI API keys start with 'sk-'."
            }
        }
    }
}

// MARK: - Preview/Test Support
#if DEBUG
extension KeychainService {
    /// Clear all keychain items for testing
    func clearForTesting() throws {
        try deleteApiKey()
    }
}
#endif// improve keychain error handling
// Security: enhance key storage validation
// Fix: resolve memory leak issue
// Security: implement key rotation
// Refactor: modernize async patterns
