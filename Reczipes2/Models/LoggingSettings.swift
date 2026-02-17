//
//  LoggingSettings.swift
//  Reczipes2
//
//  Created on February 12, 2026.
//

import Foundation
import SwiftUI
import Combine

/// User-configurable logging settings for performance optimization
@Observable
final class LoggingSettings {
    
    // MARK: - Singleton
    
    @MainActor static let shared = LoggingSettings()
    
    // MARK: - UserDefaults Keys
    
    nonisolated private static let loggingLevelKey = "com.reczipes.logging.level"
    nonisolated private static let enableFileLoggingKey = "com.reczipes.logging.fileLogging"
    nonisolated private static let enabledCategoriesKey = "com.reczipes.logging.categories"
    
    // MARK: - Logging Level
    
    /// Logging levels from least to most verbose
    enum LoggingLevel: String, CaseIterable, Identifiable {
        case off = "Off"
        case errors = "Errors Only"
        case warnings = "Warnings & Errors"
        case info = "Info, Warnings & Errors"
        case debug = "All (Debug Mode)"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .off:
                return "No logging - best performance"
            case .errors:
                return "Only critical errors - minimal impact"
            case .warnings:
                return "Warnings and errors - slight impact"
            case .info:
                return "General information - moderate impact"
            case .debug:
                return "Everything including debug - performance impact"
            }
        }
    }
    
    // MARK: - Category-Specific Logging
    
    /// Specific logging categories that can be individually enabled/disabled
    enum LoggingCategory: String, CaseIterable, Identifiable {
        case general = "General"
        case allergen = "Allergen Detection"
        case fodmap = "FODMAP Analysis"
        case recipe = "Recipe Operations"
        case network = "Network Requests"
        case storage = "Data Storage"
        case ui = "UI Events"
        case extraction = "Recipe Extraction"
        case image = "Image Processing"
        case cloudkit = "CloudKit Sync"
        case analytics = "Analytics"
        
        var id: String { rawValue }
        
        var systemImage: String {
            switch self {
            case .general: return "gear"
            case .allergen: return "exclamationmark.triangle"
            case .fodmap: return "leaf.circle"
            case .recipe: return "book.closed"
            case .network: return "network"
            case .storage: return "cylinder"
            case .ui: return "apps.iphone"
            case .extraction: return "doc.text.magnifyingglass"
            case .image: return "photo"
            case .cloudkit: return "icloud"
            case .analytics: return "chart.bar"
            }
        }
        
        var description: String {
            switch self {
            case .general: return "General app operations"
            case .allergen: return "Allergen detection and matching"
            case .fodmap: return "FODMAP analysis"
            case .recipe: return "Recipe CRUD operations"
            case .network: return "API calls and network activity"
            case .storage: return "Database and file operations"
            case .ui: return "User interface events"
            case .extraction: return "Recipe extraction from text/images"
            case .image: return "Image processing and compression"
            case .cloudkit: return "iCloud synchronization"
            case .analytics: return "Usage analytics and metrics"
            }
        }
    }
    
    // MARK: - Properties
    
    /// Overall logging level (default: errors only)
    var loggingLevel: LoggingLevel {
        didSet {
            UserDefaults.standard.set(loggingLevel.rawValue, forKey: Self.loggingLevelKey)
        }
    }
    
    /// Whether to write logs to file (default: true)
    var enableFileLogging: Bool {
        didSet {
            UserDefaults.standard.set(enableFileLogging, forKey: Self.enableFileLoggingKey)
        }
    }
    
    /// Set of enabled logging categories
    var enabledCategories: Set<LoggingCategory> {
        didSet {
            let rawValues = enabledCategories.map { $0.rawValue }
            UserDefaults.standard.set(rawValues, forKey: Self.enabledCategoriesKey)
        }
    }
    
    // MARK: - Convenience Properties
    
    /// Quick toggle for performance-critical logging (extraction, image, network)
    var enablePerformanceLogging: Bool {
        get {
            enabledCategories.contains(.extraction) && 
            enabledCategories.contains(.image) && 
            enabledCategories.contains(.network)
        }
        set {
            if newValue {
                enabledCategories.insert(.extraction)
                enabledCategories.insert(.image)
                enabledCategories.insert(.network)
            } else {
                enabledCategories.remove(.extraction)
                enabledCategories.remove(.image)
                enabledCategories.remove(.network)
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load logging level
        if let savedLevel = UserDefaults.standard.string(forKey: Self.loggingLevelKey),
           let level = LoggingLevel(rawValue: savedLevel) {
            self.loggingLevel = level
        } else {
            self.loggingLevel = .errors // Default: errors only for best performance
        }
        
        // Load file logging preference
        if UserDefaults.standard.object(forKey: Self.enableFileLoggingKey) != nil {
            self.enableFileLogging = UserDefaults.standard.bool(forKey: Self.enableFileLoggingKey)
        } else {
            self.enableFileLogging = true // Default: enabled
        }
        
        // Load enabled categories
        if let savedCategories = UserDefaults.standard.array(forKey: Self.enabledCategoriesKey) as? [String] {
            self.enabledCategories = Set(savedCategories.compactMap { LoggingCategory(rawValue: $0) })
        } else {
            // Default: only essential categories
            self.enabledCategories = [.general, .recipe, .cloudkit]
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if a specific category should be logged (thread-safe)
    nonisolated func shouldLog(category: String) -> Bool {
        // Read directly from UserDefaults for thread safety
        let levelString = UserDefaults.standard.string(forKey: Self.loggingLevelKey) ?? LoggingLevel.errors.rawValue
        guard let level = LoggingLevel(rawValue: levelString) else {
            return false
        }
        
        // If logging is completely off, don't log anything
        if level == .off {
            return false
        }
        
        // Get enabled categories from UserDefaults
        let savedCategories = UserDefaults.standard.array(forKey: Self.enabledCategoriesKey) as? [String] ?? []
        let categories = Set(savedCategories.compactMap { LoggingCategory(rawValue: $0) })
        
        // Check if the category is enabled
        guard let logCategory = LoggingCategory(rawValue: category.capitalized) else {
            // Unknown categories default to general
            return categories.contains(.general)
        }
        
        return categories.contains(logCategory)
    }
    
    /// Check if a specific log level should be logged (thread-safe)
    nonisolated func shouldLog(level: LogLevel) -> Bool {
        // Read directly from UserDefaults for thread safety
        let levelString = UserDefaults.standard.string(forKey: Self.loggingLevelKey) ?? LoggingLevel.errors.rawValue
        guard let loggingLevel = LoggingLevel(rawValue: levelString) else {
            return false
        }
        
        switch loggingLevel {
        case .off:
            return false
        case .errors:
            return level == .error || level == .critical
        case .warnings:
            return level == .warning || level == .error || level == .critical
        case .info:
            return level == .info || level == .warning || level == .error || level == .critical
        case .debug:
            return true // Log everything
        }
    }
    
    /// Check if file logging is enabled (thread-safe)
    nonisolated var isFileLoggingEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enableFileLoggingKey) == nil ? true : UserDefaults.standard.bool(forKey: Self.enableFileLoggingKey)
    }
    
    /// Reset to default settings
    func resetToDefaults() {
        loggingLevel = .errors
        enableFileLogging = true
        enabledCategories = [.general, .recipe, .cloudkit]
    }
    
    /// Enable all logging for troubleshooting
    func enableFullLogging() {
        loggingLevel = .debug
        enableFileLogging = true
        enabledCategories = Set(LoggingCategory.allCases)
    }
    
    /// Disable all logging for maximum performance
    func disableAllLogging() {
        loggingLevel = .off
        enableFileLogging = false
        enabledCategories = []
    }
}

// MARK: - Thread-Safe Logging Helper

/// Thread-safe helper for checking logging settings without accessing the shared instance
enum LoggingHelper {
    /// Check if a specific category should be logged (thread-safe)
    nonisolated static func shouldLog(category: String) -> Bool {
        // Read directly from UserDefaults for thread safety
        let levelString = UserDefaults.standard.string(forKey: "com.reczipes.logging.level") ?? "Errors Only"
        guard let level = LoggingSettings.LoggingLevel(rawValue: levelString) else {
            return false
        }
        
        // If logging is completely off, don't log anything
        if level == .off {
            return false
        }
        
        // Get enabled categories from UserDefaults
        let savedCategories = UserDefaults.standard.array(forKey: "com.reczipes.logging.categories") as? [String] ?? []
        let categories = Set(savedCategories.compactMap { LoggingSettings.LoggingCategory(rawValue: $0) })
        
        // Check if the category is enabled
        guard let logCategory = LoggingSettings.LoggingCategory(rawValue: category.capitalized) else {
            // Unknown categories default to general
            return categories.contains(.general)
        }
        
        return categories.contains(logCategory)
    }
    
    /// Check if a specific log level should be logged (thread-safe)
    nonisolated static func shouldLog(level: LogLevel) -> Bool {
        // Read directly from UserDefaults for thread safety
        let levelString = UserDefaults.standard.string(forKey: "com.reczipes.logging.level") ?? "Errors Only"
        guard let loggingLevel = LoggingSettings.LoggingLevel(rawValue: levelString) else {
            return false
        }
        
        switch loggingLevel {
        case .off:
            return false
        case .errors:
            return level == .error || level == .critical
        case .warnings:
            return level == .warning || level == .error || level == .critical
        case .info:
            return level == .info || level == .warning || level == .error || level == .critical
        case .debug:
            return true // Log everything
        }
    }
    
    /// Check if file logging is enabled (thread-safe)
    nonisolated static var isFileLoggingEnabled: Bool {
        UserDefaults.standard.object(forKey: "com.reczipes.logging.fileLogging") == nil ? true : UserDefaults.standard.bool(forKey: "com.reczipes.logging.fileLogging")
    }
}

// MARK: - Log Level Enum

/// Log levels matching OSLog levels
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}
