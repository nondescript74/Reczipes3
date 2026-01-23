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
                // Recipe Book Import Fixes (January 22, 2026)
                "🐛 CRITICAL FIX: Recipe book imports failing with 'book.json not found' error",
                "✅ Fixed: ZIP archives with nested directory structures now import correctly",
                "🔧 Added: Recursive book.json finder handles both flat and nested ZIP structures",
                "📦 Fixed: Export now creates flat ZIP structure (no parent directory) for cross-device compatibility",
                "🖼️ CRITICAL FIX: Recipe images missing after import - now properly loads image data into database",
                "⚡️ Enhanced: Image data automatically loaded from Documents directory during recipe import",
                "✅ Fixed: Both new and updated recipes now have images correctly assigned",
                "📊 Added: Detailed logging shows image loading progress (sizes in KB)",
                
                // Multi-Book Import Improvements
                "🎯 Fixed: Multi-book import now shows accurate success/failure counts",
                "✨ Enhanced: Alert title dynamically changes based on import results (Success/Partially Successful/Failed)",
                "📋 Added: Detailed failure summary lists which books failed to import",
                "🔧 Fixed: Zero-import scenario now shows error instead of success message",
                "⚡️ Improved: Better error messages explain what went wrong during imports",
                
                // Previous Features
                "🐛 CRITICAL FIX: ZIP import now handles data descriptors (flags bit 3) - reads sizes from Central Directory",
                "✅ Fixed: .recipebook files created by macOS/iOS native compression now import successfully",
                "🔧 Enhanced: Recursive file search finds .recipebook files in nested ZIP directories",
                "📦 Added: Bulk import support - import multiple recipe books from a single ZIP file",
                "🔍 Added: Automatic detection of single vs. multi-book ZIP files during import",
                "📁 Enhanced: File picker now accepts both .recipebook and .zip files",
                "⚡️ Improved: Proper zlib header wrapping with FCHECK validation for raw DEFLATE data",
                "📊 Added: Comprehensive diagnostic logging shows EOCD location, central directory entries, and extraction progress"
            ]
        ))
        
        // PREVIOUS VERSIONS - Add historical entries below (hardcoded for history)
        // These represent past releases and should not change
        // 15.3.102
        // Recipe Book Import/Export Enhancements
//        "📦 Added: Bulk import support - import multiple recipe books from a single ZIP file",
//        "🔍 Added: Automatic detection of single vs. multi-book ZIP files during import",
//        "✅ Fixed: ZIP file extraction now handles unaligned memory access (no more crashes)",
//        "📁 Enhanced: Import file picker now accepts both .recipebook and .zip files",
//        "⚡️ Enhanced: User Content Backup view now intelligently handles both single and multi-book imports",
//        "📊 Added: Detailed import summary showing success/failure counts for bulk imports",
        //15.3.101
        // CRITICAL Database Fix
//        "🐛 FIXED: Critical bug causing database deletion on every app launch",
//        "💾 Fixed: Removed overly aggressive database compatibility pre-check in ModelContainerManager",
//        "✅ Fixed: User data now persists correctly between app launches",
//        "🔧 Enhanced: Database cleanup now only runs when actual errors occur, not preventively",
//        
//        // Import/Export Bug Fixes
//        "🐛 Fixed: Recipe export now shows correct success message instead of book export message",
//        "✅ Fixed: Export messages are now properly separated from import messages in User Content view",
//        
//        // Keep Awake Feature
//        "✨ Added: Keep Awake toggle in Cooking Mode prevents device sleep during recipe preparation",
//        "⚡️ Added: Automatic keep-awake during batch extractions (URLs and images) to prevent interruption",
//        "🎨 Added: Visual indicator showing when device is staying awake during batch operations",
//        
//        // Batch Image Processing
//        "📸 Added: Batch recipe extraction from Photos library - select multiple images at once",
//        "📁 Added: Batch extraction from Files and iCloud Drive with multi-select support",
//        "🔄 Added: Mix images from Photos and Files in a single batch extraction session",
//        "⚡️ Enhanced: Process up to 10 images simultaneously for faster batch extraction",
//        "✂️ Added: Optional crop-each-image workflow for precise extraction control",
//        "📊 Added: Real-time progress tracking with success/failure counts during batch extraction",
//        "🔄 Added: Background extraction support - continue extraction when view is dismissed",
//        "⏸️ Added: Pause/resume controls for batch extraction operations",
//        "🎯 Added: Smart queue management showing remaining images and preview thumbnails"
        // 15.3.100
