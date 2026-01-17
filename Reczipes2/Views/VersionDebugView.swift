//
//  VersionDebugView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/30/24.
//

import SwiftUI

/// Debug view to check version detection and Info.plist values
struct VersionDebugView: View {
    
    private var bundleVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    private var bundleBuild: String? {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    }
    
    private var currentEntry: VersionHistoryEntry? {
        VersionHistoryManager.shared.getCurrentVersionEntry()
    }
    
    private var allEntries: [VersionHistoryEntry] {
        VersionHistoryManager.shared.getAllHistory()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Bundle Info (from Info.plist)") {
                    HStack {
                        Text("CFBundleShortVersionString")
                            .font(.caption)
                        Spacer()
                        if let version = bundleVersion {
                            Text(version)
                                .foregroundColor(.green)
                                .bold()
                        } else {
                            Text("❌ NOT FOUND")
                                .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        Text("CFBundleVersion")
                            .font(.caption)
                        Spacer()
                        if let build = bundleBuild {
                            Text(build)
                                .foregroundColor(.green)
                                .bold()
                        } else {
                            Text("❌ NOT FOUND")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("VersionHistoryManager Detection") {
                    HStack {
                        Text("Detected Version")
                        Spacer()
                        Text(VersionHistoryManager.shared.currentVersion)
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    HStack {
                        Text("Detected Build")
                        Spacer()
                        Text(VersionHistoryManager.shared.currentBuildNumber)
                            .foregroundColor(.blue)
                            .bold()
                    }
                    
                    HStack {
                        Text("Full String")
                        Spacer()
                        Text(VersionHistoryManager.shared.currentVersionString)
                            .foregroundColor(.purple)
                            .bold()
                    }
                }
                
                Section("Current Version Entry Match") {
                    if let entry = currentEntry {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Match Found!")
                                    .font(.headline)
                                Text("Version \(entry.version) (\(entry.buildNumber))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Changes (\(entry.changes.count)):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(Array(entry.changes.prefix(3)), id: \.self) { change in
                                Text(change)
                                    .font(.caption)
                            }
                            
                            if entry.changes.count > 3 {
                                Text("+ \(entry.changes.count - 3) more...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("No Match Found!")
                                .font(.headline)
                        }
                        
                        Text("The current version/build from Info.plist doesn't match any entry in VersionHistory.swift")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("All Version History Entries (\(allEntries.count))") {
                    ForEach(allEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Version \(entry.version) (\(entry.buildNumber))")
                                    .font(.subheadline)
                                    .bold()
                                
                                if entry.version == VersionHistoryManager.shared.currentVersion &&
                                   entry.buildNumber == VersionHistoryManager.shared.currentBuildNumber {
                                    Spacer()
                                    Text("CURRENT")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text("\(entry.changes.count) changes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("What's New (from getWhatsNew())") {
                    let whatsNew = VersionHistoryManager.shared.getWhatsNew()
                    
                    Text("Returns \(whatsNew.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(whatsNew, id: \.self) { change in
                        Text(change)
                            .font(.caption)
                    }
                }
                
                Section("Actions") {
                    Button {
                        VersionHistoryManager.shared.resetVersionTracking()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Version Tracking")
                        }
                    }
                    
                    Button {
                        // Print to console for debugging
                        print("🐛 VERSION DEBUG INFO")
                        print("Bundle Version: \(bundleVersion ?? "nil")")
                        print("Bundle Build: \(bundleBuild ?? "nil")")
                        print("Manager Version: \(VersionHistoryManager.shared.currentVersion)")
                        print("Manager Build: \(VersionHistoryManager.shared.currentBuildNumber)")
                        print("Manager String: \(VersionHistoryManager.shared.currentVersionString)")
                        print("Current Entry: \(currentEntry?.versionString ?? "nil")")
                        print("Should Show What's New: \(VersionHistoryManager.shared.shouldShowWhatsNew())")
                    } label: {
                        HStack {
                            Image(systemName: "ant.circle")
                            Text("Print Debug Info to Console")
                        }
                    }
                }
            }
            .navigationTitle("Version Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    VersionDebugView()
}
