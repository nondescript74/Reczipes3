//
//  BatchImageExtractorView.swift
//  Reczipes2
//
//  Created for batch recipe extraction from Photos library
//

import SwiftUI
import SwiftData
import Photos

/// UI for batch extracting recipes from tagged Photos library images
struct BatchImageExtractorView: View {
    @StateObject private var viewModel: BatchImageExtractorViewModel
    @StateObject private var photoManager = PhotoLibraryManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingImagePicker = false
    @State private var selectedAssets: [PHAsset] = []
    @State private var showingCropOptions = false
    @State private var showingCompletionAlert = false
    @State private var shouldCropImages = false
    @State private var showingHelp = false
    
    init(apiKey: String, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: BatchImageExtractorViewModel(
            apiKey: apiKey,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if selectedAssets.isEmpty {
                    emptyStateView
                } else if viewModel.isExtracting {
                    extractionProgressView
                } else {
                    imageSelectionView
                }
            }
            .navigationTitle("Batch Image Extract")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if viewModel.isExtracting {
                            viewModel.stop()
                        }
                        dismiss()
                    }
                }
                
                
                // ADD THIS NEW ITEM:
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
                
                if !selectedAssets.isEmpty && !viewModel.isExtracting {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add More") {
                            showingImagePicker = true
                        }
                    }
                }
                
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotosPickerSheet(
                    selectedAssets: $selectedAssets,
                    photoManager: photoManager
                )
            }
            .sheet(isPresented: $showingCropOptions) {
                cropOptionsSheet
            }
            
            .sheet(isPresented: $showingHelp) {
                HelpDetailView(topic: AppHelp.batchImageExtraction)
            }
            .alert("Batch Extraction Complete", isPresented: $showingCompletionAlert) {
                Button("View Recipes") {
                    dismiss()
                }
                Button("OK", role: .cancel) {
                    viewModel.reset()
                    selectedAssets = []
                }
            } message: {
                Text("Extracted \(viewModel.successCount) recipe\(viewModel.successCount == 1 ? "" : "s") successfully\(viewModel.failureCount > 0 ? " with \(viewModel.failureCount) failure\(viewModel.failureCount == 1 ? "" : "s")" : "").")
            }
            .onAppear {
                Task {
                    await photoManager.requestPermission()
                }
            }
            .onChange(of: viewModel.isExtracting) { _, isExtracting in
                if !isExtracting && viewModel.currentProgress > 0 {
                    showingCompletionAlert = true
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingCropForBatch) {
                if let image = viewModel.imageToCropInBatch {
                    ImageCropView(
                        image: image,
                        onCrop: { croppedImage in
                            viewModel.handleCroppedImage(croppedImage)
                        },
                        onCancel: {
                            viewModel.handleCroppedImage(nil)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Select Images to Extract")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose multiple recipe images from your Photos library to extract recipes in batch")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showingImagePicker = true
            } label: {
                Label("Select Photos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Image Selection View
    
    private var imageSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Selection summary
                selectionSummaryCard
                
                // Crop option prompt
                cropOptionCard
                
                // Start button
                startExtractionButton
                
                // Selected images grid
                selectedImagesGrid
            }
            .padding()
        }
    }
    
    private var selectionSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "photo.stack.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Images Selected")
                        .font(.headline)
                    Text("\(selectedAssets.count) image\(selectedAssets.count == 1 ? "" : "s") ready for extraction")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingImagePicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var cropOptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: shouldCropImages ? "crop.rotate" : "rectangle.dashed")
                    .foregroundColor(shouldCropImages ? .green : .orange)
                
                Text("Cropping Options")
                    .font(.headline)
            }
            
            Toggle(isOn: $shouldCropImages) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crop each image before extraction")
                        .font(.subheadline)
                    Text("You'll be able to crop each image individually")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .tint(.blue)
            
            if !shouldCropImages {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Images will be processed as-is up to 10 at a time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var startExtractionButton: some View {
        Button {
            if shouldCropImages {
                // Start with cropping workflow
                viewModel.startBatchExtraction(
                    assets: selectedAssets,
                    photoManager: photoManager,
                    shouldCrop: true
                )
            } else {
                // Start without cropping
                viewModel.startBatchExtraction(
                    assets: selectedAssets,
                    photoManager: photoManager,
                    shouldCrop: false
                )
            }
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text(shouldCropImages ? "Start with Cropping" : "Start Extraction")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var selectedImagesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Images")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(selectedAssets.enumerated()), id: \.offset) { index, asset in
                    SelectedAssetThumbnail(
                        asset: asset,
                        index: index,
                        photoManager: photoManager,
                        onRemove: {
                            selectedAssets.remove(at: index)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    // MARK: - Extraction Progress View
    
    private var extractionProgressView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress overview
                progressOverviewCard
                
                // Current extraction
                if viewModel.currentImage != nil {
                    currentImageCard
                }
                
                // Control buttons
                if viewModel.isWaitingForCrop {
                    cropDecisionButtons
                } else {
                    controlButtons
                }
                
                // Remaining queue
                remainingQueueSection
                
                // Error log
                if !viewModel.errorLog.isEmpty {
                    errorLogSection
                }
            }
            .padding()
        }
    }
    
    private var progressOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extracting Recipes")
                        .font(.headline)
                    Text(viewModel.currentStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress bar
            ProgressView(value: Double(viewModel.currentProgress), total: Double(viewModel.totalToExtract))
                .progressViewStyle(.linear)
                .tint(.purple)
            
            // Stats
            HStack(spacing: 20) {
                statItem(
                    label: "Progress",
                    value: "\(viewModel.currentProgress)/\(viewModel.totalToExtract)",
                    color: .blue
                )
                
                statItem(
                    label: "Success",
                    value: "\(viewModel.successCount)",
                    color: .green
                )
                
                if viewModel.failureCount > 0 {
                    statItem(
                        label: "Failed",
                        value: "\(viewModel.failureCount)",
                        color: .red
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var currentImageCard: some View {
        VStack(spacing: 12) {
            if let image = viewModel.currentImage {
                // Image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                
                if let recipe = viewModel.currentRecipe {
                    // Recipe preview
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Extracted: \(recipe.title)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        if !recipe.ingredientSections.isEmpty {
                            Text("✓ \(recipe.ingredientSections.count) ingredient section\(recipe.ingredientSections.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if !recipe.instructionSections.isEmpty {
                            Text("✓ \(recipe.instructionSections.count) instruction section\(recipe.instructionSections.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var cropDecisionButtons: some View {
        VStack(spacing: 12) {
            Text("Would you like to crop this image?")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button {
                    viewModel.skipCropping()
                } label: {
                    HStack {
                        Image(systemName: "arrow.forward")
                        Text("Skip")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.showCropping()
                } label: {
                    HStack {
                        Image(systemName: "crop.rotate")
                        Text("Crop")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var controlButtons: some View {
        HStack(spacing: 12) {
            Button {
                if viewModel.isPaused {
                    viewModel.resume()
                } else {
                    viewModel.pause()
                }
            } label: {
                HStack {
                    Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    Text(viewModel.isPaused ? "Resume" : "Pause")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isPaused ? Color.green : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button {
                viewModel.stop()
            } label: {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var remainingQueueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remaining Queue (\(viewModel.remainingCount))")
                .font(.headline)
            
            if viewModel.remainingCount == 0 {
                Text("All images processed!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Text("Next \(min(10, viewModel.remainingCount)) images will be processed")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<min(10, viewModel.remainingAssets.count), id: \.self) { index in
                            if index < viewModel.remainingAssets.count {
                                QueuedAssetThumbnail(
                                    asset: viewModel.remainingAssets[index],
                                    index: index + viewModel.currentProgress,
                                    photoManager: photoManager
                                )
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var errorLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Errors (\(viewModel.errorLog.count))")
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.errorLog.indices, id: \.self) { index in
                    let error = viewModel.errorLog[index]
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image \(error.imageIndex + 1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(error.error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    // MARK: - Crop Options Sheet
    
    private var cropOptionsSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "crop.rotate")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Crop Before Extraction?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You can crop each image individually before extraction, or skip cropping to process images faster.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button {
                        shouldCropImages = true
                        showingCropOptions = false
                        viewModel.startBatchExtraction(
                            assets: selectedAssets,
                            photoManager: photoManager,
                            shouldCrop: true
                        )
                    } label: {
                        HStack {
                            Image(systemName: "crop.rotate")
                            Text("Crop Each Image")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        shouldCropImages = false
                        showingCropOptions = false
                        viewModel.startBatchExtraction(
                            assets: selectedAssets,
                            photoManager: photoManager,
                            shouldCrop: false
                        )
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Skip Cropping (Faster)")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Cropping Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCropOptions = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SelectedAssetThumbnail: View {
    let asset: PHAsset
    let index: Int
    let photoManager: PhotoLibraryManager
    let onRemove: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(ProgressView())
            }
            
            // Remove button
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                    )
            }
            .offset(x: 8, y: -8)
            
            // Index badge
            VStack {
                Spacer()
                HStack {
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(4)
                    Spacer()
                }
            }
            .padding(4)
        }
        .task {
            thumbnail = await photoManager.loadThumbnail(for: asset)
        }
    }
}

struct QueuedAssetThumbnail: View {
    let asset: PHAsset
    let index: Int
    let photoManager: PhotoLibraryManager
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        VStack(spacing: 4) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(ProgressView())
            }
            
            Text("\(index + 1)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .task {
            thumbnail = await photoManager.loadThumbnail(for: asset)
        }
    }
}

struct PhotosPickerSheet: View {
    @Binding var selectedAssets: [PHAsset]
    @ObservedObject var photoManager: PhotoLibraryManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempSelectedAssets: [PHAsset] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ], spacing: 2) {
                    ForEach(photoManager.photoAssets, id: \.localIdentifier) { asset in
                        PhotoAssetCell(
                            asset: asset,
                            isSelected: tempSelectedAssets.contains(where: { $0.localIdentifier == asset.localIdentifier }),
                            photoManager: photoManager,
                            onTap: {
                                toggleSelection(asset)
                            }
                        )
                    }
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(tempSelectedAssets.count))") {
                        selectedAssets.append(contentsOf: tempSelectedAssets)
                        dismiss()
                    }
                    .disabled(tempSelectedAssets.isEmpty)
                }
            }
        }
        .onAppear {
            tempSelectedAssets = []
        }
    }
    
    private func toggleSelection(_ asset: PHAsset) {
        if let index = tempSelectedAssets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) {
            tempSelectedAssets.remove(at: index)
        } else {
            tempSelectedAssets.append(asset)
        }
    }
}

struct PhotoAssetCell: View {
    let asset: PHAsset
    let isSelected: Bool
    let photoManager: PhotoLibraryManager
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(ProgressView())
                }
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(8)
                }
            }
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(.plain)
        .task {
            thumbnail = await photoManager.loadThumbnail(for: asset)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BatchImageExtractorView(
            apiKey: "test-api-key",
            modelContext: ModelContext(try! ModelContainer(for: Recipe.self))
        )
    }
}