//        "🐛 Fixed: Files/iCloud Drive images now load correctly (removed incorrect security-scoped resource access)",
//        "✅ Fixed: 'Failed to access security-scoped resource' error preventing all Files app images from loading",
//        "🔧 Fixed: Document picker with 'asCopy: true' now works as intended (files already in app sandbox)",
//        
//        // Enhanced User Feedback & Performance
//        "⚡️ Enhanced: Batch image extraction from Files/iCloud Drive now provides instant visual feedback",
//        "📊 Added: Real-time progress tracking when loading images from Files (shows current file and count)",
//        "🎨 Added: Loading overlay with progress bar for multi-file selection from Files app",
//        "⚡️ Enhanced: Asynchronous image loading prevents UI freezing when selecting many files",
//        "✨ Added: Haptic feedback when files finish loading successfully",
//        
//        // Improved Error Handling & Diagnostics
//        "🔧 Improved: Better error handling with individual file failures not blocking the batch",
//        "📊 Added: Comprehensive diagnostic logging for Files/iCloud Drive image loading",
//        "🔍 Added: Detailed file validation (existence checks, size logging, format verification)",
//        "📝 Added: Enhanced error messages with emojis for quick issue identification",
//        "⚡️ Optimized: Throttled loading prevents memory spikes with large file selections",
//        
        // UI/UX Improvements
//        "📱 Enhanced: Selection summary now shows color-coded breakdown (blue=Photos, purple=Files)",
//        "✅ Fixed: 'Select All' in Files app now works smoothly with clear progress indication",
//        "🎯 Added: Visual indicators distinguish Photos library images from Files app images"
        //15.3.98
//        "📁 Added: iCloud Drive support for batch recipe extraction",
//        "✨ Added: Select multiple recipe images from Files app and iCloud Drive",
//        "🔄 Added: Mix images from both Photos library and iCloud Drive in single batch",
//        "🎨 Added: Visual distinction - purple folder badges for Files images, blue for Photos",
//        "📱 Enhanced: Batch extraction now supports three source modes (Photos only, Files only, Mixed)",
//        "⚡️ Added: Security-scoped resource handling for proper iCloud Drive file access",
//        "🔧 Added: Document picker integration with multi-selection support",
//        "📊 Enhanced: Selection summary shows breakdown of images from each source",
//        "🎯 Added: Smart routing between PHAsset and UIImage extraction workflows",
//        "📚 Added: Comprehensive user guide and technical documentation for new feature"
        //15.3.97
        // Database Recovery & Migration Improvements (January 2026)
//        "💾 Fixed: 'Unknown model version' error (code 134504) causing app crashes on databases created before migration plan",
//        "🔧 Added: Automatic database cleanup detects and recovers from incompatible pre-V1.0.0 databases",
//        "⚡️ Enhanced: Recovery system automatically deletes old database files and creates fresh V4 schema",
//        "☁️ Added: CloudKit users' data syncs back automatically after database recovery",
//        "🔧 Fixed: 'Duplicate version checksums' error by abandoning SchemaV0 approach (identical schemas not allowed)",
//        
//        // Technical Implementation Details
//        "🛠️ Enhanced: ModelContainerManager now includes error detection for schema migration failures",
//        "📊 Added: Comprehensive logging for database recovery operations with detailed diagnostics",
//        "⚡️ Improved: Database cleanup happens instantly during container creation with no user intervention",
//        "🔒 Added: Safety mechanism prevents data loss for CloudKit-enabled users during recovery",
//        "📝 Added: Extensive documentation explaining pre-migration database handling and recovery strategy",
//        
//        // Diagnostic Logging Enhancements
//        "📊 Added: Comprehensive diagnostic logging to BatchImageExtractorView for better troubleshooting",
//        "🔍 Enhanced: User actions, extraction progress, and image operations now fully logged",
//        "🐛 Improved: Batch extraction debugging with detailed logs for cropping, pausing, and error handling",
//        "📝 Added: Logging for photo picker interactions and image selection workflow",
//        
//        // Key Learnings Documented
//        "📚 Documented: Why retroactive schema versions fail (duplicate checksums from identical structures)",
//        "💡 Documented: SwiftData migration plan limitations and best practices for future releases",
//        "🔍 Documented: CloudKit data recovery capabilities and sync behavior after database recreation",
//        "⚠️ Documented: Local-only users may lose data during recovery (unavoidable for incompatible databases)",
//        "✅ Documented: Simulator CloudKit limitations showing 'temporarily unavailable' status"
        //15.3.96
        // Database Recovery & Migration Improvements (January 2026)
