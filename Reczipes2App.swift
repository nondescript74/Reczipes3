//
//  Reczipes2App.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI
import SwiftData

@main
struct Reczipes2App: App {
    
    // State management
    @StateObject private var appState = AppStateManager.shared
    @StateObject private var taskRestoration = TaskRestorationCoordinator.shared
    @StateObject private var containerManager = ModelContainerManager.shared
    
    init() {
        // Suppress Auto Layout constraint warnings from UIKit internals
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        // Handle UI testing mode
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            // Accept license and set up API key for testing
            LicenseHelper.acceptLicense()
            // Set a dummy API key for testing (won't actually work but allows UI to load)
            _ = APIKeyHelper.setAPIKey("sk-ant-test-key-for-ui-testing")
            // Skip first launch screens
            UserDefaults.standard.set(false, forKey: "shouldShowLaunchScreen")
            logInfo("🧪 UI Testing mode enabled - bypassing onboarding", category: "testing")
        }
        
        // Log CloudKit configuration for debugging (synchronous, no blocking)
        logCloudKitConfiguration()
        
        // NOTE: CloudKit checks are now deferred to background tasks after UI appears
        // See .task modifier in MainTabView for background initialization
    }
    
    // Use the shared container from the manager instead of creating our own
    var sharedModelContainer: ModelContainer {
        containerManager.container
    }
    
    // Keep the old static initializer for reference, but don't use it
    private static var _legacySharedModelContainer: ModelContainer = {
        // Log schema version information
        print("🚀 STARTING MODEL CONTAINER INITIALIZATION")
        print("   Schema Version: \(SchemaVersionManager.versionString(SchemaVersionManager.currentVersion))")
        SchemaVersionManager.logSchemaInfo()
        
        // MARK: - CloudKit Configuration with Migration Support
        // To disable CloudKit and use local-only storage, comment out the cloudKitDatabase parameter below
        
        // CloudKit configuration with migration plan
        // Use a specific URL to avoid conflicts with old database files
        let cloudKitURL = URL.applicationSupportDirectory.appending(path: "CloudKitModel.sqlite")
        let cloudKitConfiguration = ModelConfiguration(
            url: cloudKitURL,
            cloudKitDatabase: .private("iCloud.com.headydiscy.reczipes")
        )
        
        // Fallback configuration without CloudKit 
        // IMPORTANT: Use the SAME URL as CloudKit config to preserve existing data!
        let localConfiguration = ModelConfiguration(
            url: cloudKitURL,  // Use same database file
            cloudKitDatabase: .none  // Just disable CloudKit sync, keep the data
        )

        // Try CloudKit configuration first
        // Using SchemaMigrationPlan for automatic schema versioning and migration
        print("📦 Attempting to create ModelContainer...")
        do {
            print("   Creating container with models:")
            print("     - Recipe")
            print("     - RecipeImageAssignment")
            print("     - UserAllergenProfile")
            print("     - CachedDiabeticAnalysis")
            print("     - SavedLink")
            print("     - RecipeBook")
            print("     - CookingSession")
            
            let container = try ModelContainer(
                for: Recipe.self,
                RecipeImageAssignment.self,
                UserAllergenProfile.self,
                CachedDiabeticAnalysis.self,
                SavedLink.self,
                RecipeBook.self,
                CookingSession.self,
                migrationPlan: Reczipes2MigrationPlan.self,
                configurations: cloudKitConfiguration
            )
            print("✅ ModelContainer created successfully with CloudKit sync enabled")
            print("   Container: iCloud.com.headydiscy.reczipes")
            print("   Database: CloudKitModel.sqlite (separate from local-only)")
            print("   Migration Plan: Reczipes2MigrationPlan")
            print("   Current Schema Version: \(SchemaVersionManager.versionString(SchemaVersionManager.currentVersion))")
            print("   Automatic schema migration enabled")
            return container
        } catch {
            // CloudKit failed, try local-only as fallback
            print("⚠️ CloudKit ModelContainer creation failed: \(error)")
            print("   Error details: \(error.localizedDescription)")
            if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
                print("   Underlying error: \(underlyingError)")
            }
            print("   Attempting fallback to local-only container...")
            
            do {
                let container = try ModelContainer(
                    for: Recipe.self,
                    RecipeImageAssignment.self,
                    UserAllergenProfile.self,
                    CachedDiabeticAnalysis.self,
                    SavedLink.self,
                    RecipeBook.self,
                    CookingSession.self,
                    migrationPlan: Reczipes2MigrationPlan.self,
                    configurations: localConfiguration
                )
                print("✅ ModelContainer created successfully (local-only, no CloudKit sync)")
                print("   Migration Plan: Reczipes2MigrationPlan")
                print("   Current Schema Version: \(SchemaVersionManager.versionString(SchemaVersionManager.currentVersion))")
                print("   Automatic schema migration enabled")
                print("   Note: CloudKit was enabled but failed. Check your iCloud settings and container identifier.")
                print("   See CLOUDKIT_SETUP_GUIDE.md for troubleshooting steps.")
                return container
            } catch {
                print("❌ All ModelContainer initialization attempts failed")
                print("   Final error: \(error)")
                print("")
                print("   TROUBLESHOOTING:")
                print("   1. Check that all @Model classes are properly defined")
                print("   2. Verify SwiftData schema is valid")
                print("   3. Try cleaning build folder (Cmd+Shift+K)")
                print("   4. Delete app from device/simulator and reinstall")
                print("   5. Check that iCloud is properly configured")
                print("   6. See CLOUDKIT_SETUP_GUIDE.md for detailed setup")
                print("")
                fatalError("Could not create ModelContainer. Please check your model schema and iCloud settings: \(error)")
            }
        }
    }()
    
    @State private var showLicenseAgreement = !LicenseHelper.hasAcceptedLicense
    @State private var showAPIKeySetup = false
    @State private var showLaunchScreen = false
    @State private var showAppClipImportBanner = false
    @State private var importedRecipeName = ""
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Show loading overlay when container is being recreated
                if containerManager.isRecreating {
                    containerRecreationOverlay
                } else {
                    MainTabView()
                        .modelContainer(sharedModelContainer)
                        .environmentObject(appState)
                        .environmentObject(taskRestoration)
                        .fullScreenCover(isPresented: $showLicenseAgreement) {
                            LicenseAgreementView(isPresented: $showLicenseAgreement)
                                .onDisappear {
                                    // After license is accepted, check if API key setup is needed
                                    if LicenseHelper.hasAcceptedLicense {
                                        showAPIKeySetup = !APIKeyHelper.isConfigured
                                    }
                                }
                        }
                        .fullScreenCover(isPresented: $showAPIKeySetup) {
                            APIKeySetupView(isPresented: $showAPIKeySetup)
                        }
                        .onAppear {
                            // Check license and API key status on appear
                            showLicenseAgreement = !LicenseHelper.hasAcceptedLicense
                            if LicenseHelper.hasAcceptedLicense {
                                showAPIKeySetup = !APIKeyHelper.isConfigured
                            }
                            
                            // Show launch screen every launch (only if onboarding is complete)
                            if LicenseHelper.hasAcceptedLicense && APIKeyHelper.isConfigured {
                                showLaunchScreen = appState.shouldShowLaunchScreen()
                            }
                            
                            // Check if images need restoration (after app reinstall)
                            Task {
                                await checkAndRestoreImages()
                            }
                            
                            // Check for App Clip data
                            checkForAppClipData()
                        }
                    
                    // Launch screen overlay - shows briefly on every launch (after onboarding)
                    if showLaunchScreen && LicenseHelper.hasAcceptedLicense && APIKeyHelper.isConfigured {
                        LaunchScreenView {
                            // Dismiss launch screen
                            withAnimation {
                                showLaunchScreen = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(1)
                    }
                    
                    // App Clip import banner
                    if showAppClipImportBanner {
                        VStack {
                            AppClipImportBanner(
                                recipeName: importedRecipeName,
                                isPresented: $showAppClipImportBanner
                            )
                            .padding()
                            Spacer()
                        }
                        .zIndex(2)
                    }
                    
                    // Task restoration prompt
                    if taskRestoration.showRestorationPrompt {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .zIndex(2)
                        
                        TaskRestorationPromptView(
                            coordinator: taskRestoration,
                            modelContainer: sharedModelContainer
                        )
                        .zIndex(3)
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
            }
        }
    }
    
    // MARK: - Container Recreation Overlay
    
    private var containerRecreationOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text("Updating iCloud Connection")
                    .font(.headline)
                
                Text("Please wait while we reconnect to iCloud...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Image Restoration
    
    @MainActor
    private func checkAndRestoreImages() async {
        let modelContext = sharedModelContainer.mainContext
        
        // Check if any images need restoration
        let needsRestoration = RecipeImageMigrationService.needsImageRestoration(modelContext: modelContext)
        
        if needsRestoration {
            logInfo("Detected missing image files - attempting automatic restoration", category: "image-migration")
            
            do {
                try await RecipeImageMigrationService.restoreAllRecipeImages(modelContext: modelContext)
                logInfo("Successfully restored images from SwiftData", category: "image-migration")
            } catch {
                logError("Failed to restore images: \(error)", category: "image-migration")
            }
        }
    }
    
    // MARK: - App Clip Data Import
    
    private func checkForAppClipData() {
        let modelContext = sharedModelContainer.mainContext
        
        Task { @MainActor in
            let didImport = AppClipDataHandler.checkForPendingRecipe(modelContext: modelContext)
            
            if didImport {
                // Show success banner
                withAnimation {
                    importedRecipeName = "Recipe imported successfully"
                    showAppClipImportBanner = true
                }
                
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        showAppClipImportBanner = false
                    }
                }
                
                // Share API key with App Clip if available
                if let apiKey = APIKeyHelper.getAPIKey() {
                    AppClipDataHandler.shareAPIKeyWithAppClip(apiKey)
                }
            }
        }
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        // Notify app state manager
        appState.handleScenePhaseChange(newPhase)
        
        switch newPhase {
        case .active:
            // App is now active - check if we need to restore tasks
            if oldPhase == .background {
                logInfo("App returning from background", category: "state")
                taskRestoration.checkForTaskRestoration()
            }
            
        case .background:
            // App is going to background - state is automatically saved by AppStateManager
            logInfo("App entering background", category: "state")
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - CloudKit Diagnostics
    
    private func logCloudKitConfiguration() {
        print("========================================")
        print("📱 CLOUDKIT CONFIGURATION")
        print("========================================")
        print("Container ID: iCloud.com.headydiscy.reczipes")
        print("Configuration: Private Database")
        print("Framework: SwiftData (not Core Data)")
        print("")
        print("⚠️  IMPORTANT: Using explicit container identifier")
        print("   Cannot use .automatic as it would create different container")
        print("   Existing container: iCloud.com.headydiscy.reczipes")
        print("")
        
        // CRITICAL: Check for multiple database files
        checkForMultipleDatabases()
        
        print("📋 TROUBLESHOOTING:")
        print("   If CloudKit sync is not working:")
        print("   1. Go to Settings → Validate CloudKit Container")
        print("   2. Run the validation tool")
        print("   3. Follow the specific recommendations")
        print("   4. Most likely: Add container to entitlements in Xcode")
        print("")
        print("Models registered for sync:")
        print("  - Recipe")
        print("  - RecipeImageAssignment")
        print("  - UserAllergenProfile")
        print("  - CachedDiabeticAnalysis")
        print("  - SavedLink")
        print("  - RecipeBook")
        print("  - CookingSession")
        print("========================================")
    }
    
    private func checkForMultipleDatabases() {
        print("")
        print("🔍 DATABASE FILE DIAGNOSTICS:")
        print("========================================")
        
        let appSupport = URL.applicationSupportDirectory
        let fileManager = FileManager.default
        
        // Check for different database files
        let possibleDatabases = [
            "CloudKitModel.sqlite",
            "default.store",
            "Model.sqlite",
            "Reczipes2.sqlite"
        ]
        
        var foundDatabases: [(name: String, size: Int64, modified: Date)] = []
        
        for dbName in possibleDatabases {
            let dbURL = appSupport.appendingPathComponent(dbName)
            
            if fileManager.fileExists(atPath: dbURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: dbURL.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    let modDate = attributes[.modificationDate] as? Date ?? Date.distantPast
                    
                    foundDatabases.append((name: dbName, size: fileSize, modified: modDate))
                    
                    print("✅ Found: \(dbName)")
                    print("   Size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                    print("   Modified: \(modDate)")
                } catch {
                    print("⚠️  Found \(dbName) but couldn't read attributes: \(error)")
                }
            }
        }
        
        if foundDatabases.isEmpty {
            print("⚠️  No database files found - this is a fresh install")
        } else if foundDatabases.count > 1 {
            print("")
            print("🚨 CRITICAL: Multiple database files detected!")
            print("   This may explain missing recipes after update.")
            print("   The app might be reading from the wrong file.")
            print("")
            print("Largest file (likely contains user data):")
            if let largest = foundDatabases.max(by: { $0.size < $1.size }) {
                print("   📁 \(largest.name) - \(ByteCountFormatter.string(fromByteCount: largest.size, countStyle: .file))")
            }
        }
        
        print("========================================")
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject private var appState: AppStateManager
    
    var body: some View {
        TabView(selection: $appState.currentTab) {
            // Existing recipes tab
            ContentView()
                .tabItem {
                    Label("Recipes", systemImage: "book.fill")
                }
                .tag(AppTab.recipes)
            
            // Recipe Books tab
            RecipeBooksView()
                .tabItem {
                    Label("Books", systemImage: "books.vertical.fill")
                }
                .tag(AppTab.books)
            // NEW: Cooking Mode tab
            CookingView()
                .tabItem {
                    Label("Cooking", systemImage: "flame.fill")
                }
                .tag(AppTab.cooking)
            // Extraction tab - always visible
            RecipeExtractorTabWrapper()
                .tabItem {
                    Label("Extract", systemImage: "camera.fill")
                }
                .tag(AppTab.extract)
            // Settings tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
        .task {
            // Perform background initialization tasks after UI has appeared
            // This prevents blocking the UI during app launch
            await performBackgroundInitialization()
        }
    }
    
    // MARK: - Background Initialization
    
    /// Performs non-critical initialization tasks in the background after UI appears
    private func performBackgroundInitialization() async {
        // Check CloudKit status (non-blocking)
        // The ModelContainerManager will automatically upgrade to CloudKit if available
        await CloudKitSyncMonitor.shared.checkAccountStatus()
        
        // Note: ModelContainerManager already handles CloudKit upgrade asynchronously
        // in its own init() with a 1-second delay, so we don't need to trigger it here
    }
}

// MARK: - Recipe Extractor Tab Wrapper

struct RecipeExtractorTabWrapper: View {
    @State private var isAPIKeyConfigured = APIKeyHelper.isConfigured
    
    var body: some View {
        if isAPIKeyConfigured, let apiKey = APIKeyHelper.getAPIKey() {
            RecipeExtractorView(apiKey: apiKey)
                .onAppear {
                    // Refresh API key status when tab appears
                    isAPIKeyConfigured = APIKeyHelper.isConfigured
                }
        } else {
            // Show a helpful message when API key isn't configured
            NavigationView {
                VStack(spacing: 20) {
                    Image(systemName: "key.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("API Key Required")
                        .font(.title2)
                        .bold()
                    
                    Text("To extract recipes from images, you need to configure your Claude API key.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: APIKeyManagerView()) {
                        Label("Set Up API Key", systemImage: "key.fill")
                            .font(.headline)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Text("You can also set up your API key in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .navigationTitle("Extract Recipe")
                .onAppear {
                    // Refresh API key status when tab appears
                    isAPIKeyConfigured = APIKeyHelper.isConfigured
                }
            }
        }
    }
}

