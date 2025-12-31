//
//  AppClipAPIKeyHelper.swift
//  Reczipes2Clip
//
//  API Key management for App Clip
//  Created by Zahirudeen Premji on 12/30/25.
//
//  ⚠️ This file should ONLY be in the App Clip target (Reczipes2Clip)
//

import SwiftUI

// MARK: - App Clip API Key Helper

/// Lightweight API key helper for App Clips
/// Uses App Group to share with main app if available
struct AppClipAPIKeyHelper {
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.headydiscy.reczipes")
    private static let apiKeyKey = "claudeAPIKey"
    
    static var isConfigured: Bool {
        if let key = sharedDefaults?.string(forKey: apiKeyKey), !key.isEmpty {
            return true
        }
        // Fallback to standard UserDefaults
        return UserDefaults.standard.string(forKey: apiKeyKey) != nil
    }
    
    static func getAPIKey() -> String? {
        // Try shared defaults first (might have it from main app)
        if let key = sharedDefaults?.string(forKey: apiKeyKey) {
            return key
        }
        // Fallback to App Clip's own storage
        return UserDefaults.standard.string(forKey: apiKeyKey)
    }
    
    static func setAPIKey(_ key: String) {
        // Save to App Clip storage
        UserDefaults.standard.set(key, forKey: apiKeyKey)
        // Also save to shared storage
        sharedDefaults?.set(key, forKey: apiKeyKey)
    }
    
    // For demo purposes, you could provide a rate-limited demo key
    static let demoAPIKey: String? = nil // Set to your demo key if you have one
}

// MARK: - API Key Prompt View

struct AppClipAPIKeyPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var showError = false
    @State private var useDemoMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    Text("Quick Setup")
                        .font(.title2.bold())
                    
                    Text("To extract recipes, enter your Claude API key or try demo mode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // API Key Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude API Key")
                        .font(.subheadline.weight(.medium))
                    
                    SecureField("sk-ant-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Text("Get your free API key from anthropic.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        saveAndContinue()
                    } label: {
                        Text("Save & Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(apiKey.isEmpty ? Color.gray : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(apiKey.isEmpty)
                    
                    if let demoKey = AppClipAPIKeyHelper.demoAPIKey {
                        Button {
                            useDemoMode = true
                            AppClipAPIKeyHelper.setAPIKey(demoKey)
                            dismiss()
                        } label: {
                            Text("Try Demo (Limited)")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button("Skip for Now") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Get Full App
                VStack(spacing: 8) {
                    Text("Want the full experience?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Get Reczipes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Invalid API Key", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid Claude API key starting with 'sk-ant-'")
            }
        }
    }
    
    private func saveAndContinue() {
        guard apiKey.hasPrefix("sk-ant-") else {
            showError = true
            return
        }
        
        AppClipAPIKeyHelper.setAPIKey(apiKey)
        dismiss()
    }
}
