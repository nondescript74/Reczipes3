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
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
            RecipeImageAssignment.self,
            UserAllergenProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var showLicenseAgreement = !LicenseHelper.hasAcceptedLicense
    @State private var showAPIKeySetup = false
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
                    }
                
                // Launch screen overlay - only shows on true first launch
                if appState.shouldShowLaunchScreen() {
                    LaunchScreenView {
                        withAnimation {
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

