//
//  APIKeySetupView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/8/25.
//

import SwiftUI
import OSLog

struct APIKeySetupView: View {
    @Binding var isPresented: Bool
    @State private var apiKey = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isValidating = false
    @State private var skipValidation = false
    
    var log = OSLog(subsystem: "com.headydiscy.Reczipes2", category: "APIKeySetupView")
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to Reczipes!")
                            .font(.title2)
                            .bold()
                        
                        Text("To extract recipes from images using AI, you need a Claude API key from Anthropic.")
                            .font(.body)
                    }
                    .padding(.vertical, 8)
                    
                    Link(destination: URL(string: "https://console.anthropic.com/settings/keys")!) {
                        HStack {
                            Text("Get API Key from Anthropic")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                } header: {
                    Text("Claude API Key Setup")
                }
                
                Section {
                    SecureField("Enter API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isValidating)
                        .font(.system(.body, design: .monospaced))
                    
                    if !apiKey.isEmpty {
                        HStack {
                            Text("Key Length:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(apiKey.count) characters")
                                .font(.caption)
                                .foregroundColor(apiKey.count == 108 ? .green : .orange)
                            if apiKey.count != 108 {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Toggle("Skip validation (not recommended)", isOn: $skipValidation)
                        .font(.caption)
                    
                    Button(isValidating ? "Validating..." : skipValidation ? "Save Without Validation" : "Save & Validate API Key") {
                        Task {
                            await validateAndSaveAPIKey()
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    
                    if isValidating {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Testing API key with Anthropic...")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if showError {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                } header: {
                    Text("Enter Your API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        if !skipValidation {
                            Text("Your API key will be tested before saving.")
                        }
                        Text("It's stored securely in the Keychain.")
                        Text("API keys are exactly 108 characters and start with 'sk-ant-api03-'")
                            .bold()
                        if apiKey.count == 107 || apiKey.count == 109 {
                            Text("⚠️ Your key has \(apiKey.count) characters. Double-check you copied the entire key!")
                                .foregroundColor(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Section {
                    Button("Skip for Now") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                } footer: {
                    Text("You can add your API key later in Settings. Without an API key, you won't be able to extract recipes from images.")
                        .font(.caption)
                }
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.large)
        }
        .interactiveDismissDisabled(isValidating)
    }
    
    @MainActor
    private func validateAndSaveAPIKey() async {
        print("🔑 Starting API key validation in setup...")
        
        showError = false
        errorMessage = ""
        isValidating = true
        
        // Sanitize the API key - remove any whitespace, newlines, etc.
        let cleanedKey = apiKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
        
        print("🔑 Original key length: \(apiKey.count), Cleaned key length: \(cleanedKey.count)")
        
        // Basic validation
        guard cleanedKey.hasPrefix("sk-ant-") else {
            showError = true
            errorMessage = "Invalid API key format. Keys should start with 'sk-ant-api03-'"
            isValidating = false
            return
        }
        
        // Check length
        if cleanedKey.count != 108 {
            showError = true
            errorMessage = "API key should be exactly 108 characters. Your key has \(cleanedKey.count) characters. Please copy the complete key from Anthropic."
            isValidating = false
            return
        }
        
        // If skipping validation, just save it
        if skipValidation {
            print("🔑 Skipping validation, saving directly...")
            if APIKeyHelper.setAPIKey(cleanedKey) {
                print("🔑 API key saved successfully (without validation)!")
                isPresented = false
            } else {
                showError = true
                errorMessage = "Failed to save the API key to Keychain."
            }
            isValidating = false
            return
        }
        
        // Validate with Anthropic
        let client = ClaudeAPIClient(apiKey: cleanedKey)
        let isValid = await client.validateAPIKey()
        
        isValidating = false
        
        if isValid {
            print("🔑 API key is valid, saving...")
            if APIKeyHelper.setAPIKey(cleanedKey) {
                print("🔑 API key saved successfully!")
                // Dismiss the setup view
                isPresented = false
            } else {
                showError = true
                errorMessage = "Failed to save the API key to Keychain."
            }
        } else {
            print("🔑 API key validation failed")
            showError = true
            errorMessage = "Could not validate with Anthropic. Your key appears to be 108 characters and correctly formatted, but Anthropic rejected it. Please verify it's active in the Anthropic console, or use 'Skip validation' to save it anyway."
        }
    }
}

#Preview {
    APIKeySetupView(isPresented: .constant(true))
}
