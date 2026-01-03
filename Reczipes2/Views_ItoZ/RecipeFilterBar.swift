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
            // Filter Mode Picker - Compact badges
            HStack(spacing: 8) {
                ForEach(RecipeFilterMode.allCases) { mode in
                    filterBadge(for: mode)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Filter Details Section (only show when a filter is active)
            if filterMode != .none {
                HStack(spacing: 8) {
                    // Show active profile info for allergen filters
                    if filterMode.includesAllergenFilter {
                        allergenProfileSection
                    }
                    
                    // Show diabetes status for diabetes filters
                    if filterMode.includesDiabetesFilter {
                        diabetesStatusSection
                    }
                    
                    // Show nutrition status for nutrition filters
                    if filterMode.includesNutritionalFilter {
                        nutritionStatusSection
                    }
                    
                    Spacer()
                    
                    // Show only safe toggle
                    Toggle(isOn: $showOnlySafe) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                            .foregroundStyle(showOnlySafe ? .green : .secondary)
                    }
                    .toggleStyle(.button)
                    .buttonStyle(.borderless)
                    .help("Show only safe recipes")
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Filter Badge
    
    @ViewBuilder
    private func filterBadge(for mode: RecipeFilterMode) -> some View {
        Button {
            filterMode = mode
        } label: {
            Image(systemName: mode.icon)
                .font(.caption)
                .foregroundStyle(filterMode == mode ? .white : badgeColor(for: mode))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(filterMode == mode ? badgeColor(for: mode) : Color(.systemBackground))
                )
                .overlay(
                    Circle()
                        .strokeBorder(badgeColor(for: mode).opacity(0.3), lineWidth: filterMode == mode ? 0 : 1)
                )
        }
        .buttonStyle(.plain)
        .help(mode.description)
    }
    
    private func badgeColor(for mode: RecipeFilterMode) -> Color {
        switch mode {
        case .none:
            return .gray
        case .allergenFODMAP:
            return .orange
        case .diabetes:
            return .red
        case .nutrition:
            return .green
        case .all:
            return .purple
        }
    }
    
    // MARK: - Allergen Profile Section
    
    private var allergenProfileSection: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.caption)
                    .foregroundStyle(activeProfile != nil ? .orange : .secondary)
                
                if let profile = activeProfile {
                    Text("\(profile.sensitivities.count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(.plain)
        .help(activeProfile != nil ? "Profile: \(activeProfile!.name) (\(activeProfile!.sensitivities.count) sensitivities)" : "No profile selected - tap to choose")
    }
    
    // MARK: - Diabetes Status Section
    
    private var diabetesStatusSection: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 4) {
                Image(systemName: "heart.text.square.fill")
                    .font(.caption)
                    .foregroundStyle(activeProfile?.hasDiabetesConcern == true ? .red : .secondary)
                
                if let profile = activeProfile, profile.hasDiabetesConcern {
                    Text(profile.diabetesStatus.icon)
                        .font(.caption)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(.plain)
        .help(activeProfile?.hasDiabetesConcern == true ? "Diabetes: \(activeProfile!.diabetesStatus.rawValue)" : "No diabetes status - tap to set")
    }
    
    // MARK: - Nutrition Status Section
    
    private var nutritionStatusSection: some View {
        Button(action: onProfileTap) {
            HStack(spacing: 4) {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                if let profile = activeProfile, profile.hasNutritionalGoals {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "exclamationmark.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(.plain)
        .help(activeProfile?.hasNutritionalGoals == true ? "Nutritional goals configured" : "No nutritional goals - tap to set")
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
        case .nutrition:
            if showOnlySafe {
                return "Nutrient-Rich Recipes"
            } else {
                return "Sorted by Nutritional Value"
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
        case .nutrition:
            return .green
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
