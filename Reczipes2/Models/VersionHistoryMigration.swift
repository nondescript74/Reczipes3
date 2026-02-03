//
//  VersionHistoryMigration.swift
//  Reczipes2
//
//  Created on 02/01/26.
//

import Foundation
import SwiftData

//// MARK: - Version History Entry (for migration)
//
//struct VersionHistoryEntry {
//    let version: String
//    let buildNumber: String
//    let releaseDate: Date
//    let changes: [String]
//}

// MARK: - Version History Migration Utility

@MainActor
class VersionHistoryMigration {
    
    /// Import all historical version entries into SwiftData
    /// This should be run once to migrate from the old system to the new one
    static func importHistoricalData(into modelContext: ModelContext) async throws {
        let service = VersionHistoryService.shared
        service.initialize(modelContext: modelContext)
        
        print("🔄 Starting version history migration...")
        
        // All historical entries from the original VersionHistory.swift (up to line 724)
        let historicalEntries = getHistoricalEntries()
        
        var imported = 0
        var skipped = 0
        
        for entry in historicalEntries {
            do {
                try service.addVersionHistory(
                    version: entry.version,
                    buildNumber: entry.buildNumber,
                    releaseDate: entry.releaseDate,
                    changes: entry.changes
                )
                imported += 1
            } catch {
                // Already exists or other error
                skipped += 1
            }
        }
        
        print("✅ Migration complete: \(imported) imported, \(skipped) skipped")
    }
    
