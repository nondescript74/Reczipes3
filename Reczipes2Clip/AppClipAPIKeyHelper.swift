//
//  AppClipAPIKeyHelper.swift
//  Reczipes2Clip
//
//  API key management for the App Clip.
//  Reads from and writes to a shared App Group Keychain so the main app
//  and the App Clip can exchange the key securely — no plaintext in UserDefaults.
//
//  TARGET MEMBERSHIP: Reczipes2Clip only
//

import Foundation

// MARK: - App Clip API Key Helper

/// Lightweight, secure API-key helper for the App Clip.
///
/// Storage hierarchy (tried in order on read):
///   1. Shared App-Group Keychain  – written by the main app OR by this helper
///   2. App Clip's own Keychain    – fallback; written here when the user enters
///                                    a key before ever opening the main app
///
/// On write we always persist to *both* so the main app can pick it up later.
struct AppClipAPIKeyHelper {

    // MARK: - Constants

    /// Must match the App Group configured in Xcode for both targets.
    private static let appGroupID = "group.com.headydiscy.reczipes"

    /// Keychain account label used in the shared App-Group Keychain.
    private static let sharedKeychainKey = "claudeAPIKey"

    /// Keychain account label used in the App Clip's own (non-shared) Keychain.
    /// A different label avoids collisions if both keychains are ever queried
    /// on the same device in the same process.
    private static let clipKeychainKey = "clipClaudeAPIKey"

    // MARK: - Public API

    /// `true` when a valid key is available from either Keychain.
    static var isConfigured: Bool {
        getAPIKey() != nil
    }

    /// Retrieve the API key.  Returns `nil` when nothing has been stored yet.
    static func getAPIKey() -> String? {
        // 1. Shared App-Group Keychain (preferred – main app writes here)
        if let key = readFromKeychain(account: sharedKeychainKey, accessGroup: appGroupID) {
            return key
        }
        // 2. App Clip's own Keychain (fallback – written before main app is installed)
        return readFromKeychain(account: clipKeychainKey, accessGroup: nil)
    }

    /// Persist the API key.  Writes to both the shared and clip-local Keychains
    /// so the main app can pick it up via App Groups, and so the clip itself can
    /// read it back even if the shared Keychain is not yet available.
    @discardableResult
    static func setAPIKey(_ key: String) -> Bool {
        let sharedOK = writeToKeychain(key, account: sharedKeychainKey, accessGroup: appGroupID)
        let clipOK  = writeToKeychain(key, account: clipKeychainKey,   accessGroup: nil)
        return sharedOK || clipOK   // succeed as long as at least one store worked
    }

    // MARK: - Private Keychain Helpers

    /// Read a string value from the Keychain.
    /// - `accessGroup`: pass the App-Group identifier for shared access, or `nil`
    ///   for the app's own Keychain.
    private static func readFromKeychain(account: String, accessGroup: String?) -> String? {
        var query: [String: Any] = [
            kSecClass            as String: kSecClassGenericPassword,
            kSecAttrAccount      as String: account,
            kSecReturnData       as String: true,
            kSecMatchLimit       as String: kSecMatchLimitOne
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else { return nil }

        return String(data: data, encoding: .utf8)
    }

    /// Write a string value to the Keychain, replacing any existing entry.
    /// - `accessGroup`: pass the App-Group identifier for shared access, or `nil`
    ///   for the app's own Keychain.
    private static func writeToKeychain(_ value: String, account: String, accessGroup: String?) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        var attributes: [String: Any] = [
            kSecClass            as String: kSecClassGenericPassword,
            kSecAttrAccount      as String: account,
            kSecValueData        as String: data,
            kSecAttrAccessible   as String: kSecAttrAccessibleWhenUnlocked
        ]
        if let group = accessGroup {
            attributes[kSecAttrAccessGroup as String] = group
        }

        // Delete any existing entry first (SecItemUpdate is finicky)
        var deleteQuery: [String: Any] = [
            kSecClass       as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        if let group = accessGroup {
            deleteQuery[kSecAttrAccessGroup as String] = group
        }
        SecItemDelete(deleteQuery as CFDictionary)

        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }
}
