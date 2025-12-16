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
