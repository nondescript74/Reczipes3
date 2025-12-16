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
            .onAppear {
                // Refresh API key status when view appears
                isAPIKeyConfigured = APIKeyHelper.isConfigured
            }
        }
    }
}

#Preview {
    SettingsView()
}
