//
//  RecipeExtractorConfig.swift
//  Reczipes2
//
//  Configuration for Claude API recipe extraction
//

import Foundation

struct RecipeExtractorConfig {
    
    // MARK: - API Configuration
    
    /// The Claude model to use for recipe extraction
    static let claudeModel = "claude-sonnet-4-20250514"
    
    /// Maximum tokens for Claude's response
    static let maxTokens = 8192
    
    /// Image compression quality (0.0 to 1.0)
    /// Higher = better quality but larger file size
    static let imageCompressionQuality: CGFloat = 0.9
    
    /// API request timeout in seconds
    static let requestTimeout: TimeInterval = 60
    
    // MARK: - Image Preprocessing
    
    /// Default preprocessing setting
    static let defaultUsePreprocessing = true
    
    /// Contrast enhancement level (0.0 to 2.0)
    /// 1.0 = no change, >1.0 = more contrast
    static let contrastLevel: Float = 1.5
    
    /// Sharpness level (0.0 to 2.0)
    static let sharpnessLevel: Float = 0.7
    
    /// Noise reduction level (0.0 to 1.0)
    static let noiseReductionLevel: Float = 0.02
    
    // MARK: - Feature Flags
    
    /// Enable image preprocessing toggle in UI
    static let enablePreprocessingToggle = true
    
    /// Enable image comparison view
    static let enableImageComparison = true
    
    /// Show processing time in UI
    static let showProcessingTime = false
    
    /// Enable recipe editing after extraction
    static let enableRecipeEditing = false
    
    // MARK: - User Experience
    
    /// Automatically extract recipe after image selection
    static let autoExtractOnImageSelection = true
    
    /// Show detailed error messages
    static let showDetailedErrors = true
    
    /// Haptic feedback on success/error
    static let enableHapticFeedback = true
    
    // MARK: - Development/Debug
    
    /// Enable debug logging
    static let debugLogging = false
    
    /// Save preprocessed images for debugging
    static let savePreprocessedImages = false
    
    /// Log API request/response details
    static let logAPIDetails = false
}

// MARK: - API Key Management

enum APIKeyStorage {
    case environment(variableName: String)
    case keychain(key: String)
    case userDefaults(key: String) // NOT RECOMMENDED for production
    case hardcoded(key: String) // ONLY for development, NEVER commit
    
    func retrieve() -> String? {
        switch self {
        case .environment(let variableName):
            return ProcessInfo.processInfo.environment[variableName]
            
        case .keychain(let key):
            return KeychainManager.shared.get(key: key)
            
        case .userDefaults(let key):
            return UserDefaults.standard.string(forKey: key)
            
        case .hardcoded(let key):
            return key
        }
    }
}

//// MARK: - API Key Helper
//
//class APIKeyHelper {
//    
//    /// The storage method being used (configure this for your app)
//    static var storageMethod: APIKeyStorage = .keychain(key: "claudeAPIKey")
//    
//    /// Get the API key from configured storage
//    static func getAPIKey() -> String? {
//        let key = storageMethod.retrieve()
//        
//        if RecipeExtractorConfig.debugLogging {
//            if key != nil {
//                print("✅ API Key retrieved successfully")
//            } else {
//                print("❌ API Key not found")
//            }
//        }
//        
//        return key
//    }
//    
//    /// Set the API key (useful for first-time setup)
//    static func setAPIKey(_ key: String) -> Bool {
//        switch storageMethod {
//        case .keychain(let keychainKey):
//            return KeychainManager.shared.save(key: keychainKey, value: key)
//            
//        case .userDefaults(let defaultsKey):
//            UserDefaults.standard.set(key, forKey: defaultsKey)
//            return true
//            
//        default:
//            print("⚠️ Cannot programmatically set API key for current storage method")
//            return false
//        }
//    }
//    
//    /// Check if API key is configured
//    static var isConfigured: Bool {
//        guard let key = getAPIKey(), !key.isEmpty else {
//            return false
//        }
//        return true
//    }
//}
