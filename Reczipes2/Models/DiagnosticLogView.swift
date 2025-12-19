//
//  DiagnosticLogView.swift
//  Reczipes
//
//  Created on December 19, 2025.
//

import SwiftUI

/// View for displaying and managing the diagnostic log
struct DiagnosticLogView: View {
    
    @State private var logContents: String = ""
    @State private var isLoading = true
    @State private var showClearConfirmation = false
    @State private var showShareSheet = false
    @State private var fileSize: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Info header
                if !fileSize.isEmpty {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                        Text("Log file size: \(fileSize)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                }
                
                // Log contents
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading log...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if logContents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No logs yet")
                            .font(.headline)
                        Text("Diagnostic logs will appear here as you use the app")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(logContents)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Diagnostic Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    // Refresh button
                    Button {
                        loadLog()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                    
                    // Share button
                    if !logContents.isEmpty {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                    // Clear button
                    if !logContents.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirmation = true
                        } label: {
                            Label("Clear", systemImage: "trash")
                        }
                    }
                }
            }
            .task {
                loadLog()
            }
            .confirmationDialog(
                "Clear Diagnostic Log?",
                isPresented: $showClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Log", role: .destructive) {
                    clearLog()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all diagnostic log entries. This action cannot be undone.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = DiagnosticLogger.shared.getLogFileURL() {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadLog() {
        isLoading = true
        
        Task {
            // Run file I/O on background
            let contents = await Task.detached {
                await DiagnosticLogger.shared.getLogContents()
            }.value
            
            let size = await Task.detached {
                await DiagnosticLogger.shared.getFormattedLogFileSize()
            }.value
            
            await MainActor.run {
                self.logContents = contents
                self.fileSize = size
                self.isLoading = false
            }
        }
    }
    
    private func clearLog() {
        Task {
            await Task.detached {
                await DiagnosticLogger.shared.clearLog()
            }.value
            
            // Wait a moment for the file to be cleared
            try? await Task.sleep(for: .milliseconds(100))
            
            loadLog()
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

// MARK: - Preview

#Preview {
    DiagnosticLogView()
}
