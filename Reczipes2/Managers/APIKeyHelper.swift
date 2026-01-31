//
//  APIKeyHelper.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/29/26.
//

import Foundation

// MARK: - API Key Helper

class APIKeyHelper {
    
    /// The storage method being used (configure this for your app)
    static var storageMethod: APIKeyStorage = .keychain(key: "claudeAPIKey")
    
    /// Get the API key from configured storage
    static func getAPIKey() -> String? {
        let key = storageMethod.retrieve()
        
        if RecipeExtractorConfig.debugLogging {
            if key != nil {
                print("✅ API Key retrieved successfully")
            } else {
                print("❌ API Key not found")
            }
        }
        
        return key
    }
    
    /// Set the API key (useful for first-time setup)
    static func setAPIKey(_ key: String) -> Bool {
        switch storageMethod {
        case .keychain(let keychainKey):
            return KeychainManager.shared.save(key: keychainKey, value: key)
            
        case .userDefaults(let defaultsKey):
            UserDefaults.standard.set(key, forKey: defaultsKey)
            return true
            
        default:
            print("⚠️ Cannot programmatically set API key for current storage method")
            return false
        }
    }
    
    /// Check if API key is configured
    static var isConfigured: Bool {
        guard let key = getAPIKey(), !key.isEmpty else {
            return false
        }
        return true
    }
}
