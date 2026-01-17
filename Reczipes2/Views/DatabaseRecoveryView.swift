//
//  DatabaseRecoveryView.swift
//  Reczipes2
//
//  Created by Assistant on 1/15/26.
//  UI for recovering recipes after database migration issues
//

import SwiftUI
import SwiftData

struct DatabaseRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var migrationInfo: DatabaseMigrationInfo?
    @State private var isChecking = true
    @State private var recoveryResult: RecoveryResult?
    @State private var isRecovering = false
    @State private var error: Error?
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isChecking {
                    checkingView
                } else if let info = migrationInfo {
                    recoveryAvailableView(info: info)
                } else if let result = recoveryResult {
                    recoveryCompleteView(result: result)
                } else {
                    noRecoveryNeededView
                }
            }
            .padding()
            .navigationTitle("Database Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Recovery Complete", isPresented: $showSuccessAlert) {
                Button("Restart App") {
                    // User needs to restart the app to see recovered data
                    exit(0)
                }
                Button("Close", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your recipes have been recovered! Please restart the app to see your data.")
            }
            .task {
                await checkForRecovery()
            }
        }
    }
    
    // MARK: - Views
    
    private var checkingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Checking for recoverable data...")
                .font(.headline)
            
            Text("Scanning database files...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func recoveryAvailableView(info: DatabaseMigrationInfo) -> some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            // Title
            Text("Recipes Found!")
                .font(.title)
                .fontWeight(.bold)
            
            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text("We found your recipes in a different database file. This can happen after app updates.")
                    .font(.body)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Old Database")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(info.oldDatabaseURL.lastPathComponent)
                                .font(.footnote)
                                .fontWeight(.medium)
                            Text(info.oldDatabaseSizeFormatted)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "externaldrive.fill")
                            .foregroundStyle(.orange)
                    }
                    
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Database")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(info.currentDatabaseURL.lastPathComponent)
                                .font(.footnote)
                                .fontWeight(.medium)
                            Text(info.currentDatabaseSizeFormatted)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "internaldrive")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Recovery button
            VStack(spacing: 12) {
                Button(action: { Task { await performRecovery(info: info) } }) {
                    HStack {
                        if isRecovering {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(isRecovering ? "Recovering..." : "Recover My Recipes")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isRecovering)
                
                Text("This will copy your old database to the current location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private func recoveryCompleteView(result: RecoveryResult) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Recovery Complete!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Successfully recovered:")
                    .font(.headline)
                
                if result.recipesFound > 0 {
                    Label("\(result.recipesFound) recipe\(result.recipesFound == 1 ? "" : "s")",
                          systemImage: "book.fill")
                }
                
                if result.booksFound > 0 {
                    Label("\(result.booksFound) recipe book\(result.booksFound == 1 ? "" : "s")",
                          systemImage: "books.vertical.fill")
                }
                
                if result.profilesFound > 0 {
                    Label("\(result.profilesFound) user profile\(result.profilesFound == 1 ? "" : "s")",
                          systemImage: "person.fill")
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 8) {
                Text("⚠️ Important")
                    .font(.headline)
                    .foregroundStyle(.orange)
                
                Text("Please restart the app to see your recovered recipes.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Button("Restart App Now") {
                showSuccessAlert = true
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var noRecoveryNeededView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("All Good!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("No database recovery needed. Your recipes are in the correct location.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Actions
    
    private func checkForRecovery() async {
        isChecking = true
        migrationInfo = await DatabaseRecoveryService.checkForDatabaseMigration()
        isChecking = false
    }
    
    private func performRecovery(info: DatabaseMigrationInfo) async {
        isRecovering = true
        error = nil
        
        do {
            // First, check what's in the old database
            let result = try await DatabaseRecoveryService.recoverFromOldDatabase(migrationInfo: info)
            
            if result.hasData {
                // Backup old database first
                _ = try DatabaseRecoveryService.backupOldDatabase(url: info.oldDatabaseURL)
                
                // Copy old database to current location
                try DatabaseRecoveryService.copyOldDatabaseToCurrent(migrationInfo: info)
                
                recoveryResult = result
            } else {
                error = RecoveryError.noDataFound
            }
        } catch {
            self.error = error
        }
        
        isRecovering = false
    }
}

enum RecoveryError: LocalizedError {
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .noDataFound:
            return "No recipes found in the old database"
        }
    }
}

#Preview {
    DatabaseRecoveryView()
}
