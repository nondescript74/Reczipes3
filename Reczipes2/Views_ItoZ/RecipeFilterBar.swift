//
//  RecipeFilterBar.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import SwiftUI

struct RecipeFilterBar: View {
    @Binding var filterMode: RecipeFilterMode
    @Binding var showOnlySafe: Bool
    let activeProfile: UserAllergenProfile?
    let onProfileTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Filter Mode Picker
            Picker("Filter Mode", selection: $filterMode) {
                ForEach(RecipeFilterMode.allCases) { mode in
                    Label(mode.displayName, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Filter Details Section (only show when a filter is active)
            if filterMode != .none {
                HStack(spacing: 12) {
                    // Show active profile info for allergen filters
                    if filterMode.includesAllergenFilter {
                        allergenProfileSection
                    }
                    
                    // Show diabetes status for diabetes filters
                    if filterMode.includesDiabetesFilter {
                        diabetesStatusSection
                    }
                    
                    Spacer()
                    
                    // Show only safe toggle
                    Toggle(isOn: $showOnlySafe) {
                        Text("Only Safe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .toggleStyle(.switch)
                    .fixedSize()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Allergen Profile Section
    
    private var allergenProfileSection: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(activeProfile != nil ? .blue : .secondary)
                
                if let profile = activeProfile {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("\(profile.sensitivities.count) sensitivit\(profile.sensitivities.count == 1 ? "y" : "ies")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Profile")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Diabetes Status Section
    
    private var diabetesStatusSection: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 6) {
                Image(systemName: "heart.text.square.fill")
                    .foregroundStyle(activeProfile?.hasDiabetesConcern == true ? .red : .secondary)
                
                if let profile = activeProfile, profile.hasDiabetesConcern {
                    HStack(spacing: 4) {
                        Text(profile.diabetesStatus.icon)
                            .font(.caption)
                        Text(profile.diabetesStatus.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                } else {
                    Text("No Diabetes Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Status Header

struct RecipeFilterStatusHeader: View {
    let filterMode: RecipeFilterMode
    let showOnlySafe: Bool
    let totalRecipes: Int
    let filteredCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: filterMode.icon)
                .foregroundStyle(iconColor)
            
            Text(headerText)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("(\(filteredCount))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var headerText: String {
        switch filterMode {
        case .none:
            return "All Recipes"
        case .allergenFODMAP:
            if showOnlySafe {
                return "Safe for Allergens & FODMAP"
            } else {
                return "Sorted by Allergen Safety"
            }
        case .diabetes:
            if showOnlySafe {
                return "Diabetes-Friendly Recipes"
            } else {
                return "Sorted by Diabetes Suitability"
            }
        case .all:
            if showOnlySafe {
                return "Safe for All Conditions"
            } else {
                return "Sorted by Overall Safety"
            }
        }
    }
    
    private var iconColor: Color {
        switch filterMode {
        case .none:
            return .secondary
        case .allergenFODMAP:
            return .orange
        case .diabetes:
            return .blue
        case .all:
            return .purple
        }
    }
}

#Preview {
    VStack {
        RecipeFilterBar(
            filterMode: .constant(.allergenFODMAP),
            showOnlySafe: .constant(false),
            activeProfile: nil,
            onProfileTap: {}
        )
        
        RecipeFilterBar(
            filterMode: .constant(.none),
            showOnlySafe: .constant(false),
            activeProfile: nil,
            onProfileTap: {}
        )
    }
}
