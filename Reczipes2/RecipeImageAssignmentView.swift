//
//  RecipeImageAssignmentView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI
import SwiftData
import Photos

struct RecipeImageAssignmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var assignments: [RecipeImageAssignment]
    @Query private var savedRecipes: [Recipe]
    
    @StateObject private var photoLibrary = PhotoLibraryManager()
    
    // All recipes from RecipeCollection (stable UUIDs!)
    private var allRecipes: [RecipeModel] {
        RecipeCollection.shared.allRecipes(savedRecipes: savedRecipes)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if allRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes Yet",
                        systemImage: "book.closed",
                        description: Text("Extract recipes first before assigning images")
                    )
                } else {
                    switch photoLibrary.authorizationStatus {
                    case .notDetermined:
                        permissionPromptView
                    case .restricted, .denied:
                        permissionDeniedView
                    case .authorized, .limited:
                        if photoLibrary.isLoading {
                            loadingView
                        } else {
                            recipeListView
                        }
                    @unknown default:
                        permissionPromptView
                    }
                }
            }
            .navigationTitle("Recipe Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Recipe Images")
                            .font(.headline)
                        Text("Change or assign photos")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .task {
                // Load photos if we already have permission
                if photoLibrary.authorizationStatus == .authorized || photoLibrary.authorizationStatus == .limited {
                    await photoLibrary.loadPhotos()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var permissionPromptView: some View {
        ContentUnavailableView {
            Label("Photo Library Access", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Allow access to your photo library to assign images to recipes")
        } actions: {
            Button("Grant Access") {
                Task {
                    await photoLibrary.requestPermission()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Photo Library Access Denied", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Please enable photo library access in Settings to assign images to recipes")
        } actions: {
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: settingsUrl)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading photos...")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recipeListView: some View {
        List {
            if photoLibrary.photoAssets.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Photos Found",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("Your photo library appears to be empty or the app doesn't have access to any photos.")
                    )
                } footer: {
                    if photoLibrary.authorizationStatus == .limited {
                        Text("You've granted limited photo access. To see more photos, go to Settings and change photo access to 'Full Access'.")
                    }
                }
            } else {
                Section {
                    ForEach(allRecipes) { recipe in
                        RecipePhotoRow(
                            recipe: recipe,
                            currentImageName: assignedImage(for: recipe.id),
                            photoLibrary: photoLibrary,
                            onPhotoSelected: { asset in
                                Task {
                                    await assignPhoto(asset, to: recipe.id)
                                }
                            },
                            onImageRemoved: {
                                removeImage(from: recipe.id)
                            }
                        )
                    }
                } header: {
                    Text("Your Recipes")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(photoLibrary.photoAssets.count) photo(s) available in library")
                        Text("Tip: Images are automatically saved when extracting recipes. You can change them here anytime.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func assignedImage(for recipeID: UUID) -> String? {
        assignments.first { $0.recipeID == recipeID }?.imageName
    }
    
    private func assignPhoto(_ asset: PHAsset, to recipeID: UUID) async {
        // Save the photo to documents directory and get a unique filename
        guard let image = await photoLibrary.loadImage(for: asset, targetSize: PHImageManagerMaximumSize) else {
            print("❌ Failed to load image")
            return
        }
        
        // Generate a unique filename
        let filename = "recipe_\(recipeID.uuidString).jpg"
        
        // Save to documents directory
        if let savedPath = saveImageToDocuments(image, filename: filename) {
            print("✅ Saved image to: \(savedPath)")
            
            // Remove existing assignment if any
            if let existing = assignments.first(where: { $0.recipeID == recipeID }) {
                // Delete old image file if it exists
                deleteImageFromDocuments(existing.imageName)
                modelContext.delete(existing)
            }
            
            // Create new assignment
            let assignment = RecipeImageAssignment(recipeID: recipeID, imageName: filename)
            modelContext.insert(assignment)
            
            try? modelContext.save()
        }
    }
    
    private func removeImage(from recipeID: UUID) {
        if let existing = assignments.first(where: { $0.recipeID == recipeID }) {
            // Delete the image file
            deleteImageFromDocuments(existing.imageName)
            // Remove the assignment
            modelContext.delete(existing)
        }
    }
    
    // MARK: - File Management
    
    private func saveImageToDocuments(_ image: UIImage, filename: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("❌ Error saving image: \(error)")
            return nil
        }
    }
    
    private func deleteImageFromDocuments(_ filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Recipe Photo Row

struct RecipePhotoRow: View {
    let recipe: RecipeModel
    let currentImageName: String?
    let photoLibrary: PhotoLibraryManager
    let onPhotoSelected: (PHAsset) -> Void
    let onImageRemoved: () -> Void
    
    @State private var showingPhotoPicker = false
    @State private var thumbnailImage: UIImage?
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe thumbnail or placeholder
            Group {
                if let thumbnail = thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else if let imageName = currentImageName,
                          let image = loadImageFromDocuments(imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Recipe info
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                
                if currentImageName != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text("Image assigned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                
                Button(action: { showingPhotoPicker = true }) {
                    Image(systemName: currentImageName == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerSheet(
                recipe: recipe,
                photoLibrary: photoLibrary,
                onPhotoSelected: onPhotoSelected
            )
        }
    }
    
    private func loadImageFromDocuments(_ filename: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return UIImage(data: data)
    }
}

// MARK: - Photo Picker Sheet

struct PhotoPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let recipe: RecipeModel
    let photoLibrary: PhotoLibraryManager
    let onPhotoSelected: (PHAsset) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photoLibrary.photoAssets, id: \.localIdentifier) { asset in
                        Button {
                            onPhotoSelected(asset)
                            dismiss()
                        } label: {
                            PhotoThumbnailView(
                                asset: asset,
                                photoLibrary: photoLibrary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Photo")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Photo Thumbnail View

struct PhotoThumbnailView: View {
    let asset: PHAsset
    let photoLibrary: PhotoLibraryManager
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .task {
            thumbnail = await photoLibrary.loadThumbnail(for: asset)
        }
    }
}

#Preview {
    RecipeImageAssignmentView()
        .modelContainer(for: [RecipeImageAssignment.self, Recipe.self], inMemory: true)
}
