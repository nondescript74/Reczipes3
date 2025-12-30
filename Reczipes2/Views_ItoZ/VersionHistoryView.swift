//
//  VersionHistoryView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/30/24.
//

import SwiftUI

struct VersionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let allHistory = VersionHistoryManager.shared.getAllHistory()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current version header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "app.badge")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            
                            Text("Current Version")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(VersionHistoryManager.shared.currentVersionString)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                    
                    // Version history list
                    ForEach(allHistory) { entry in
                        VersionHistoryCard(entry: entry)
                    }
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Version History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(
                        item: VersionHistoryManager.shared.getFormattedChangelog(),
                        preview: SharePreview(
                            "Reczipes Version History",
                            image: Image(systemName: "doc.text")
                        )
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

// MARK: - Version History Card

struct VersionHistoryCard: View {
    let entry: VersionHistoryEntry
    @State private var isExpanded = false
    
    private var isCurrentVersion: Bool {
        entry.versionString == VersionHistoryManager.shared.currentVersionString
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Version \(entry.version)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("(\(entry.buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if isCurrentVersion {
                            Text("CURRENT")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor)
                                )
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(formatDate(entry.releaseDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Changes list
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.changes, id: \.self) { change in
                        HStack(alignment: .top, spacing: 8) {
                            Text(change)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Show first 3 changes as preview
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(entry.changes.prefix(3)), id: \.self) { change in
                        Text(change)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if entry.changes.count > 3 {
                        Text("+ \(entry.changes.count - 3) more changes...")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.top, 2)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .onAppear {
            // Auto-expand current version
            if isCurrentVersion {
                isExpanded = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    VersionHistoryView()
}
