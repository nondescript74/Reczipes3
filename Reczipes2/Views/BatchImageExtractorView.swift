//
//  BatchImageExtractorView.swift
//  Reczipes2
//
//  Created for batch recipe extraction from Photos library
//

import SwiftUI
import SwiftData
import Photos
import OSLog
import UniformTypeIdentifiers

/// UI for batch extracting recipes from tagged Photos library images
struct BatchImageExtractorView: View {
    @StateObject private var viewModel: BatchImageExtractorViewModel
    @StateObject private var photoManager = PhotoLibraryManager()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingImagePicker = false
    @State private var showingDocumentPicker = false
    @State private var selectedAssets: [PHAsset] = []
    @State private var selectedImages: [UIImage] = [] // For iCloud Drive images
    @State private var showingCropOptions = false
    @State private var showingCompletionAlert = false
    @State private var shouldCropImages = false
    @State private var showingHelp = false
    @State private var showingSourcePicker = false
    
    init(apiKey: String, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: BatchImageExtractorViewModel(
            apiKey: apiKey,
            modelContext: modelContext
        ))
        logInfo("BatchImageExtractorView initialized", category: "ui")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if selectedAssets.isEmpty && selectedImages.isEmpty {
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
                            logInfo("User stopped extraction and closed view", category: "extraction")
                            viewModel.stop()
                        } else {
                            logInfo("User closed BatchImageExtractorView", category: "ui")
                        }
                        dismiss()
                    }
                }
                
                
                // ADD THIS NEW ITEM:
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        logDebug("User tapped help button for batch extraction", category: "ui")
                        showingHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
                
                if !selectedAssets.isEmpty && !viewModel.isExtracting {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                logInfo("User tapped 'Add More from Photos' to add additional images", category: "ui")
                                showingImagePicker = true
                            } label: {
                                Label("From Photos", systemImage: "photo.on.rectangle")
                            }
                            
                            Button {
                                logInfo("User tapped 'Add More from Files' to add additional images", category: "ui")
                                showingDocumentPicker = true
                            } label: {
                                Label("From Files (iCloud Drive)", systemImage: "folder")
                            }
                        } label: {
                            Label("Add More", systemImage: "plus")
                        }
                    }
                }
                
                if !selectedImages.isEmpty && !viewModel.isExtracting {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                logInfo("User tapped 'Add More from Photos' to add additional images", category: "ui")
                                showingImagePicker = true
                            } label: {
                                Label("From Photos", systemImage: "photo.on.rectangle")
                            }
                            
                            Button {
                                logInfo("User tapped 'Add More from Files' to add additional images", category: "ui")
                                showingDocumentPicker = true
                            } label: {
                                Label("From Files (iCloud Drive)", systemImage: "folder")
                            }
                        } label: {
                            Label("Add More", systemImage: "plus")
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
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPickerView(selectedImages: $selectedImages)
            }
            .sheet(isPresented: $showingSourcePicker) {
                sourceSelectionSheet
            }
            .sheet(isPresented: $showingCropOptions) {
                cropOptionsSheet
            }
            
            .sheet(isPresented: $showingHelp) {
                HelpDetailView(topic: AppHelp.batchImageExtraction)
            }
            .alert("Batch Extraction Complete", isPresented: $showingCompletionAlert) {
                Button("View Recipes") {
                    logInfo("User chose to view recipes after batch extraction", category: "ui")
                    dismiss()
                }
                Button("OK", role: .cancel) {
                    logInfo("User dismissed completion alert and reset batch extractor", category: "ui")
                    viewModel.reset()
                    selectedAssets = []
                    selectedImages = []
                }
            } message: {
                Text("Extracted \(viewModel.successCount) recipe\(viewModel.successCount == 1 ? "" : "s") successfully\(viewModel.failureCount > 0 ? " with \(viewModel.failureCount) failure\(viewModel.failureCount == 1 ? "" : "s")" : "").")
            }
            .onAppear {
                logDebug("BatchImageExtractorView appeared", category: "ui")
                Task {
                    await photoManager.requestPermission()
                    logInfo("Photo library permission requested", category: "image")
                }
            }
            .onChange(of: viewModel.isExtracting) { _, isExtracting in
                if !isExtracting && viewModel.currentProgress > 0 {
                    logInfo("Batch extraction completed. Success: \(viewModel.successCount), Failures: \(viewModel.failureCount)", category: "extraction")
                    showingCompletionAlert = true
                }
            }
            .onChange(of: selectedImages) { _, newImages in
                if !newImages.isEmpty {
                    logInfo("Loaded \(newImages.count) images from iCloud Drive/Files", category: "ui")
                }
            }
            .fullScreenCover(isPresented: $viewModel.showingCropForBatch) {
                if let image = viewModel.imageToCropInBatch {
                    ImageCropView(
                        image: image,
                        onCrop: { croppedImage in
                            logDebug("User completed cropping image in batch workflow", category: "image")
                            viewModel.handleCroppedImage(croppedImage)
                        },
                        onCancel: {
                            logDebug("User cancelled crop view in batch workflow", category: "image")
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
            
            Text("Choose multiple recipe images from Photos or Files to extract recipes in batch")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    logInfo("User tapped 'Select from Photos' in empty state", category: "ui")
                    showingImagePicker = true
                } label: {
                    Label("Select from Photos", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                
                Button {
                    logInfo("User tapped 'Select from Files' in empty state", category: "ui")
                    showingDocumentPicker = true
                } label: {
                    Label("Select from Files (iCloud Drive)", systemImage: "folder.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
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
                    let totalCount = selectedAssets.count + selectedImages.count
                    Text("\(totalCount) image\(totalCount == 1 ? "" : "s") ready for extraction")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !selectedAssets.isEmpty && !selectedImages.isEmpty {
                        Text("\(selectedAssets.count) from Photos • \(selectedImages.count) from Files")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if !selectedAssets.isEmpty {
                        Text("From Photos Library")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if !selectedImages.isEmpty {
                        Text("From Files/iCloud Drive")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button {
                        logInfo("User tapped add more from Photos", category: "ui")
                        showingImagePicker = true
                    } label: {
                        Label("From Photos", systemImage: "photo.on.rectangle")
                    }
                    
                    Button {
                        logInfo("User tapped add more from Files", category: "ui")
                        showingDocumentPicker = true
                    } label: {
                        Label("From Files", systemImage: "folder")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
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
            .onChange(of: shouldCropImages) { oldValue, newValue in
                logDebug("User toggled crop option: \(newValue)", category: "ui")
            }
            
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
            let totalCount = selectedAssets.count + selectedImages.count
            logInfo("Starting batch extraction with \(totalCount) images (\(selectedAssets.count) from Photos, \(selectedImages.count) from Files), cropping: \(shouldCropImages)", category: "extraction")
            
            if shouldCropImages {
                // Start with cropping workflow
                if !selectedImages.isEmpty {
                    // Extract from UIImages (Files/iCloud Drive)
                    viewModel.startBatchExtractionFromImages(
                        images: selectedImages,
                        shouldCrop: true
                    )
                } else {
                    // Extract from PHAssets (Photos)
                    viewModel.startBatchExtraction(
                        assets: selectedAssets,
                        photoManager: photoManager,
                        shouldCrop: true
                    )
                }
            } else {
                // Start without cropping
                if !selectedImages.isEmpty {
                    // Extract from UIImages (Files/iCloud Drive)
                    viewModel.startBatchExtractionFromImages(
                        images: selectedImages,
                        shouldCrop: false
                    )
                } else {
                    // Extract from PHAssets (Photos)
                    viewModel.startBatchExtraction(
                        assets: selectedAssets,
                        photoManager: photoManager,
                        shouldCrop: false
                    )
                }
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
                // First show PHAssets from Photos
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
                
                // Then show UIImages from Files/iCloud Drive
                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                    SelectedImageThumbnail(
                        image: image,
                        index: selectedAssets.count + index,
                        onRemove: {
                            selectedImages.remove(at: index)
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
                    logDebug("User chose to skip cropping for current image", category: "image")
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
                    logDebug("User chose to crop current image", category: "image")
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
                    logInfo("User resumed batch extraction", category: "extraction")
                    viewModel.resume()
                } else {
                    logInfo("User paused batch extraction", category: "extraction")
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
                logWarning("User stopped batch extraction at \(viewModel.currentProgress)/\(viewModel.totalToExtract)", category: "extraction")
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
    
    private var sourceSelectionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Select Image Source")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Choose where to select your recipe images from")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Button {
                        showingSourcePicker = false
                        showingImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            VStack(alignment: .leading) {
                                Text("Photos Library")
                                    .font(.headline)
                                Text("Select from your device's photos")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        showingSourcePicker = false
                        showingDocumentPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            VStack(alignment: .leading) {
                                Text("Files (iCloud Drive)")
                                    .font(.headline)
                                Text("Select from Files app and iCloud Drive")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationTitle("Select Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSourcePicker = false
                    }
                }
            }
        }
    }
    
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
                        logInfo("User chose to crop each image in batch", category: "extraction")
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
                        logInfo("User chose to skip cropping for batch extraction", category: "extraction")
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

// MARK: - Document Picker for iCloud Drive

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.image], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            logInfo("User selected \(urls.count) images from Files/iCloud Drive", category: "ui")
            
            var loadedImages: [UIImage] = []
            
            for url in urls {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    logWarning("Failed to access security-scoped resource: \(url)", category: "storage")
                    continue
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                // Load image data
                do {
                    let imageData = try Data(contentsOf: url)
                    if let image = UIImage(data: imageData) {
                        loadedImages.append(image)
                        logDebug("Loaded image from \(url.lastPathComponent)", category: "image")
                    } else {
                        logWarning("Failed to create UIImage from \(url.lastPathComponent)", category: "image")
                    }
                } catch {
                    logError("Failed to load image from \(url.lastPathComponent): \(error)", category: "storage")
                }
            }
            
            DispatchQueue.main.async {
                self.parent.selectedImages.append(contentsOf: loadedImages)
                logInfo("Successfully loaded \(loadedImages.count) images from Files", category: "image")
            }
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            logDebug("User cancelled document picker", category: "ui")
        }
    }
}

// MARK: - Selected Image Thumbnail (for Files/iCloud Drive images)

struct SelectedImageThumbnail: View {
    let image: UIImage
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(8)
            
            // Remove button
            Button {
                logDebug("User removed iCloud Drive image \(index + 1) from selection", category: "ui")
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
                    HStack(spacing: 2) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 8))
                        Text("\(index + 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(4)
                    Spacer()
                }
            }
            .padding(4)
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
                logDebug("User removed image \(index + 1) from selection", category: "ui")
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
                        logInfo("User added \(tempSelectedAssets.count) images to batch selection (total: \(selectedAssets.count + tempSelectedAssets.count))", category: "ui")
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
            logDebug("Deselected asset in photo picker", category: "ui")
        } else {
            tempSelectedAssets.append(asset)
            logDebug("Selected asset in photo picker (temp count: \(tempSelectedAssets.count))", category: "ui")
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
