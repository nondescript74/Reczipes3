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
    
    var body: some View {
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
                
                Section("Help & Support") {
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
                    
                    Link(destination: URL(string: "https://console.anthropic.com")!) {
                        HStack {
                            Label("Get Claude API Key", systemImage: "link")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
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
