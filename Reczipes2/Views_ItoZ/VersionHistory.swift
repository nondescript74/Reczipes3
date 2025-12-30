//
//  VersionHistory.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/30/24.
//

import Foundation

// MARK: - Version History Entry

struct VersionHistoryEntry: Codable, Identifiable {
    let id: UUID
    let version: String
    let buildNumber: String
    let releaseDate: Date
    let changes: [String]
    
    init(version: String, buildNumber: String, releaseDate: Date = Date(), changes: [String]) {
        self.id = UUID()
        self.version = version
        self.buildNumber = buildNumber
        self.releaseDate = releaseDate
        self.changes = changes
    }
    
    var versionString: String {
        "\(version) (\(buildNumber))"
    }
}

// MARK: - Version History Manager

class VersionHistoryManager {
    static let shared = VersionHistoryManager()
    
    private let userDefaultsKey = "com.reczipes.versionHistory"
    private let lastShownVersionKey = "com.reczipes.lastShownVersion"
    
    private init() {}
    
    // MARK: - Version History Database
    
    /// Complete version history - ADD NEW VERSIONS AT THE TOP
    /// Each commit should add a new entry here with concise bullet points
    ///
    /// IMPORTANT: The first entry ALWAYS represents the current version from Info.plist.
    /// When you update your app version in Xcode, just update the changes array below.
    /// The version/build numbers are automatically pulled from Info.plist.
    private var versionHistory: [VersionHistoryEntry] {
        var history: [VersionHistoryEntry] = []
        
        // CURRENT VERSION - Automatically uses Info.plist values
        // When you increment version/build in Xcode, this entry automatically updates
        // You only need to update the changes array with new features
        history.append(VersionHistoryEntry(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            releaseDate: Date(),
            changes: [
                "✨ Added: Dynamic Version History System",
                "🎨 Enhanced: Launch screen now shows every app launch",
                "📱 Added: Version History viewer in Settings",
                "🔧 Added: Version Debug view for troubleshooting",
                "📝 Improved: What's New section auto-populated from version database",
                "⚡️ Improved: Launch screen uses dynamic data from VersionHistoryManager",
                "📚 Added: Comprehensive documentation for version management",
                "🎯 Added: Emoji categorization guide for changelog entries",
                "🔄 Added: Share changelog functionality",
                "🗂️ Added: Expandable/collapsible version entries",
                "📊 Added: Automatic version/build detection from Info.plist",
                "🐛 Added: Developer reset button for version tracking (DEBUG)"
            ]
        ))
        
        // PREVIOUS VERSIONS - Add historical entries below (hardcoded for history)
        // These represent past releases and should not change
        
        history.append(VersionHistoryEntry(
            version: "11.5",
            buildNumber: "47",
            releaseDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            changes: [
                "📚 Export & Import Recipe Books",
                "🔄 Share Collections with Friends",
                "🤖 AI-Powered Recipe Extraction with Claude",
                "☁️ iCloud Sync Enabled",
                "🏷️ Recipe Image Assignment System",
                "⚠️ Allergen Profile Tracking",
                "💉 Diabetes Analysis for Recipes",
                "🔍 Advanced Recipe Search & Filtering",
                "📝 Recipe Books Organization",
                "🔗 Save & Extract from URLs",
                "📊 FODMAP Substitution Guide",
                "🎨 Liquid Glass Design Elements",
                "📱 State Preservation & Task Restoration"
            ]
        ))
        
        return history
    }
    
    // MARK: - Public Methods
    
    /// Get the current app version
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Get the current build number
    var currentBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Get the current version string
    var currentVersionString: String {
        "\(currentVersion) (\(currentBuildNumber))"
    }
    
    /// Get version history entry for current version
    func getCurrentVersionEntry() -> VersionHistoryEntry? {
        versionHistory.first { entry in
            entry.version == currentVersion && entry.buildNumber == currentBuildNumber
        }
    }
    
    /// Get what's new for the current version (changes since last shown version)
    func getWhatsNew() -> [String] {
        guard let currentEntry = getCurrentVersionEntry() else {
            return ["Welcome to Reczipes!"]
        }
        
        return currentEntry.changes
    }
    
