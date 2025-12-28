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
        
        // Check CloudKit availability
        Task {
            await CloudKitSyncMonitor.shared.checkAccountStatus()
        }
    }
    
    var sharedModelContainer: ModelContainer = {
        // Log schema version information
        SchemaVersionManager.logSchemaInfo()
        
        // MARK: - CloudKit Configuration with Migration Support
        // To disable CloudKit and use local-only storage, comment out the cloudKitDatabase parameter below
        
        // CloudKit configuration with migration plan
        let cloudKitConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private("iCloud.com.headydiscy.reczipes")
        )
        
        // Fallback configuration without CloudKit
        let localConfiguration = ModelConfiguration(
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .none
        )

        // Try CloudKit configuration first
        // Note: Lightweight migration (adding diabetesStatusRaw field) is automatic
        do {
            let schema = Schema([
                Recipe.self,
                RecipeImageAssignment.self,
                UserAllergenProfile.self,
                CachedDiabeticAnalysis.self,
                SavedLink.self,
                RecipeBook.self,
            ])
            
            let container = try ModelContainer(
                for: schema,
                configurations: [cloudKitConfiguration]
            )
            print("✅ ModelContainer created successfully with CloudKit sync enabled")
            print("   Container: iCloud.com.headydiscy.reczipes")
            print("   Automatic lightweight migration enabled for schema changes")
            return container
        } catch {
            // CloudKit failed, try local-only as fallback
            print("⚠️ CloudKit ModelContainer creation failed: \(error)")
            print("   Attempting fallback to local-only container...")
            
            do {
                let schema = Schema([
                    Recipe.self,
                    RecipeImageAssignment.self,
                    UserAllergenProfile.self,
                    CachedDiabeticAnalysis.self,
                    SavedLink.self,
                    RecipeBook.self,
                ])
                
                let container = try ModelContainer(
                    for: schema,
                    configurations: [localConfiguration]
                )
                print("✅ ModelContainer created successfully (local-only, no CloudKit sync)")
                print("   Automatic lightweight migration enabled for schema changes")
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
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                        
                        // Show launch screen on first launch
                        showLaunchScreen = appState.shouldShowLaunchScreen()
                    }
                
                // Launch screen overlay - shows briefly on every launch
                if showLaunchScreen {
                    LaunchScreenView {
                        // Dismiss launch screen and mark first launch as complete
                        withAnimation {
                            showLaunchScreen = false
                            appState.isFirstLaunch = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
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

