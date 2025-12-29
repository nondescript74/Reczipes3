//
//  PersistentContainerInfoView.swift
//  Reczipes2
//
//  Shows detailed information about the ModelContainer configuration
//

import SwiftUI
import SwiftData

struct PersistentContainerInfoView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var containerInfo: ContainerInfo?
    @State private var isLoading = true
    
    var body: some View {
        List {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading container info...")
                        .foregroundColor(.secondary)
                }
            } else if let info = containerInfo {
                Section("Container Configuration") {
                    InfoRow(label: "Container Type", value: info.containerType)
                    InfoRow(label: "CloudKit Enabled", value: info.cloudKitEnabled ? "Yes" : "No")
                    
                    if info.cloudKitEnabled {
                        InfoRow(label: "Container ID", value: info.containerIdentifier)
                        InfoRow(label: "Database Type", value: info.databaseType)
                    }
                }
                
                Section("Schema") {
                    ForEach(info.modelTypes, id: \.self) { modelType in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(modelType)
                        }
                    }
                }
                
                Section("Storage") {
                    InfoRow(label: "Stored in Memory", value: info.isStoredInMemory ? "Yes" : "No")
                    InfoRow(label: "Allows Save", value: info.allowsSave ? "Yes" : "No")
                    
                    if let url = info.storageURL {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Storage Location")
                                .font(.headline)
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                }
                
                Section("Statistics") {
                    InfoRow(label: "Total Recipes", value: "\(info.recipeCount)")
                    InfoRow(label: "Recipe Books", value: "\(info.recipeBookCount)")
                    InfoRow(label: "Saved Links", value: "\(info.savedLinkCount)")
                }
                
                Section("Actions") {
                    Button("Refresh Info") {
                        Task {
                            await loadContainerInfo()
                        }
                    }
                    
                    Button("Copy Configuration") {
                        copyConfiguration()
                    }
                }
            } else {
                Section {
                    Text("Could not load container information")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Container Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContainerInfo()
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadContainerInfo() async {
        isLoading = true
        defer { isLoading = false }
        
        // Get the container from the model context
        let container = modelContext.container
        
        // Gather information
        var info = ContainerInfo()
        
        // Check configurations
        if let firstConfig = container.configurations.first {
            info.containerType = "ModelContainer (SwiftData)"
            
            // CloudKit configuration analysis
            // We check the cloudKitDatabase by examining its description
            // since it's an enum without directly accessible properties
            let cloudKitDB = firstConfig.cloudKitDatabase
            let cloudKitDescription = String(describing: cloudKitDB)
            
            // Check if CloudKit is enabled by examining the description
            if cloudKitDescription.contains("none") {
                info.cloudKitEnabled = false
                info.databaseType = "Local Only"
                info.containerIdentifier = "None"
            } else if cloudKitDescription.contains("automatic") {
                info.cloudKitEnabled = true
                info.databaseType = "CloudKit (Private - Automatic)"
                info.containerIdentifier = "Default Container"
            } else if cloudKitDescription.contains("private") {
                info.cloudKitEnabled = true
                info.databaseType = "CloudKit (Private)"
                
                // Try to extract container identifier from description
                // Format is typically: private("iCloud.com.example.app")
                if let range = cloudKitDescription.range(of: "\"([^\"]+)\"", options: .regularExpression) {
                    let extracted = String(cloudKitDescription[range])
                    info.containerIdentifier = extracted.replacingOccurrences(of: "\"", with: "")
                } else {
                    info.containerIdentifier = "Private Container"
                }
            } else if cloudKitDescription.contains("public") {
                info.cloudKitEnabled = true
                info.databaseType = "CloudKit (Public)"
                info.containerIdentifier = "Public Container"
            } else if cloudKitDescription.contains("shared") {
                info.cloudKitEnabled = true
                info.databaseType = "CloudKit (Shared)"
                info.containerIdentifier = "Shared Container"
            } else {
                info.cloudKitEnabled = false
                info.databaseType = "Unknown"
                info.containerIdentifier = "Unknown"
            }
            
            info.isStoredInMemory = firstConfig.isStoredInMemoryOnly
            info.allowsSave = firstConfig.allowsSave
            info.storageURL = firstConfig.url.path
        }
        
        // Get schema information
        info.modelTypes = container.schema.entities.map { $0.name }.sorted()
        
        // Get counts
        info.recipeCount = (try? modelContext.fetchCount(FetchDescriptor<Recipe>())) ?? 0
        info.recipeBookCount = (try? modelContext.fetchCount(FetchDescriptor<RecipeBook>())) ?? 0
        info.savedLinkCount = (try? modelContext.fetchCount(FetchDescriptor<SavedLink>())) ?? 0
        
        containerInfo = info
        
        // Print to console
        printContainerInfo(info)
    }
    
    private func printContainerInfo(_ info: ContainerInfo) {
        print("\n" + String(repeating: "=", count: 60))
        print("📦 PERSISTENT CONTAINER INFORMATION")
        print(String(repeating: "=", count: 60))
        
        print("\n🏗️  CONFIGURATION:")
        print("   Type: \(info.containerType)")
        print("   CloudKit: \(info.cloudKitEnabled ? "✅ Enabled" : "❌ Disabled")")
        
        if info.cloudKitEnabled {
            print("   Container ID: \(info.containerIdentifier)")
            print("   Database: \(info.databaseType)")
        }
        
        print("\n💾 STORAGE:")
        print("   In Memory: \(info.isStoredInMemory ? "Yes" : "No")")
        print("   Allows Save: \(info.allowsSave ? "Yes" : "No")")
        if let url = info.storageURL {
            print("   Location: \(url)")
        }
        
        print("\n📋 SCHEMA:")
        for modelType in info.modelTypes {
            print("   • \(modelType)")
        }
        
        print("\n📊 DATA:")
        print("   Recipes: \(info.recipeCount)")
        print("   Recipe Books: \(info.recipeBookCount)")
        print("   Saved Links: \(info.savedLinkCount)")
        
        print("\n" + String(repeating: "=", count: 60) + "\n")
    }
    
    private func copyConfiguration() {
        guard let info = containerInfo else { return }
        
        var text = "=== Persistent Container Configuration ===\n\n"
        
        text += "Type: \(info.containerType)\n"
        text += "CloudKit: \(info.cloudKitEnabled ? "Enabled" : "Disabled")\n"
        
        if info.cloudKitEnabled {
            text += "Container ID: \(info.containerIdentifier)\n"
            text += "Database: \(info.databaseType)\n"
        }
        
        text += "\nStorage:\n"
        text += "  In Memory: \(info.isStoredInMemory ? "Yes" : "No")\n"
        text += "  Allows Save: \(info.allowsSave ? "Yes" : "No")\n"
        
        if let url = info.storageURL {
            text += "  Location: \(url)\n"
        }
        
        text += "\nSchema Models:\n"
        for modelType in info.modelTypes {
            text += "  • \(modelType)\n"
        }
        
        text += "\nData Counts:\n"
        text += "  Recipes: \(info.recipeCount)\n"
        text += "  Recipe Books: \(info.recipeBookCount)\n"
        text += "  Saved Links: \(info.savedLinkCount)\n"
        
        UIPasteboard.general.string = text
        print("📋 Configuration copied to clipboard")
    }
}

// MARK: - Supporting Types

struct ContainerInfo {
    var containerType: String = "Unknown"
    var cloudKitEnabled: Bool = false
    var containerIdentifier: String = "Unknown"
    var databaseType: String = "Unknown"
    var isStoredInMemory: Bool = false
    var allowsSave: Bool = true
    var storageURL: String?
    var modelTypes: [String] = []
    var recipeCount: Int = 0
    var recipeBookCount: Int = 0
    var savedLinkCount: Int = 0
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PersistentContainerInfoView()
    }
}
