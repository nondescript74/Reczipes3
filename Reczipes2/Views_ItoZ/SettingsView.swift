//
//  SettingsView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/8/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var showAPIKeyManager = false
    @State private var isAPIKeyConfigured = APIKeyHelper.isConfigured
    @State private var showLicenseAgreement = false
    @State private var showHelpBrowser = false
    @State private var showDiagnosticLog = false
    
    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Global batch extraction status bar
            BatchExtractionStatusBar(manager: BatchExtractionManager.shared)
            
            NavigationView {
                Form {
                    Section("Recipe Extraction") {
                        HStack {
                            Text("API Key Status")
                            Spacer()
                            if isAPIKeyConfigured {
                                Label("Configured", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Label("Not Set", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Button("Manage API Key") {
                            showAPIKeyManager = true
                        }
                        
                        Toggle("Auto-Extract on Image Selection",
                               isOn: .constant(RecipeExtractorConfig.autoExtractOnImageSelection))
                        
                        Toggle("Enable Image Preprocessing",
                               isOn: .constant(RecipeExtractorConfig.defaultUsePreprocessing))
                    }
                    
                    Section("Data & Sync") {
                        NavigationLink(destination: QuickSyncStatusView()) {
                            HStack {
                                Label("Quick Sync Check", systemImage: "checkmark.circle")
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        
                        NavigationLink(destination: CloudKitSyncStatusMonitorView()) {
                            Label("Sync Monitor", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        
                        NavigationLink(destination: CloudKitSettingsView()) {
                            Label("iCloud Sync Settings", systemImage: "icloud.fill")
                        }
                        
                        NavigationLink(destination: RecipeImageMigrationView()) {
                            Label("Image Migration", systemImage: "photo.stack")
                        }
                        
                        NavigationLink(destination: UserContentBackupView()) {
                            Label("User Content Import/Export", systemImage: "arrow.up.arrow.down.circle")
                        }
                        
                        NavigationLink(destination: CloudKitDiagnosticsView()) {
                            Label("Advanced Diagnostics", systemImage: "stethoscope")
                        }
                        
                        NavigationLink(destination: PersistentContainerInfoView()) {
                            Label("Container Details", systemImage: "cylinder.split.1x2")
                        }
                        
                        NavigationLink(destination: CloudKitContainerValidationView()) {
                            HStack {
                                Label("Validate CloudKit Container", systemImage: "checkmark.seal.fill")
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Section {
                        NavigationLink {
                            FODMAPSettingsView()
                        } label: {
                            Label("FODMAP Settings", systemImage: "leaf.circle")
                        }
                        
                        NavigationLink {
                            DiabeticSettingsView()
                        } label: {
                            HStack {
                                Label("Diabetic-Friendly Analysis", systemImage: "heart.text.square")
                                Spacer()
                                if UserDiabeticSettings.shared.isDiabeticEnabled {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                        }
                    } header: {
                        Text("Dietary Preferences")
                    } footer: {
                        if UserDiabeticSettings.shared.isDiabeticEnabled {
                            Text("Diabetic-friendly analysis is enabled. Recipes can show glycemic load, carb counts, and substitution suggestions.")
                                .font(.caption)
                        }
                    }
                    
                    Section {
                        NavigationLink {
                            DatabaseInvestigationView()
                        } label: {
                            HStack {
                                Label("Database Investigation", systemImage: "magnifyingglass.circle.fill")
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        
                        NavigationLink {
                            DatabaseRecoveryView()
                        } label: {
                            Label("Database Recovery", systemImage: "externaldrive.badge.exclamationmark")
                        }
                    } header: {
                        Text("Developer Tools")
                    } footer: {
                        Text("Database Investigation shows all database files and their contents. Use this if recipes are missing after an update.")
                            .font(.caption)
                    }
                    
                    Section("Legal") {
                        Button {
                            showLicenseAgreement = true
                        } label: {
                            HStack {
                                Label("View License Agreement", systemImage: "doc.text")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let acceptanceDate = LicenseHelper.acceptanceDate {
                            HStack {
                                Text("Accepted On")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(acceptanceDate, style: .date)
                                    .foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Section {
                        Button {
                            showHelpBrowser = true
                        } label: {
                            HStack {
                                Label("Browse Help Topics", systemImage: "questionmark.circle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            showDiagnosticLog = true
                        } label: {
                            HStack {
                                Label("Diagnostic Log", systemImage: "doc.text")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Link(destination: URL(string: "https://www.monashfodmap.com")!) {
                            HStack {
                                Label("Monash FODMAP Research", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Link(destination: URL(string: "https://diabetes.org")!) {
                            HStack {
                                Label("American Diabetes Association", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Link(destination: URL(string: "https://console.anthropic.com")!) {
                            HStack {
                                Label("Get Claude API Key", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("Help & Support")
                    } footer: {
                        Text("External resources for FODMAP information, diabetes management, and API access.")
                            .font(.caption)
                    }
                    
                    Section("About") {
                        NavigationLink(destination: VersionHistoryView()) {
                            HStack {
                                Label("Version History", systemImage: "clock.arrow.circlepath")
                                Spacer()
                                Text(versionString)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            Text("Current Version")
                            Spacer()
                            Text(versionString)
                                .foregroundColor(.secondary)
                        }
                        
#if DEBUG
                        NavigationLink(destination: VersionDebugView()) {
                            HStack {
                                Label("Version Debug Info", systemImage: "ant.circle")
                                    .foregroundColor(.orange)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button {
                            VersionHistoryManager.shared.resetVersionTracking()
                        } label: {
                            HStack {
                                Label("Reset Version Tracking", systemImage: "arrow.counterclockwise")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
#endif
                        
                        Link("Powered by Claude AI",
                             destination: URL(string: "https://www.anthropic.com")!)
                    }
                }
                .navigationTitle("Settings")
                .fullScreenCover(isPresented: $showAPIKeyManager, onDismiss: {
                    // Refresh API key status when manager is dismissed
                    isAPIKeyConfigured = APIKeyHelper.isConfigured
                }) {
                    APIKeyManagerView()
                }
                .sheet(isPresented: $showLicenseAgreement) {
                    LicenseDisplayView()
                }
                .sheet(isPresented: $showHelpBrowser) {
                    HelpBrowserView()
                }
                .sheet(isPresented: $showDiagnosticLog) {
                    DiagnosticLogView()
                }
                .onAppear {
                    // Refresh API key status when view appears
                    isAPIKeyConfigured = APIKeyHelper.isConfigured
                }
            }
        }
    }
}

// MARK: - License Display View (for viewing only, not for initial acceptance)

struct LicenseDisplayView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(LicenseHelper.licenseText)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("License Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
