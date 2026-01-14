//
//  CloudKitSyncMonitor.swift
//  Reczipes2
//
//  Created for monitoring CloudKit sync status
//

import Foundation
import SwiftUI
import CloudKit
import Combine

/// Monitor CloudKit account and sync status
@MainActor
class CloudKitSyncMonitor: ObservableObject {
    static let shared = CloudKitSyncMonitor()
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var isSyncEnabled: Bool = false
    @Published var lastSyncError: String?
    @Published var isCheckingStatus: Bool = false
    
    private let container = CKContainer.default()
    private var hasWarnedAboutStatus: Set<String> = []
    
    private init() {
        Task {
            await checkAccountStatus()
        }
        
        // Monitor account changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAccountChange),
            name: .CKAccountChanged,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async {
        isCheckingStatus = true
        defer { isCheckingStatus = false }
        
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            
            switch status {
            case .available:
                isSyncEnabled = true
                lastSyncError = nil
                // Only print once when status changes to available
                if !hasWarnedAboutStatus.contains("available") {
                    print("✅ iCloud is available and ready to sync")
                    hasWarnedAboutStatus.insert("available")
                    // Clear other warnings since we're now available
                    hasWarnedAboutStatus.remove("noAccount")
                    hasWarnedAboutStatus.remove("restricted")
                    hasWarnedAboutStatus.remove("couldNotDetermine")
                    hasWarnedAboutStatus.remove("temporarilyUnavailable")
                }
                
            case .noAccount:
                isSyncEnabled = false
                lastSyncError = "No iCloud account found. Please sign in to iCloud in Settings."
                if !hasWarnedAboutStatus.contains("noAccount") {
                    print("⚠️ No iCloud account")
                    hasWarnedAboutStatus.insert("noAccount")
                }
                
            case .restricted:
                isSyncEnabled = false
                lastSyncError = "iCloud is restricted on this device."
                if !hasWarnedAboutStatus.contains("restricted") {
                    print("⚠️ iCloud is restricted")
                    hasWarnedAboutStatus.insert("restricted")
                }
                
            case .couldNotDetermine:
                isSyncEnabled = false
                lastSyncError = "Could not determine iCloud status."
                if !hasWarnedAboutStatus.contains("couldNotDetermine") {
                    print("⚠️ Could not determine iCloud status")
                    hasWarnedAboutStatus.insert("couldNotDetermine")
                }
                
            case .temporarilyUnavailable:
                isSyncEnabled = false
                lastSyncError = "iCloud is temporarily unavailable."
                if !hasWarnedAboutStatus.contains("temporarilyUnavailable") {
                    print("⚠️ iCloud temporarily unavailable")
                    hasWarnedAboutStatus.insert("temporarilyUnavailable")
                }
                
            @unknown default:
                isSyncEnabled = false
                lastSyncError = "Unknown iCloud status."
                if !hasWarnedAboutStatus.contains("unknown") {
                    print("⚠️ Unknown iCloud status")
                    hasWarnedAboutStatus.insert("unknown")
                }
            }
        } catch {
            isSyncEnabled = false
            lastSyncError = "Error checking iCloud status: \(error.localizedDescription)"
            // Always print errors since they might be different each time
            print("❌ Error checking account status: \(error)")
        }
    }
    
    @objc private func handleAccountChange() {
        Task { @MainActor in
            print("🔄 iCloud account changed, rechecking status...")
            // Clear warnings when account changes so we get fresh feedback
            hasWarnedAboutStatus.removeAll()
            await checkAccountStatus()
            
            // Notify the container manager to potentially recreate the container
            // The manager will decide if recreation is actually needed
            await ModelContainerManager.shared.recreateContainer()
        }
    }
    
    // MARK: - User-Facing Status
    
    var statusMessage: String {
        switch accountStatus {
        case .available:
            return "iCloud sync is active"
        case .noAccount:
            return "Sign in to iCloud to sync across devices"
        case .restricted:
            return "iCloud is restricted on this device"
        case .couldNotDetermine:
            return "Checking iCloud status..."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable"
        @unknown default:
            return "Unknown iCloud status"
        }
    }
    
    var statusIcon: String {
        switch accountStatus {
        case .available:
            return "icloud.fill"
        case .noAccount:
            return "icloud.slash"
        case .restricted:
            return "exclamationmark.icloud"
        case .couldNotDetermine:
            return "questionmark.circle"
        case .temporarilyUnavailable:
            return "icloud.slash"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    var statusColor: Color {
        switch accountStatus {
        case .available:
            return .green
        case .noAccount:
            return .orange
        case .restricted:
            return .red
        case .couldNotDetermine:
            return .gray
        case .temporarilyUnavailable:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

// MARK: - Sync Status View

struct CloudKitSyncStatusView: View {
    @StateObject private var monitor = CloudKitSyncMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: monitor.statusIcon)
                    .foregroundColor(monitor.statusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Sync")
                        .font(.headline)
                    
                    if monitor.isCheckingStatus {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Checking status...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(monitor.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if monitor.accountStatus != .available && !monitor.isCheckingStatus {
                    Button("Refresh") {
                        Task {
                            await monitor.checkAccountStatus()
                        }
                    }
                    .font(.caption)
                }
            }
            
            if let error = monitor.lastSyncError, !monitor.isSyncEnabled {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            
            if monitor.accountStatus == .noAccount {
                Button {
                    // Open Settings app
                    if let url = URL(string: "App-prefs:root=CASTLE") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gearshape.fill")
                        Text("Open iCloud Settings")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
            
            // Advanced: Manual container recreation button
            Button {
                Task {
                    await ModelContainerManager.shared.manuallyRecreateContainer()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Reconnect to iCloud")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .task {
            await monitor.checkAccountStatus()
        }
    }
}

// MARK: - Compact Status Badge

struct CloudKitSyncBadge: View {
    @StateObject private var monitor = CloudKitSyncMonitor.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: monitor.statusIcon)
                .foregroundColor(monitor.statusColor)
            
            if monitor.isSyncEnabled {
                Text("Syncing")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await monitor.checkAccountStatus()
        }
    }
}
