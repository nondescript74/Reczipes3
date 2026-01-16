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
                // ADD NEW CHANGES HERE as you commit
                // Use emoji prefixes from the guide at the bottom of this file
                // Example: "✨ Added: New feature description"
                "🐛 Fixed: FODMAP analyzer incorrectly flagging apple cider vinegar as high FODMAP (was confusing it with apples)",
                "⚡️ Enhanced: FODMAP ingredient matching now uses word boundaries to prevent false positives",
                "🔧 Added: Exception list for compound ingredients (vinegars, plant milks) to ensure accurate FODMAP detection",
                "✅ Improved: FODMAP analysis now correctly recognizes coconut milk, almond milk, and other low-FODMAP alternatives",
                "📚 Added: Comprehensive Community Sharing Help section in CloudKit Setup & Diagnostics",
                "💡 Added: Expandable help guide with troubleshooting steps, common fixes, and reporting instructions"
            ]
        ))
        
        // PREVIOUS VERSIONS - Add historical entries below (hardcoded for history)
        // These represent past releases and should not change
        // 14.2.81
        
        // Community Sharing Features
//        "✨ Added: Community Sharing - share recipes and recipe books with all app users via CloudKit Public Database",
//        "👥 Added: Browse and import recipes shared by other users in the community",
//        "🔄 Added: Automatic sharing options - share all recipes/books automatically or select specific ones",
//        "📚 Added: Recipe Book sharing - share entire collections with the community",
//        "🎨 Added: Sharing preferences and management UI in Settings → Community section",
//        "☁️ Added: CloudKit Public Database integration for community content",
//        "🖼️ Added: Image sharing support - recipe images are included with shared content",
//        "👤 Added: User attribution - see who shared each recipe with optional name display",
//        "🔍 Added: Search and filter shared community recipes in Browse Community view",
//        "📥 Added: One-tap import of community recipes to your personal collection",
//        
//        // Schema & Migration
//        "💾 Added: Schema V4.0.0 - adds SharedRecipe, SharedRecipeBook, and SharingPreferences models",
//        "🔧 Enhanced: Lightweight migration from Schema V3 to V4 preserves all existing data",
//        "☁️ Fixed: CloudKit compatibility - all SwiftData models now have optional properties or defaults",
//        "⚡️ Improved: ModelContainer initialization includes new sharing models automatically",
//        
//        // Developer/Reliability Improvements
//        "🐛 Fixed: Schema migration issues causing recipes to disappear after adding new models",
//        "🔧 Fixed: Runtime error for non-optional properties in CloudKit-enabled SwiftData models",
//        "📊 Enhanced: DiagnosticLogger now properly handles async logging contexts",
//        "🛠️ Added: Comprehensive logging for sharing operations and CloudKit interactions"
        // 14.2.80
//        "⚡️ Fixed: Eliminated UI blocking during app launch - app now appears instantly",
//        "🔧 Improved: CloudKit availability checks now happen in background after UI loads",
//        "⚡️ Optimized: Removed artificial 1-second delay from ModelContainer initialization",
//        "🚀 Enhanced: App launches with local-only storage and upgrades to CloudKit seamlessly in background"
        //14.2.79
//        "🚨 Fixed: Critical database migration issue causing recipes to disappear after app updates",
//        "🔧 Added: Database Recovery tool to automatically detect and restore recipes from old database files",
//        "📊 Added: Database diagnostics to identify multiple database files and migration issues",
//        "💾 Enhanced: Automatic backup creation before database recovery operations",
//        "✨ Added: User-friendly recovery interface accessible from Settings → Developer Tools",
//        "☁️ Fixed: CloudKit initialization timeout preventing iCloud sync from activating",
//        "⚡️ Improved: App startup now completes instantly without blocking CloudKit checks",
//        "🔄 Enhanced: Automatic CloudKit upgrade after launch when iCloud becomes available",
//        "🐛 Fixed: Container recreation conflicts that prevented CloudKit sync from enabling",
//        "⚡️ Optimized: Smart teardown timing (1s for local→CloudKit, 5s for CloudKit→local transitions)",
//        "🔧 Improved: Async-first ModelContainer initialization eliminates main thread blocking"
        // 14.2.77
