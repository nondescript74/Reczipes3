//
//  APIKeyManagerView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/8/25.
//

import SwiftUI

// MARK: - API Key Manager View

struct APIKeyManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newAPIKey = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isValidating = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if APIKeyHelper.isConfigured {
                        HStack {
                            Text("Status")
                            Spacer()
                            Label("Configured", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        Button("Remove API Key", role: .destructive) {
                            removeAPIKey()
                        }
                    } else {
                        Text("No API key configured")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    SecureField("Enter new API key", text: $newAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isValidating)
                    
                    Button(isValidating ? "Validating..." : "Update API Key") {
                        Task {
                            await updateAPIKey()
                        }
                    }
                    .disabled(newAPIKey.isEmpty || isValidating)
                } header: {
                    Text("Update API Key")
                } footer: {
                    Text("Your API key will be tested with Anthropic before being saved. It's stored securely in the Keychain.")
                }
                
                // Separate section for feedback to make it more visible
                if isValidating || showSuccess || showError {
                    Section {
                        if isValidating {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Testing API key with Anthropic...")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showSuccess {
                            Label("API Key validated and saved successfully!", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        
                        if showError {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Failed to validate API Key", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("API Key Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateAPIKey() async {
        print("🔑 Starting API key validation...")
        showSuccess = false
        showError = false
        errorMessage = ""
        isValidating = true
        
        print("🔑 isValidating set to true")
        
        // Sanitize the API key - remove any whitespace, newlines, etc.
        let cleanedKey = newAPIKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
        
        print("🔑 Original key length: \(newAPIKey.count), Cleaned key length: \(cleanedKey.count)")
        
        // Basic validation
        if !cleanedKey.hasPrefix("sk-ant-") {
            showError = true
            errorMessage = "Invalid API key format. Keys should start with 'sk-ant-api03-'"
            isValidating = false
            return
        }
        
        if cleanedKey.count < 50 {
            showError = true
            errorMessage = "API key seems too short. Please verify you copied the entire key."
            isValidating = false
            return
        }
        
        // First, validate the API key with Anthropic
        let client = ClaudeAPIClient(apiKey: cleanedKey)
        print("🔑 Calling validateAPIKey...")
        let isValid = await client.validateAPIKey()
        print("🔑 Validation result: \(isValid)")
        
        // All UI updates on main thread
        isValidating = false
        print("🔑 isValidating set to false")
        
        if isValid {
            print("🔑 API key is valid, attempting to save...")
            // API key is valid, save it
            if APIKeyHelper.setAPIKey(cleanedKey) {
                print("🔑 API key saved successfully!")
                showSuccess = true
                newAPIKey = ""
                
                // Dismiss after showing success
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                print("🔑 Dismissing view...")
                dismiss()
            } else {
                print("🔑 Failed to save to Keychain")
                showError = true
                errorMessage = "Failed to save the API key to Keychain."
            }
        } else {
            print("🔑 API key validation failed")
            // API key is invalid
            showError = true
            errorMessage = "Could not validate with Anthropic. Please verify your API key is correct and active in the Anthropic console."
        }
        
        print("🔑 Final state - showSuccess: \(showSuccess), showError: \(showError)")
    }
    
    private func removeAPIKey() {
        _ = KeychainManager.shared.delete(key: "claudeAPIKey")
        dismiss()
    }
}

#Preview {
    APIKeyManagerView()
}
