#!/usr/bin/env swift

import Foundation
import Security

// Quick keychain test script

struct KeychainService {
    private let service = "com.menubargpt.api"
    private let account = "OPENAI_API_KEY"
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case invalidItemFormat
        case unexpectedStatus(OSStatus)
    }
    
    func saveApiKey(_ apiKey: String) throws {
        let data = apiKey.data(using: .utf8)!
        
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
            print("✅ Successfully updated existing API key")
            return
        }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        if addStatus == errSecSuccess {
            print("✅ Successfully added new API key")
        } else {
            print("❌ Failed to add API key: \(addStatus)")
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }
    
    func getApiKey() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                print("⚠️ No API key found in keychain")
                return nil
            }
            print("❌ Failed to retrieve API key: \(status)")
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            print("❌ Invalid data format in keychain")
            throw KeychainError.invalidItemFormat
        }
        
        print("✅ Successfully retrieved API key: \(String(apiKey.prefix(10)))...")
        return apiKey
    }
    
    func hasApiKey() -> Bool {
        do {
            return try getApiKey() != nil
        } catch {
            return false
        }
    }
    
    func deleteApiKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("✅ Successfully deleted API key (or none existed)")
        } else {
            print("❌ Failed to delete API key: \(status)")
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// Test the keychain functionality
let keychain = KeychainService()

print("🔧 Testing Keychain Functionality")
print("=================================")

// Test 1: Check current state
print("\n1. Checking current API key state:")
let hasKey = keychain.hasApiKey()
print("Has API key: \(hasKey)")

// Test 2: Try to get existing key
print("\n2. Attempting to retrieve existing key:")
do {
    let existingKey = try keychain.getApiKey()
    if let key = existingKey {
        print("Found existing key: \(String(key.prefix(10)))...")
    } else {
        print("No existing key found")
    }
} catch {
    print("Error retrieving key: \(error)")
}

// Test 3: Save a test key
print("\n3. Saving test API key:")
let testKey = "sk-test123456789012345678901234567890"
do {
    try keychain.saveApiKey(testKey)
    print("Test key saved successfully!")
} catch {
    print("Failed to save test key: \(error)")
}

// Test 4: Verify the save worked
print("\n4. Verifying save operation:")
do {
    let retrievedKey = try keychain.getApiKey()
    if retrievedKey == testKey {
        print("✅ Save verification successful!")
    } else {
        print("❌ Save verification failed - keys don't match")
    }
} catch {
    print("❌ Save verification failed with error: \(error)")
}

// Test 5: Check hasApiKey function
print("\n5. Testing hasApiKey function:")
let hasKeyAfterSave = keychain.hasApiKey()
print("hasApiKey() returns: \(hasKeyAfterSave)")

// Test 6: Clean up
print("\n6. Cleaning up test key:")
do {
    try keychain.deleteApiKey()
    print("Test key deleted successfully")
} catch {
    print("Failed to delete test key: \(error)")
}

// Test 7: Final verification
print("\n7. Final verification:")
let hasKeyAfterDelete = keychain.hasApiKey()
print("hasApiKey() after deletion: \(hasKeyAfterDelete)")

print("\n🎉 Keychain test completed!")
