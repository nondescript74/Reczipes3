//
//  RecipeImageAssignmentView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI
import SwiftData

struct RecipeImageAssignmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var assignments: [RecipeImageAssignment]
    
    // List of all image names in your Assets catalog
    // Update this array with your actual image names
    @State private var availableImages: [String] = [
        "AmNC",
        "CaPi",
        "CoCh",
        "CuRa",
        "DhCh",
        "DrCa",
        "EgRa",
        "GaMa",
        "GhCb",
        "HiContrast",
        "HoYo",
        "Itc",
        "Kach",
        "KaSM",
        "LaYS",
        "LeCh",
        "Mpio",
        "Sher",
        "VeSo",
        "Vs"
    ]
    
    // All recipes from RecipeCollection (stable UUIDs!)
    private var allRecipes: [RecipeModel] {
        RecipeCollection.shared.allRecipes
    }
    
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Recipe Image Assignments") {
                    ForEach(allRecipes) { recipe in
                        RecipeImageRow(
                            recipe: recipe,
                            currentImageName: assignedImage(for: recipe.id),
                            availableImages: availableImagesForRecipe(recipe.id),
                            onImageSelected: { imageName in
                                assignImage(imageName, to: recipe.id)
                            },
                            onImageRemoved: {
                                removeImage(from: recipe.id)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Assign Recipe Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func assignedImage(for recipeID: UUID) -> String? {
        assignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    private func availableImagesForRecipe(_ recipeID: UUID) -> [String] {
        let assignedImages = Set(assignments.map { $0.imageName })
        let currentImage = assignedImage(for: recipeID)
        
        // Include images that are either unassigned or currently assigned to this recipe
        return availableImages.filter { imageName in
            !assignedImages.contains(imageName) || imageName == currentImage
        }
    }
    
    private func assignImage(_ imageName: String, to recipeID: UUID) {
        // Remove existing assignment if any
        if let existing = assignments.first(where: { $0.recipeID == recipeID }) {
            modelContext.delete(existing)
        }
        
        // Create new assignment
        let assignment = RecipeImageAssignment(recipeID: recipeID, imageName: imageName)
        modelContext.insert(assignment)
    }
    
    private func removeImage(from recipeID: UUID) {
        if let existing = assignments.first(where: { $0.recipeID == recipeID }) {
            modelContext.delete(existing)
        }
    }
}

// MARK: - Recipe Image Row

struct RecipeImageRow: View {
    let recipe: RecipeModel
    let currentImageName: String?
    let availableImages: [String]
    let onImageSelected: (String) -> Void
    let onImageRemoved: () -> Void
    
    @State private var showingImagePicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe thumbnail or placeholder
            if let imageName = currentImageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                
                if let imageName = currentImageName {
                    Text(imageName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No image assigned")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if currentImageName != nil {
                    Button(action: { onImageRemoved() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: { showingImagePicker = true }) {
                    Image(systemName: currentImageName == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .disabled(availableImages.isEmpty && currentImageName == nil)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerSheet(
                recipe: recipe,
                availableImages: availableImages,
                currentImageName: currentImageName,
                onImageSelected: onImageSelected
            )
        }
    }
}

// MARK: - Image Picker Sheet

struct ImagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let recipe: RecipeModel
    let availableImages: [String]
    let currentImageName: String?
    let onImageSelected: (String) -> Void
    
    @State private var searchText = ""
    
    private var filteredImages: [String] {
        if searchText.isEmpty {
            return availableImages
        } else {
            return availableImages.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredImages, id: \.self) { imageName in
                        Button {
                            onImageSelected(imageName)
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                currentImageName == imageName ? Color.blue : Color.gray.opacity(0.3),
                                                lineWidth: currentImageName == imageName ? 3 : 1
                                            )
                                    )
                                    .shadow(radius: 2)
                                
                                Text(imageName)
                                    .font(.caption2)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.primary)
                            }
                            .frame(width: 100)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Image")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RecipeImageAssignmentView()
        .modelContainer(for: [RecipeImageAssignment.self], inMemory: true)
}