    /// Get changes between two versions
    func getChangesBetween(from: String, to: String) -> [String] {
        var changes: [String] = []
        var collecting = false
        
        for entry in versionHistory {
            if entry.versionString == to {
                collecting = true
                changes.append(contentsOf: entry.changes)
            }
            
            if entry.versionString == from {
                break
            }
            
            if collecting && entry.versionString != to {
                changes.append(contentsOf: entry.changes)
            }
        }
        
        return changes
    }
    
    /// Check if this is a new version (should show what's new)
    func shouldShowWhatsNew() -> Bool {
        let lastShownVersion = UserDefaults.standard.string(forKey: lastShownVersionKey)
        let currentVersionString = self.currentVersionString
        
        // First launch or version changed
        return lastShownVersion == nil || lastShownVersion != currentVersionString
    }
    
    /// Mark current version as shown
    func markWhatsNewAsShown() {
        UserDefaults.standard.set(currentVersionString, forKey: lastShownVersionKey)
    }
    
    /// Get all version history (for a dedicated history view)
    func getAllHistory() -> [VersionHistoryEntry] {
        return versionHistory
    }
    
    /// Get formatted changelog text
    func getFormattedChangelog() -> String {
        var changelog = ""
        
        for entry in versionHistory {
            changelog += "Version \(entry.versionString)\n"
            changelog += "Released: \(formatDate(entry.releaseDate))\n\n"
            
            for change in entry.changes {
                changelog += "• \(change)\n"
            }
            
            changelog += "\n---\n\n"
        }
        
        return changelog
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Development Helper
    
    /// Reset version tracking (useful for testing)
    func resetVersionTracking() {
        UserDefaults.standard.removeObject(forKey: lastShownVersionKey)
    }
    
    #if DEBUG
    /// Get version history with sample data for testing/preview
    func getHistoryWithSampleData() -> [VersionHistoryEntry] {
        var history = versionHistory
        
        // Add a few sample versions for testing the UI
        history.append(contentsOf: [
            VersionHistoryEntry(
                version: "11.6",
                buildNumber: "49",
                releaseDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                changes: [
                    "✨ Added: Recipe backup to iCloud",
                    "🎨 Redesigned: Settings interface",
                    "⚡️ Improved: App performance by 30%",
                ]
            ),
            VersionHistoryEntry(
                version: "1.8",
                buildNumber: "3",
                releaseDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
                changes: [
                    "📸 Added: Photo library integration",
                    "🐛 Fixed: Crash when importing large recipes",
                ]
            ),
        ])
        
        return history
    }
    #endif
}

// MARK: - Emoji Prefix Guide

/*
 
 EMOJI GUIDE FOR VERSION HISTORY
 ================================
 
 Use these emoji prefixes to categorize changes:
 
 ✨ New Feature - Major new functionality
 🎨 UI/Design - Visual improvements, new design elements
 ⚡️ Performance - Speed improvements, optimization
 🐛 Bug Fix - Fixed bugs or issues
 🔒 Security - Security improvements
 📚 Documentation - Documentation updates
 🔄 Sync/Cloud - Sync, backup, cloud features
 🤖 AI/ML - AI or machine learning features
 🏷️ Organization - Tagging, categorization features
 ⚠️ Health - Health-related features (allergens, diabetes, etc.)
 🔍 Search - Search and filtering improvements
 📱 Platform - Platform-specific features
 🌐 Localization - Language and region support
 ♿️ Accessibility - Accessibility improvements
 📊 Analytics - Analytics and tracking
 🎯 Targeting - Personalization features
 💾 Data - Data management features
 🔗 Integration - Third-party integrations
 📸 Media - Photo and media features
 🎵 Audio - Audio features
 📹 Video - Video features
 🗺️ Maps - Location and maps
 📅 Calendar - Calendar integration
 👥 Social - Social and sharing features
 💰 Commerce - In-app purchases, payments
 🎮 Gamification - Game-like features
 📢 Notifications - Notification features
 🔧 Developer - Developer tools and debugging
 
 Examples:
 "✨ New Feature: Recipe Books Organization"
 "🐛 Fixed: Crash when importing large recipes"
 "⚡️ Improved: Recipe loading speed by 50%"
 "🎨 Redesigned: Launch screen with Liquid Glass"
 
 */

