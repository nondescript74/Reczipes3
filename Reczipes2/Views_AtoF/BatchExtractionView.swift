//
//  BatchExtractionView.swift
//  Reczipes2
//
//  Created for automated batch recipe extraction UI
//

import SwiftUI
import SwiftData

struct BatchExtractionView: View {
    let links: [SavedLink]
    let apiKey: String
    let onComplete: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel: BatchRecipeExtractorViewModel?
    @State private var showingStopConfirmation = false
    @State private var showingErrorLog = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    contentView(vm: vm)
                } else {
                    ProgressView("Initializing...")
                }
            }
            .navigationTitle("Batch Extract Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel?.isExtracting == true ? "Cancel" : "Done") {
                        if viewModel?.isExtracting == true {
                            showingStopConfirmation = true
                        } else {
                            dismiss()
                            onComplete()
                        }
                    }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = BatchRecipeExtractorViewModel(
                        apiKey: apiKey,
                        modelContext: modelContext
                    )
                }
            }
            .alert("Stop Extraction?", isPresented: $showingStopConfirmation) {
                Button("Continue", role: .cancel) { }
                Button("Stop", role: .destructive) {
                    viewModel?.stop()
                }
            } message: {
                Text("This will stop the batch extraction. Progress will be saved, but unprocessed links will remain.")
            }
            .sheet(isPresented: $showingErrorLog) {
                if let vm = viewModel {
                    errorLogSheet(vm: vm)
                }
            }
        }
    }
    
    // MARK: - Main Content View
    
    private func contentView(vm: BatchRecipeExtractorViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Progress Section
                if vm.isExtracting {
                    progressSection(vm: vm)
                }
                
                // Current Recipe Preview
                if let recipe = vm.currentRecipe {
                    currentRecipePreview(recipe)
                }
                
                // Stats Section
                statsSection(vm: vm)
                
                // Control Buttons
                controlButtonsSection(vm: vm)
                
                // Error Log Button
                if !vm.errorLog.isEmpty {
                    errorLogButton(vm: vm)
                }
            }
            .padding()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Automated Recipe Extraction")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Recipes will be extracted automatically with a 1-minute interval between each extraction")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            // Show batch limit info
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                Text("Maximum 10 recipes per batch")
                    .font(.caption)
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        }
    }
    
    private func progressSection(vm: BatchRecipeExtractorViewModel) -> some View {
        VStack(spacing: 16) {
            // Progress Bar
            ProgressView(
                value: Double(vm.currentProgress),
                total: Double(vm.totalToExtract)
            )
            .progressViewStyle(.linear)
            .tint(.blue)
            
            // Progress Text
            HStack {
                Text("\(vm.currentProgress) of \(vm.totalToExtract)")
                    .font(.headline)
                Spacer()
                Text("\(Int((Double(vm.currentProgress) / Double(vm.totalToExtract)) * 100))%")
                    .font(.headline)
                    .foregroundStyle(.blue)
            }
            
            // Current Status
            if !vm.currentStatus.isEmpty {
                Text(vm.currentStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            
            // Current Link
            if let currentLink = vm.currentLink {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Currently Extracting:", systemImage: "link")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(currentLink.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text(currentLink.url)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func currentRecipePreview(_ recipe: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Recipe Extracted")
                    .font(.headline)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let yield = recipe.yield {
                    HStack {
                        Image(systemName: "person.2")
                            .font(.caption)
                        Text(yield)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    if !recipe.ingredientSections.isEmpty {
                        Label("\(recipe.ingredientSections.count) section(s)", systemImage: "list.bullet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let imageURLs = recipe.imageURLs {
                        Label("\(imageURLs.count) image(s)", systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func statsSection(vm: BatchRecipeExtractorViewModel) -> some View {
        HStack(spacing: 20) {
            BatchStatBadge(
                label: "To Extract",
                value: vm.totalToExtract,
                color: .blue,
                icon: "clock"
            )
            
            BatchStatBadge(
                label: "Success",
                value: vm.successCount,
                color: .green,
                icon: "checkmark.circle"
            )
            
            if vm.failureCount > 0 {
                BatchStatBadge(
                    label: "Failed",
                    value: vm.failureCount,
                    color: .red,
                    icon: "xmark.circle"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func controlButtonsSection(vm: BatchRecipeExtractorViewModel) -> some View {
        VStack(spacing: 12) {
            if !vm.isExtracting {
                // Show count info
                let unprocessedCount = links.filter { !$0.isProcessed }.count
                let willProcess = min(unprocessedCount, 10)
                
                if unprocessedCount > 10 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text("Will extract \(willProcess) of \(unprocessedCount) unprocessed recipes")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                    .padding(.vertical, 8)
                }
                
                // Start Button
                Button {
                    vm.startBatchExtraction(links: links)
                } label: {
                    Label("Start Batch Extraction", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(links.filter { !$0.isProcessed }.isEmpty)
            } else {
                // Pause/Resume Button
                Button {
                    if vm.isPaused {
                        vm.resume()
                    } else {
                        vm.pause()
                    }
                } label: {
                    Label(
                        vm.isPaused ? "Resume" : "Pause",
                        systemImage: vm.isPaused ? "play.fill" : "pause.fill"
                    )
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.isPaused ? Color.green : Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                
                // Stop Button
                Button {
                    showingStopConfirmation = true
                } label: {
                    Label("Stop Extraction", systemImage: "stop.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func errorLogButton(vm: BatchRecipeExtractorViewModel) -> some View {
        Button {
            showingErrorLog = true
        } label: {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text("View Error Log (\(vm.errorLog.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
    
    private func errorLogSheet(vm: BatchRecipeExtractorViewModel) -> some View {
        NavigationStack {
            List {
                ForEach(Array(vm.errorLog.enumerated()), id: \.offset) { _, error in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error.link)
                            .font(.headline)
                        Text(error.error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Extraction Errors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingErrorLog = false
                    }
                }
            }
        }
    }
}

// MARK: - Batch Stat Badge Component

struct BatchStatBadge: View {
    let label: String
    let value: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SavedLink.self, configurations: config)
    let context = ModelContext(container)
    
    // Create sample links
    let link1 = SavedLink(title: "Chocolate Chip Cookies", url: "https://example.com/recipe1")
    let link2 = SavedLink(title: "Banana Bread", url: "https://example.com/recipe2")
    let link3 = SavedLink(title: "Apple Pie", url: "https://example.com/recipe3")
    
    context.insert(link1)
    context.insert(link2)
    context.insert(link3)
    
    return BatchExtractionView(
        links: [link1, link2, link3],
        apiKey: "test-key",
        onComplete: {}
    )
    .modelContainer(container)
}