//        "💾 Fixed: 'Unknown model version' error (code 134504) causing app crashes on databases created before migration plan",
//        "🔧 Added: Automatic database cleanup detects and recovers from incompatible pre-V1.0.0 databases",
//        "⚡️ Enhanced: Recovery system automatically deletes old database files and creates fresh V4 schema",
//        "☁️ Added: CloudKit users' data syncs back automatically after database recovery",
//        "🔧 Fixed: 'Duplicate version checksums' error by abandoning SchemaV0 approach (identical schemas not allowed)",
//        
//        // Technical Implementation Details
//        "🛠️ Enhanced: ModelContainerManager now includes error detection for schema migration failures",
//        "📊 Added: Comprehensive logging for database recovery operations with detailed diagnostics",
//        "⚡️ Improved: Database cleanup happens instantly during container creation with no user intervention",
//        "🔒 Added: Safety mechanism prevents data loss for CloudKit-enabled users during recovery",
//        "📝 Added: Extensive documentation explaining pre-migration database handling and recovery strategy",
//        
//        // Diagnostic Logging Enhancements
//        "📊 Added: Comprehensive diagnostic logging to BatchImageExtractorView for better troubleshooting",
//        "🔍 Enhanced: User actions, extraction progress, and image operations now fully logged",
//        "🐛 Improved: Batch extraction debugging with detailed logs for cropping, pausing, and error handling",
//        "📝 Added: Logging for photo picker interactions and image selection workflow",
//        
//        // Key Learnings Documented
//        "📚 Documented: Why retroactive schema versions fail (duplicate checksums from identical structures)",
//        "💡 Documented: SwiftData migration plan limitations and best practices for future releases",
//        "🔍 Documented: CloudKit data recovery capabilities and sync behavior after database recreation",
//        "⚠️ Documented: Local-only users may lose data during recovery (unavoidable for incompatible databases)",
//        "✅ Documented: Simulator CloudKit limitations showing 'temporarily unavailable' status"
//        
        //15.2.95
//        "🐛 Fixed: CloudKit recipe book manager runtime crash during pagination",
//        "⚡️ Improved: Replaced recursive closure pattern with clean async/await loop for fetching CloudKit records",
//        "🔧 Enhanced: Better error handling and logging for CloudKit batch operations",
//        "✅ Added: Safety mechanism to prevent infinite pagination loops (max 100 batches)",
//        "🗑️ Fixed: Successfully delete orphaned recipe books from CloudKit public database",
//        "📊 Improved: More detailed batch progress logging showing record counts per batch"
        //15.2.92
//        "✨ Added: 'Remove Duplicate Recipes' tool in Developer Tools to clean up duplicate database records",
//        "🔧 Fixed: Database Investigation now uses SQLite3 directly (bypasses migration issues)",
//        "✅ Fixed: Can now read 12.9 MB databases that were showing 0 recipes",
//        "🗑️ Enhanced: Duplicate removal keeps newest version of each recipe, deletes older copies",
//        "📊 Added: Shows duplicate statistics before cleanup (total/unique/duplicates to remove)",
//        "🚨 Added: Local database duplicate detection in CloudKit cleanup",
//        "⚡️ Enhanced: SQLite queries try multiple table names for compatibility",
//        "🧹 Added: Comprehensive CloudKit cleanup to remove duplicate shared recipes",
//        "🎨 Added: 'Fix Sharing Issues' UI in Settings → Community",
//        "🔄 Enhanced: Share deduplication prevents duplicate CloudKit records",
//        "🐛 Fixed: Community sharing now fetches all recipes (not just first 100)",
//        "⚡️ Enhanced: Cursor-based pagination for CloudKit queries",
//        "🔧 Added: Detailed batch logging for CloudKit operations",
//        "🔍 Added: Diagnostic function to analyze sharing by user",
//        "📊 Enhanced: Better error reporting with record IDs"
        // 15.2.90
//        "🐛 Fixed: Button style compatibility issues in empty state views",
//        "⚡️ Enhanced: Recipe cache system eliminates redundant database queries for improved performance",
//        "🔧 Improved: Background filter processing with smart caching for allergen and diabetes analysis",
//        "📱 Optimized: ContentUnavailableView actions now use SwiftUI default styling for better compatibility"
        // 15.2.89
//        "✨ Added: Three-way content filter (Mine/Shared/All) for Recipes and Books tabs",
//        "👥 Added: User attribution showing who shared each recipe and book",
//        "🔍 Added: Smart filtering to view your content, community content, or everything combined",
//        "🎨 Added: Segmented picker with contextual descriptions for each filter mode",
//        "⚡️ Enhanced: Filter integrates seamlessly with search and allergen/diabetes filters",
//        "📱 Added: Smart empty states that explain what's being filtered",
//        "✅ Improved: Community sharing and management are now more secure and user-friendly",
//        "☁️ Added: Help for first time users on Community Sharing"
        // 15.1.85
        //"🐛 Fixed: FODMAP analyzer incorrectly flagging apple cider vinegar as high FODMAP (was confusing it with apples)",
        //"⚡️ Enhanced: FODMAP ingredient matching now uses word boundaries to prevent false positives",
        //"🔧 Added: Exception list for compound ingredients (vinegars, plant milks) to ensure accurate FODMAP detection",
        //"✅ Improved: FODMAP analysis now correctly recognizes coconut milk, almond milk, and other low-FODMAP alternatives",
        //"📚 Added: Comprehensive Community Sharing Help section in CloudKit Setup & Diagnostics",
        //"💡 Added: Expandable help guide with troubleshooting steps, common fixes, and reporting instructions"
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

