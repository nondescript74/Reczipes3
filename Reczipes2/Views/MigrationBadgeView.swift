//
//  MigrationBadgeView.swift
//  Reczipes2
//
//  Created on 1/27/26.
//
//  Badge indicator showing when legacy migration is available

import SwiftUI
import SwiftData

struct MigrationBadgeView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var needsMigration = false
    @State private var legacyCount = 0
    @State private var showingMigration = false
    
    var body: some View {
        Group {
            if needsMigration {
                Button {
                    showingMigration = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.caption)
                        Text("\(legacyCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .sheet(isPresented: $showingMigration) {
                    LegacyMigrationView()
                }
            }
        }
        .task {
            await checkMigrationStatus()
        }
    }
    
    private func checkMigrationStatus() async {
        let manager = LegacyToNewMigrationManager(modelContext: modelContext)
        let shouldMigrate = await manager.needsMigration()
        
        if shouldMigrate {
            let stats = await manager.getMigrationStats()
            await MainActor.run {
                needsMigration = true
                legacyCount = stats.totalLegacyItems
            }
        }
    }
}

#Preview {
    MigrationBadgeView()
        .modelContainer(for: [Recipe.self, RecipeX.self], inMemory: true)
}