//        "✨ Added: Batch extraction mode processes up to 50 saved links automatically with 5-second intervals",
//        "⚡️ Enhanced: Intelligent retry system handles transient failures during batch recipe extraction",
//        "📸 Added: Automatic multi-image download support during batch extraction sessions",
//        "📊 Added: Comprehensive batch extraction UI with live progress, error logs, and session controls"
        // 14.1.75
        // Simplified Backup Access
        //"🔧 Removed: Backup & Restore button from Recipes view toolbar",
        //"📱 Improved: Backup and restore functionality now centralized in Settings under User Content Backup",
        //"🎨 Streamlined: Cleaner Recipes view interface with unified backup access point",
        // 14.1.74
        
        // Recipe Book Cover Image Fixes
//        "🐛 Fixed: Recipe book cover images not displaying after save",
//        "🐛 Fixed: Cover images not updating without navigating away from books view",
//        "⚡️ Improved: RecipeImageView now properly reloads when image file changes",
//        "🔧 Enhanced: Recipe books view now force-refreshes after editing to show immediate changes",
//        "🎨 Improved: Book cards now properly react to all property changes (name, description, color, cover image)",
        
        // Unified User Content Backup System
//        "✨ Added: Unified User Content Backup & Restore system",
//        "📚 Enhanced: Backup system now handles both recipes and recipe books in one place",
//        "🔄 Added: Export individual recipe books as .recipebook files with all images",
//        "📦 Improved: Recipe books export now includes cover images and all recipe images",
//        "🎨 Redesigned: Tabbed interface to switch between recipes and books backup",
//        "⚡️ Enhanced: Import recipe books directly from backup view",
//        "🔧 Renamed: 'Recipe Backup & Restore' to 'User Content Backup' for clarity"
        // 13.2.72
//        "🐛 Fixed: CloudKit validator false error reporting entitlements as missing when they were correct",
//        "🔧 Enhanced: Validator now correctly relies on actual CloudKit access test instead of impossible runtime entitlements check",
//        "📚 Improved: CloudKit validation messages now explain that entitlements can't be read at runtime",
//        "✅ Removed: Misleading debug messages showing 'entitlements not found' when they were properly configured",
//        "🔒 Technical: Entitlements are in app code signature, not accessible via Bundle.main APIs",
//        "💡 Added: Clear explanation that successful CloudKit access proves entitlements are correct",
        // 13.2.69
        // Performance Optimization
//        "⚡️ Optimized: Recipe list caching eliminates redundant SwiftData queries during UI rendering",
//        "🔧 Fixed: Eliminated 10x redundant recipe refreshes on ContentView load",
//        "💾 Added: Smart recipe cache that only updates when recipes are added, edited, or deleted",
//        "📊 Enhanced: Recipe filtering now uses cached data for instant performance",
//        
//        // Test Infrastructure Improvements
//        "🔧 Converted: RecipeExtractorTests from XCTest to Swift Testing framework",
//        "✅ Modernized: All test suites now use consistent Swift Testing macros and patterns",
//        "⚡️ Improved: Performance tests now use manual timing with time limits instead of XCTest measure blocks",
//        "🐛 Fixed: Test isolation in RecipeExportImportBackupTests using .serialized trait",
//        "📊 Enhanced: Backup tests run sequentially to prevent file system race conditions",
//        "🔧 Added: Custom TestSkipError for consistent test skipping across all test suites",
//        "✅ Removed: XCTest dependency from recipe extraction tests for better Swift 6 compatibility"
        
        // 13.2 66"🐛 Fixed: DiabeticCacheIntegrationTests for main actor concurrency failures",
        // 13.2.67                 "🔧 Converted: RecipeExtractorTests from XCTest to Swift Testing framework",