    /// Get all historical version entries
    private static func getHistoricalEntries() -> [VersionHistoryEntry] {
        var entries: [VersionHistoryEntry] = []
        
        // 15.4.110
        entries.append(VersionHistoryEntry(
            version: "15.4",
            buildNumber: "110",
            releaseDate: date(year: 2026, month: 1, day: 28),
            changes: [
                "☁️ Enhanced: Community recipe sync now fetches ALL shared recipes instead of just 100",
                "⚡️ Added: Sophisticated pagination system for CloudKit fetches (100 records per batch)",
                "🎨 Added: Real-time sync progress indicator in sidebar during community recipe sync",
                "🔄 Enhanced: Automatic sync rate limiting (once every 5 minutes) with duplicate prevention",
                "📊 Added: Visual feedback showing sync status (Connecting, Fetching, Complete)",
                "⚡️ Improved: Both automatic and manual sync now fetch complete recipe library",
                "🔧 Enhanced: Better sync reliability with cursor-based pagination and error handling",
                "🎨 Added: Full-screen progress overlays for all long-running CloudKit operations",
                "✨ Enhanced: Auto-share and unshare operations now show clear progress indicators",
                "📱 Improved: Browse Community views display loading states with modern overlays",
                "⚡️ Fixed: UI no longer appears frozen during share/sync operations",
                "🔧 Added: Disabled interaction during CloudKit operations to prevent conflicts",
                "🐛 Fixed: 'No recipes to unshare' message when toggling off auto-share with active shares",
                "📊 Enhanced: Unshare operations now show detailed results (success/failed/skipped counts)",
                "🔍 Added: Comprehensive logging for share/unshare operations to diagnose sync issues",
                "✅ Improved: Better error messages distinguish between truly empty state vs already unshared",
                "🎯 Enhanced: Ghost recipe cleanup now shows detailed results in alerts (ghosts found/deleted/failed)",
                "📊 Enhanced: Diagnostic tools now display results directly in UI instead of console logs",
                "✨ Improved: Recipe book diagnostics show CloudKit vs local stats with specific issue detection",
                "🔧 Added: Structured result types for all cleanup and diagnostic operations",
                "📱 Improved: Users no longer need to check console logs for diagnostic information",
                "🎯 Enhanced: Database health check now shows comprehensive status report in alert",
                "📊 Enhanced: Full diagnostics display complete report with stats and recovery history",
                "⚡️ Added: Progress overlays for all diagnostic operations with disabled interaction",
                "✨ Improved: All database diagnostic tools now show user-friendly results immediately"
            ]
        ))
        
        // 15.4.108
        entries.append(VersionHistoryEntry(
            version: "15.4",
            buildNumber: "108",
            releaseDate: date(year: 2026, month: 1, day: 27),
            changes: [
                "📚 Unified: Books tab now exclusively uses new Book model with CloudKit sync",
                "🗑️ Removed: Legacy RecipeBook model selector from Books tab",
                "✨ Simplified: Single book management interface with improved UX",
                "⚡️ Enhanced: All books now sync automatically via CloudKit Public Database",
                "🎨 Improved: Consistent book card design across all books",
                "🔧 Streamlined: Removed dual-model complexity from Books view",
                "🗑️ Removed: Image Migration tool (obsolete with new RecipeX/Book models)",
                "💾 Enhanced: RecipeX and Book store images directly in SwiftData - no migration needed",
                "⚡️ Simplified: All images sync automatically via CloudKit with zero configuration",
                "🔧 Refactored: AllergenAnalyzer now works directly with RecipeX (no RecipeModel conversion needed)",
                "🔧 Refactored: DiabetesAnalyzer now works directly with RecipeX (no RecipeModel conversion needed)",
                "🔧 Refactored: NutritionalAnalyzer now works directly with RecipeX (no RecipeModel conversion needed)",
                "⚡️ Enhanced: All analyzers decode ingredient sections from JSON on-demand for better performance",
                "🗑️ Eliminated: RecipeModel dependency from allergen, diabetes, and nutritional analysis systems",
                "✨ Simplified: ContentView now uses RecipeX throughout with no model conversions",
                "🐛 Fixed: LinkExtractionView navigation now properly returns RecipeDetailView",
                "🔧 Fixed: SharingSettingsView now uses RecipeX entities for CloudKit sharing (removed RecipeModel conversion)",
                "⚡️ Enhanced: RecipeSelectorView queries RecipeX directly for better performance",
                "✅ Fixed: Community recipe sharing now works with unified RecipeX model"
            ]
        ))
        
        // 15.4.107
        entries.append(VersionHistoryEntry(
            version: "15.4",
            buildNumber: "107",
            releaseDate: date(year: 2026, month: 1, day: 26),
            changes: [
                "✨ Added: RecipeX unified recipe model with automatic CloudKit sync capabilities",
                "🔄 Added: Recipe model selector in Recipes tab - switch between Legacy and RecipeX",
                "📊 Added: Side-by-side model support - both Recipe and RecipeX work simultaneously",
                "💾 Added: RecipeX stores all data in SwiftData (no separate image files)",
                "🔧 Added: RecipeX.toRecipeModel() conversion for seamless display compatibility",
                "⚡️ Enhanced: Recipe cache system now supports both model types",
                "🎨 Added: RecipeModelTypePicker UI component with model descriptions",
                "📝 Added: Comprehensive RecipeX integration guide (RECIPEX_INTEGRATION_GUIDE.md)",
                "📚 Added: New unified Book model for recipe book CloudKit sync to Public Database",
                "☁️ Added: BookSyncService for uploading, downloading, searching, and deleting books from CloudKit",
                "✨ Added: Community book sharing - share entire recipe books with all app users",
                "🔍 Added: Search books by name, category, and cuisine in CloudKit Public Database",
                "📥 Added: Download and import books shared by other users",
                "🔄 Added: Automatic sync for books marked as shared with configurable privacy levels",
                "📊 Added: Book content includes recipes, images, instructions, glossaries, and custom content",
                "👤 Added: User attribution for book ownership with display name and CloudKit user ID",
                "🎨 Added: Book sharing configuration with image quality and content inclusion options",
                "💾 Added: Book model integrated into ModelContainer schema (5 locations)",
                "⚡️ Enhanced: Background book sync with CloudKit subscriptions and remote notifications",
                "🐛 CRITICAL FIX: Unshared recipe books now properly disappear from 'All' tab for other users",
                "✅ Fixed: SharedRecipeBook tracking records are now deleted (not just marked inactive) when books are unshared",
                "🔧 Enhanced: Sync cleanup now fully removes unshared community books from all views",
                "📚 Fixed: Recipe books now disappear consistently across Mine/Shared/All tabs after being unshared",
                "⚡️ Improved: Better error handling when RecipeBook entity is already deleted during sync cleanup"
            ]
        ))
        
        // 15.4.106
        entries.append(VersionHistoryEntry(
            version: "15.4",
            buildNumber: "106",
            releaseDate: date(year: 2026, month: 1, day: 25),
            changes: [
                "🐛 FIXED: Critical CloudKit sync crash - CloudKitRecipePreview model incompatibility",
                "✅ Fixed: Added default values to all non-optional CloudKitRecipePreview properties for CloudKit compatibility",
                "☁️ Fixed: App now launches successfully with CloudKit enabled and syncs recipe books from community",
                "🔧 Enhanced: Recipe books view now prevents duplicate book IDs with deduplication logic",
                "📊 Added: Warning logs when duplicate book entries are detected for debugging",
                "📝 Enhanced: All CloudKitDuplicateMonitor print statements converted to structured logging (logInfo/logWarning/logError)",
                "🔍 Improved: CloudKit sync events now properly logged with 'cloudkit' category for better diagnostics",
                "⚡️ Added: Duplicate detection after sync now includes detailed logging and statistics",
                "✨ Added: Display Name field in Sharing Settings for community content attribution",
                "👤 Fixed: 'Show My Name' toggle now properly shows/hides user's name on shared recipes and books",
                "🔧 Enhanced: CloudKitSharingService now reads display name from SharingPreferences model instead of just UserDefaults",
                "📱 Added: TextField for entering display name appears when 'Show My Name' is enabled",
                "🔄 Added: Automatic synchronization between SharingPreferences and CloudKitSharingService",
                "🔒 Added: Privacy control - toggle OFF clears display name and shows 'Anonymous' on shares",
                "💾 Enhanced: Display name properly persists in both SwiftData and UserDefaults for reliability",
                "✅ Improved: Name changes apply to new shares going forward (existing shares retain original name)"
            ]
        ))
        
        // 15.4.105
        entries.append(VersionHistoryEntry(
            version: "15.4",
            buildNumber: "105",
            releaseDate: date(year: 2026, month: 1, day: 23),
            changes: [
                "🐛 CRITICAL FIX: Recipe book imports failing with 'book.json not found' error",
                "✅ Fixed: ZIP archives with nested directory structures now import correctly",
                "🔧 Added: Recursive book.json finder handles both flat and nested ZIP structures",
                "📦 Fixed: Export now creates flat ZIP structure (no parent directory) for cross-device compatibility",
                "🖼️ CRITICAL FIX: Recipe images missing after import - now properly loads image data into database",
                "⚡️ Enhanced: Image data automatically loaded from Documents directory during recipe import",
                "✅ Fixed: Both new and updated recipes now have images correctly assigned",
                "📊 Added: Detailed logging shows image loading progress (sizes in KB)",
                "🎯 Fixed: Multi-book import now shows accurate success/failure counts",
                "✨ Enhanced: Alert title dynamically changes based on import results (Success/Partially Successful/Failed)",
                "📋 Added: Detailed failure summary lists which books failed to import",
                "🔧 Fixed: Zero-import scenario now shows error instead of success message",
                "⚡️ Improved: Better error messages explain what went wrong during imports",
                "🐛 CRITICAL FIX: ZIP import now handles data descriptors (flags bit 3) - reads sizes from Central Directory",
                "✅ Fixed: .recipebook files created by macOS/iOS native compression now import successfully",
                "🔧 Enhanced: Recursive file search finds .recipebook files in nested ZIP directories",
                "📦 Added: Bulk import support - import multiple recipe books from a single ZIP file",
                "🔍 Added: Automatic detection of single vs. multi-book ZIP files during import",
                "📁 Enhanced: File picker now accepts both .recipebook and .zip files",
                "⚡️ Improved: Proper zlib header wrapping with FCHECK validation for raw DEFLATE data",
                "📊 Added: Comprehensive diagnostic logging shows EOCD location, central directory entries, and extraction progress",
                "🔧 Added: DatabaseRecoveryLogger tracks all database recovery attempts with detailed diagnostics",
                "📊 Added: Recovery statistics showing success rate, average duration, and recent failures",
                "✅ Enhanced: User-facing diagnostics with actionable suggestions when recovery fails",
                "⚡️ Added: Automatic recovery history logging shows on startup if recoveries have occurred",
                "🐛 Fixed: Recovery failure handling now supports optional secondary errors",
                "🔍 Added: Debug menu in ContentView for testing recovery logging (DEBUG builds only)",
                "🔒 SECURITY FIX: Removed API key logging from ClaudeAPIClient to prevent credential exposure",
                "✅ Fixed: API key prefix/suffix no longer logged during validation",
                "✅ Fixed: HTTP headers (including x-api-key) no longer logged during requests",
                "🗑️ Security Migration: Diagnostic logs automatically cleared once on update to remove any exposed keys",
                "⚠️ IMPORTANT: Users should rotate their Anthropic API keys if they shared diagnostic logs before this update",
                "📝 Enhanced: Logging now only shows whether API key is configured (YES/NO) without exposing values"
            ]
        ))
        
        // Continue with more versions...
        // 15.3.101
        entries.append(VersionHistoryEntry(
            version: "15.3",
            buildNumber: "101",
            releaseDate: date(year: 2026, month: 1, day: 20),
            changes: [
                "🐛 FIXED: Critical bug causing database deletion on every app launch",
                "💾 Fixed: Removed overly aggressive database compatibility pre-check in ModelContainerManager",
                "✅ Fixed: User data now persists correctly between app launches",
                "🔧 Enhanced: Database cleanup now only runs when actual errors occur, not preventively",
                "🐛 Fixed: Recipe export now shows correct success message instead of book export message",
                "✅ Fixed: Export messages are now properly separated from import messages in User Content view",
                "✨ Added: Keep Awake toggle in Cooking Mode prevents device sleep during recipe preparation",
                "⚡️ Added: Automatic keep-awake during batch extractions (URLs and images) to prevent interruption",
                "🎨 Added: Visual indicator showing when device is staying awake during batch operations",
                "📸 Added: Batch recipe extraction from Photos library - select multiple images at once",
                "📁 Added: Batch extraction from Files and iCloud Drive with multi-select support",
                "🔄 Added: Mix images from Photos and Files in a single batch extraction session",
                "⚡️ Enhanced: Process up to 10 images simultaneously for faster batch extraction",
                "✂️ Added: Optional crop-each-image workflow for precise extraction control",
                "📊 Added: Real-time progress tracking with success/failure counts during batch extraction",
                "🔄 Added: Background extraction support - continue extraction when view is dismissed",
                "⏸️ Added: Pause/resume controls for batch extraction operations",
                "🎯 Added: Smart queue management showing remaining images and preview thumbnails"
            ]
        ))
        
        // Add version 14.2.81
        entries.append(VersionHistoryEntry(
            version: "14.2",
            buildNumber: "81",
            releaseDate: date(year: 2026, month: 1, day: 15),
            changes: [
                "✨ Added: Community Sharing - share recipes and recipe books with all app users via CloudKit Public Database",
                "👥 Added: Browse and import recipes shared by other users in the community",
                "🔄 Added: Automatic sharing options - share all recipes/books automatically or select specific ones",
                "📚 Added: Recipe Book sharing - share entire collections with the community",
                "🎨 Added: Sharing preferences and management UI in Settings → Community section",
                "☁️ Added: CloudKit Public Database integration for community content",
                "🖼️ Added: Image sharing support - recipe images are included with shared content",
                "👤 Added: User attribution - see who shared each recipe with optional name display",
                "🔍 Added: Search and filter shared community recipes in Browse Community view",
                "📥 Added: One-tap import of community recipes to your personal collection",
                "💾 Added: Schema V4.0.0 - adds SharedRecipe, SharedRecipeBook, and SharingPreferences models",
                "🔧 Enhanced: Lightweight migration from Schema V3 to V4 preserves all existing data",
                "☁️ Fixed: CloudKit compatibility - all SwiftData models now have optional properties or defaults",
                "⚡️ Improved: ModelContainer initialization includes new sharing models automatically",
                "🐛 Fixed: Schema migration issues causing recipes to disappear after adding new models",
                "🔧 Fixed: Runtime error for non-optional properties in CloudKit-enabled SwiftData models",
                "📊 Enhanced: DiagnosticLogger now properly handles async logging contexts",
                "🛠️ Added: Comprehensive logging for sharing operations and CloudKit interactions"
            ]
        ))
        
        // Add more versions as needed...
        
        return entries
    }
    
    /// Helper to create dates
    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}