//        "✅ Modernized: All test suites now use consistent Swift Testing macros and patterns",
//        "⚡️ Improved: Performance tests now use manual timing with time limits instead of XCTest measure blocks",
//        "🐛 Fixed: Test isolation in RecipeExportImportBackupTests using .serialized trait",
//        "📊 Enhanced: Backup tests run sequentially to prevent file system race conditions",
//        "🔧 Added: Custom TestSkipError for consistent test skipping across all test suites",
//        "✅ Removed: XCTest dependency from recipe extraction tests for better Swift 6 compatibility"
//        
//        
//        history.append(VersionHistoryEntry(
//            version: "13.1",
//            buildNumber: "65",
//            releaseDate: Date(),
//            changes: [
//                "Fixed memory leaks in CloudKit sync monitoring by replacing NotificationCenter observers with async notification streams",
//                "Replaced legacy DispatchQueue.main.async calls with modern Swift Concurrency (@MainActor isolation)",
//                "Eliminated Timer memory leaks in ExtractionLoadingView by using SwiftUI's .task modifier with structured concurrency",
//                "Improved notification monitoring with automatic cancellation when views disappear",
//
//                // Swift Concurrency Best Practices
//                "Migrated CloudKitSyncStatusMonitorView to use async/await throughout for better reliability",
//                "Updated SyncStatusLogger to use @MainActor isolation for thread-safe UI updates",
//                "Replaced Date-based animation calculations with state-driven SwiftUI animations",
//
//                // SwiftData & Actor Isolation Fixes
//                "Fixed Sendable compliance errors in DiabeticAnalysisService by introducing CachedData transfer object",
//                "Resolved actor isolation warnings by properly handling SwiftData models within ModelActor boundaries",
//                "Improved cache invalidation to work correctly across actor boundaries with proper data isolation",
//                "⚡️ Enhanced: Intelligent retry logic with exponential backoff for recipe extraction network failures",
//                "🔧 Added: Comprehensive test suite for retry manager covering transient errors, rate limiting, and terminal failures"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "13.0",
//            buildNumber: "63",
//            releaseDate: Date(),
//            changes: [
//                "🔧 Refactored: Split 2,864-line RecipeExportImportTests into 5 focused test files for better maintainability",
//                "✅ Organized: Test suites now grouped by functionality (Basic, Backup, Restore, Integration, Edge Cases)",
//                "⚡️ Enhanced: Tests can now run independently, improving development workflow",
//                "🐛 Fixed: Edge case test expectation for nil vs empty string in ingredient encoding"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.9",
//            buildNumber: "62",
//            releaseDate: Date(),
//            changes: [
//                "💾 Enhanced: Recipe backups now save to Files/Reczipes2 folder instead of temporary storage",
//                "✨ Added: Automatic backup discovery - available backups are listed in the import view",
//                "📁 Improved: Backups are now persistent and accessible via iOS/iPadOS Files app",
//                "🔄 Added: Refresh button to reload available backups in import view",
//                "📊 Enhanced: Backup list shows file name, date, and size for each backup",
//                "☁️ Added: Backups in Documents folder can sync via iCloud if enabled",
//                "🔧 Added: Comprehensive test suite for backup/restore with 25+ test cases",
//                "✅ Added: Integration tests for complete backup/restore workflows",
//                "🐛 Added: Failure scenario tests with instructive error messages",
//                "📝 Added: Step-by-step workflow tests simulating real-world usage",
//                "🎨 Improved: Recipe details now use full-screen presentation on iPad for better reading experience",
//                "✨ Added: Clear and prominent dismiss button when viewing recipes in Recipe Books on iPad",
//                "📱 Enhanced: Optimized sheet presentations for iPad with proper sizing and drag indicators",
//                "⚡️ Fixed: Recipe detail sheets appearing too small on iPad, now uses device-appropriate presentation"
//
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.8",
//            buildNumber: "61",
//            releaseDate: Date(),
//            changes: [
//                "✨ Added: Rerun Analysis button for diabetic-friendly recipe analysis",
//                "🔗 Added: Clickable recipe reference URLs that open in Safari Reader mode",
//                "🔒 Enhanced: Reference URLs open in secure SFSafariViewController with restricted navigation",
//                "🎨 Improved: Recipe references now display as interactive buttons with Safari icon for valid URLs"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.7",
//            buildNumber: "59",
//            releaseDate: Date(),
//            changes: [
//                "🔧 Fixed: Swift 6 concurrency warnings in UserAllergenProfile and SchemaMigration files",
//                "📝 Improved: JSON encoding/decoding patterns for nutritional goals and sensitivities",
//                "💾 Enhanced: Schema V3 compatibility with CloudKit sync for nutritional data",
//                "✅ Verified: All SwiftData models properly configured for main actor isolation"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.6",
//            buildNumber: "58",
//            releaseDate: Date(),
//            changes: [
//                "🐛 Fixed: Startup crash caused by SchemaV3 initialization with nil nutritional goals",
//                "🔧 Fixed: Main actor isolation warnings in UserAllergenProfile schema definitions",
//                "⚡️ Improved: Enhanced ModelContainer initialization logging for better debugging",
//                "🔍 Added: Detailed error logging during container creation to diagnose CloudKit issues"
//            
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.5",
//            buildNumber: "57",
//            releaseDate: Date(),
//            changes: [
//                "🐛 Fixed: Recipe Book import decompression error when importing .recipebook files",
//                "🔧 Enhanced: ZIP file extraction now properly handles raw DEFLATE compression with zlib wrapper",
//                "⚡️ Improved: More descriptive error messages when archive decompression fails",
//                "📚 Fixed: Recipe Books exported from the app can now be successfully imported on other devices",
//                "✨ Added: Nutritional Goals system with daily targets for calories, sodium, fat, sugar, fiber, and more",
//                "⚠️ Added: Personalized nutritional goal profiles (Weight Loss, Diabetes Management, Heart Health, General Health, Athletic Performance)",
//                "🏥 Added: Medical guidelines integration from American Heart Association, American Diabetes Association, and CDC",
//                "📊 Added: Recipe nutritional analysis showing how recipes fit within daily goals",
//                "⚡️ Added: Smart nutrition alerts for high sodium, saturated fat, sugar, and positive fiber content",
//                "🎯 Added: Recipe compatibility scoring (0-100) based on nutritional goals",
//                "💾 Added: Schema V3.0.0 for UserAllergenProfile with nutritional goals data storage"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.4",
//            buildNumber: "56",
//            releaseDate: Date(),
//            changes: [
//                "✨ Added: Recipe Book integration with context menus and visual badges showing book membership",
//                "⚡️ Improved: Background filter processing with caching to prevent UI blocking during allergen and diabetes analysis",
//                "🔧 Enhanced: Recipe deletion now automatically cleans up associated image files and assignments"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "12.3",
//            buildNumber: "54",
//            releaseDate: Date(),
//            changes: [
//                "✨ Added: Cooking Mode with step-by-step recipe tracking and completion checkmarks",
//                "⚡️ Added: Dynamic serving size adjustment with automatic ingredient quantity scaling",
//                "🎨 Added: Persistent cooking session state across app launches using SwiftData",
//                "🔧 Fixed: CloudKit sync compatibility for CookingSession model with proper default values",
//                "✅ Added Recipe Book Query",
//                "✅ Enhanced Recipe Row with Book Badges",
//                "✅ Added Add to Book Context Menu",
//                "✅ Added Helper Methods",
//                "✅ Added View Books Toolbar Button",
//                "✅ Created RecipeBookBadge Component"
//
//            ]
//        ))
//        
//        
//        history.append(VersionHistoryEntry(
//            version: "12.2",
//            buildNumber: "53",
//            releaseDate: Date(),
//            changes: [
//                "⚡️ Added: Tips can be added to existing recipes",
//                "🎨 Fixed: AppClip not compiling",
//                "⚡️ Added: Adds an image size reduction function to ImagePreprocessor",
//                "⚡️ Added: Updates the ViewModel to reduce image sizes before sending to Claude",
//                "⚡️ Added: Handles this for camera, library, and web URL images",
//                "⚡️ Improved: Image cropping performance - crop handles now respond instantly to touch",
//                "🎨 Fixed: Laggy crop rectangle dragging during recipe image extraction",
//                "🐛 Fixed: Slow response when adjusting crop corners and moving crop area",
//                "⚡️ Added: Added tip creation UI to RecipeDetailView with Add a Tip button",
//                "⚡️ Added: Pending tips shown with orange border and badge before save",
//                "⚡️ Added: Tips automatically included when recipe is saved",
//                "⚡️ Added: Save button displays pending tip count"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "11.8",
//            buildNumber: "50",
//            releaseDate: Date(),
//            changes: [
//                "🎨 Enhanced: Animated loading indicators for recipe extraction with rotating status messages",
//                "⚡️ Added: 'Preparing image...' spinner between photo selection and crop screen",
//                "🐛 Fixed: Crop screen not appearing after selecting library photo (timing conflict)",
//                "🐛 Fixed: Loading indicator hidden behind UI elements during extraction",
//                "⚡️ Improved: UI now hides all controls during extraction to focus on progress",
//                "🔧 Added: Debug logging for image selection and extraction flow",
//                "✅ Added 0.6s delay between sheet dismiss and fullScreenCover present (prevents SwiftUI conflict)",
//                "✅ Hide source buttons when imageToCrop != nil (shows preparing spinner instead)",
//                "✅ Added Preparing image... indicator between picker and crop",
//                "✅ Added debug logging to trace the flow",
//                "✅ Hide UI elements during extraction to show only loading indicator",
//                "📱 Fixed: Hang on image extraction",
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "11.7",
//            buildNumber: "49",
//            releaseDate: Date(),
//            changes: [
//                "📱 Removed: Spoonacular minor reference in url",
//                "📱 Added: Version History viewer in Settings",
//                "🎨 Enhanced: Launch screen now shows every app launch"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "11.6",
//            buildNumber: "48",
//            releaseDate: Date(),
//            changes: [
//                "🎨 Enhanced: Launch screen now shows every app launch",
//                "📱 Added: Version History viewer in Settings",
//                "🔧 Added: Version Debug view for troubleshooting",
//                "📝 Improved: What's New section auto-populated from version database",
//                "⚡️ Improved: Launch screen uses dynamic data from VersionHistoryManager",
//                "📚 Added: Comprehensive documentation for version management",
//                "🎯 Added: Emoji categorization guide for changelog entries",
//                "🔄 Added: Share changelog functionality",
//                "🗂️ Added: Expandable/collapsible version entries",
//                "📊 Added: Automatic version/build detection from Info.plist",
//                "🐛 Added: Developer reset button for version tracking (DEBUG)",
//                "🐛 Fixed: Version history debug function mutation error"
//            ]
//        ))
//        
//        history.append(VersionHistoryEntry(
//            version: "11.5",
//            buildNumber: "47",
//            releaseDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
//            changes: [
//                "📚 Export & Import Recipe Books",
//                "🔄 Share Collections with Friends",
//                "🤖 AI-Powered Recipe Extraction with Claude",
//                "☁️ iCloud Sync Enabled",
//                "🏷️ Recipe Image Assignment System",
//                "⚠️ Allergen Profile Tracking",
//                "💉 Diabetes Analysis for Recipes",
//                "🔍 Advanced Recipe Search & Filtering",
//                "📝 Recipe Books Organization",
//                "🔗 Save & Extract from URLs",
//                "📊 FODMAP Substitution Guide",
//                "🎨 Liquid Glass Design Elements",
//                "📱 State Preservation & Task Restoration"
//            ]
//        ))
        
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
    
//    #if DEBUG
//    /// Add sample history data for testing/preview
//    func addSampleHistoryForTesting() {
//        // Add a few sample versions for testing the UI
//        versionHistory.append(contentsOf: [
//            VersionHistoryEntry(
//                version: "1.9",
//                buildNumber: "5",
//                releaseDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
//                changes: [
//                    "✨ Added: Recipe backup to iCloud",
//                    "🎨 Redesigned: Settings interface",
//                    "⚡️ Improved: App performance by 30%",
//                ]
//            ),
//            VersionHistoryEntry(
//                version: "1.8",
//                buildNumber: "3",
//                releaseDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
//                changes: [
//                    "📸 Added: Photo library integration",
//                    "🐛 Fixed: Crash when importing large recipes",
//                ]
//            ),
//        ])
//    }
//    #endif
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

