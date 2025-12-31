//
//  RecipeDetailView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    let recipe: RecipeModel
    let isSaved: Bool
    let onSave: () -> Void
    let previewImage: UIImage? // Optional image for unsaved recipes being previewed
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppStateManager
    
    @Query private var savedRecipes: [Recipe]
    @Query private var allergenProfiles: [UserAllergenProfile]
    
    @StateObject private var fodmapSettings = UserFODMAPSettings.shared
    @StateObject private var diabeticSettings = UserDiabeticSettings.shared
    
    @State private var showingEditor = false
    @State private var showingRemindersAlert = false
    @State private var remindersAlertMessage = ""
    @State private var isExportingToReminders = false
    @State private var showingAllergenDetail = false
    @State private var showingFODMAPSubstitutions = true // Default to showing substitutions
    @State private var showingFODMAPGuide = false
    @State private var showingAddTip = false
    @State private var newTipText = ""
    @State private var pendingTips: [RecipeNote] = [] // Tips to be saved with the recipe
    
    // Diabetic analysis
    @State private var diabeticInfo: DiabeticInfo?
    @State private var isLoadingDiabeticInfo = false
    @State private var analysisProgress: Double = 0.0
    @State private var showPendingAnalysisAlert = false
    
    private let remindersService = RemindersService()
    
    // FODMAP analysis
    private var fodmapAnalysis: RecipeFODMAPSubstitutions {
        FODMAPSubstitutionDatabase.shared.analyzeRecipe(recipe)
    }
    
    init(recipe: RecipeModel, 
         isSaved: Bool, 
         onSave: @escaping () -> Void,
         previewImage: UIImage? = nil) {
        self.recipe = recipe
        self.isSaved = isSaved
        self.onSave = onSave
        self.previewImage = previewImage
    }
    
    // Get the saved Recipe entity for editing
    private var savedRecipe: Recipe? {
        savedRecipes.first { $0.id == recipe.id }
    }
    
    // Active allergen profile
    private var activeProfile: UserAllergenProfile? {
        allergenProfiles.first { $0.isActive }
    }
    
    // Allergen score for this recipe
    private var allergenScore: RecipeAllergenScore? {
        guard let profile = activeProfile else { return nil }
        return AllergenAnalyzer.shared.analyzeRecipe(recipe, profile: profile)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recipe Image (if available)
                // For unsaved recipes in preview, show the previewImage
                // For saved recipes, use the imageName from the recipe model
                if let previewImage = previewImage {
                    // Show the temporary preview image (for extracted recipes not yet saved)
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                } else if let imageName = recipe.imageName {
                    // Get all image names (main + additional + imageURLs)
                    let allImageNames = getAllImageNames(for: recipe)
                    
                    if allImageNames.count > 1 {
                        // Show scrollable gallery for multiple images
                        TabView {
                            ForEach(allImageNames, id: \.self) { imageNameItem in
                                RecipeImageView(
                                    imageName: imageNameItem,
                                    size: nil,
                                    aspectRatio: .fit,
                                    cornerRadius: 16
                                )
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: 200)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                .padding(.horizontal)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 220) // Slightly taller to accommodate page indicator
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                    } else {
                        // Show single image (saved recipes)
                        RecipeImageView(
                            imageName: imageName,
                            size: nil,  // No fixed size - let it adapt
                            aspectRatio: .fit,
                            cornerRadius: 16
                        )
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 200)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                    }
                }
                
                // Header Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if let headerNotes = recipe.headerNotes {
                                Text(headerNotes)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 8) {
                            // Show Save/Update button based on state
                            if !isSaved {
                                // Unsaved recipe - show Save button
                                Button(action: { 
                                    saveRecipeWithTips()
                                }) {
                                    Label("Save Recipe", systemImage: "plus.circle.fill")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            } else if !pendingTips.isEmpty {
                                // Saved recipe with pending tips - show Update button
                                Button(action: { 
                                    savePendingTipsToExistingRecipe()
                                }) {
                                    Label("Save Tips", systemImage: "arrow.down.circle.fill")
                                        .font(.headline)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            } else {
                                // Saved recipe with no pending tips - show Saved badge
                                Label("Saved", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .clipShape(Capsule())
                            }
                            
                            // Show badge if there are pending tips
                            if !pendingTips.isEmpty {
                                Text("\(pendingTips.count) tip\(pendingTips.count == 1 ? "" : "s") to save")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Show diabetic badge if diabetic mode is enabled or profile has diabetes concern
                            if diabeticSettings.isDiabeticEnabled || (activeProfile?.hasDiabetesConcern ?? false) {
                                RecipeDiabeticBadge.full(
                                    info: diabeticInfo,
                                    isLoading: isLoadingDiabeticInfo,
                                    progress: analysisProgress
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    if let yield = recipe.yield {
                        HStack {
                            Label(yield, systemImage: "chart.bar.doc.horizontal")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Allergen Information Section (if profile is active)
                if let score = allergenScore, let profile = activeProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Allergen Analysis", systemImage: "allergens")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            RecipeAllergenBadge(score: score)
                        }
                        
                        Text("Based on \(profile.name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if !score.isSafe {
                            Button {
                                showingAllergenDetail = true
                            } label: {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                    Text("View Detailed Analysis")
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.1))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
                
                // FODMAP Substitutions Section (if there are any high FODMAP ingredients)
                if fodmapSettings.isFODMAPEnabled && fodmapAnalysis.hasSubstitutions {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("FODMAP Friendly Options", systemImage: "leaf.circle.fill")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    showingFODMAPSubstitutions.toggle()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(showingFODMAPSubstitutions ? "Hide" : "Show")
                                        .font(.subheadline)
                                    Image(systemName: showingFODMAPSubstitutions ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundStyle(.blue)
                            }
                        }
                        
                        if showingFODMAPSubstitutions {
                            FODMAPSubstitutionSection(analysis: fodmapAnalysis)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
                
                // Diabetic-Friendly Analysis Section
                // Show if diabetic mode is enabled OR if active profile has diabetes concern
                if diabeticSettings.isDiabeticEnabled || (activeProfile?.hasDiabetesConcern ?? false) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Diabetic-Friendly Analysis", systemImage: "heart.text.square")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.red)
                            
                            Spacer()
                            
                            // Show diabetes status badge if from profile
                            if let profile = activeProfile, profile.hasDiabetesConcern {
                                HStack(spacing: 4) {
                                    Text(profile.diabetesStatus.icon)
                                    Text(profile.diabetesStatus.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                            }
                        }
                        
                        // Show profile note if analysis is triggered by profile diabetes status
                        if let profile = activeProfile, profile.hasDiabetesConcern {
                            Text("Analysis based on \(profile.name) - \(profile.diabetesStatus.description)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let info = diabeticInfo {
                            DiabeticInfoView(info: info)
                        } else if isLoadingDiabeticInfo {
                            VStack(spacing: 12) {
                                ProgressView("Analyzing recipe...", value: analysisProgress)
                                    .progressViewStyle(.linear)
                                    .tint(.red)
                                
                                Text("\(Int(analysisProgress * 100))% complete")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            Button {
                                Task {
                                    await loadDiabeticInfo()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "waveform.path.ecg")
                                    Text("Analyze for Diabetic-Friendly Info")
                                }
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
                
                // Ingredients Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Ingredients", systemImage: "list.bullet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(recipe.ingredientSections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            if let title = section.title {
                                Text(title)
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                    .padding(.top, 8)
                            }
                            
                            ForEach(section.ingredients) { ingredient in
                                // Check if this ingredient has a FODMAP substitution
                                let substitution = fodmapSettings.isFODMAPEnabled && fodmapSettings.showInlineIndicators
                                    ? FODMAPSubstitutionDatabase.shared.getSubstitutions(for: ingredient.name)
                                    : nil
                                
                                IngredientRowWithFODMAP(
                                    ingredient: ingredient,
                                    substitution: substitution
                                )
                            }
                            
                            if let transitionNote = section.transitionNote {
                                Text(transitionNote)
                                    .font(.subheadline)
                                    .italic()
                                    .foregroundStyle(.orange)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                Divider()
                
                // Instructions Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Instructions", systemImage: "list.number")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(recipe.instructionSections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            if let title = section.title {
                                Text(title)
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                    .padding(.top, 8)
                            }
                            
                            ForEach(section.steps) { step in
                                HStack(alignment: .top, spacing: 12) {
                                    if let stepNum = step.stepNumber {
                                        Text("\(stepNum)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                            .background(Color.green)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                            .padding(.top, 6)
                                    }
                                    
                                    Text(step.text)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.bottom, 4)
                            }
                        }
                    }
                }
                
                // Notes Section - Always show to allow adding tips
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Notes", systemImage: "note.text")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Show existing notes
                    ForEach(recipe.notes) { note in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: iconForNoteType(note.type))
                                .font(.title3)
                                .foregroundStyle(colorForNoteType(note.type))
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.type.rawValue.capitalized)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(colorForNoteType(note.type))
                                
                                Text(note.text)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(12)
                        .background(colorForNoteType(note.type).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Show pending tips (not yet saved)
                    ForEach(pendingTips) { note in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: iconForNoteType(note.type))
                                .font(.title3)
                                .foregroundStyle(colorForNoteType(note.type))
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(note.type.rawValue.capitalized)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(colorForNoteType(note.type))
                                    
                                    Spacer()
                                    
                                    Text("Pending")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.2))
                                        .foregroundStyle(.orange)
                                        .clipShape(Capsule())
                                }
                                
                                Text(note.text)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                removePendingTip(note)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(colorForNoteType(note.type).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                    
                    // Show helpful message if no notes exist yet
                    if recipe.notes.isEmpty && pendingTips.isEmpty {
                        Text("No notes yet. Add cooking tips, substitutions, or important reminders.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                            .padding(.vertical, 8)
                    }
                    
                    // Add Tip Button - Always visible
                    Button {
                        showingAddTip = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add a Tip")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Reference
                if let reference = recipe.reference {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Reference", systemImage: "link")
                            .font(.headline)
                        
                        Text(reference)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipe.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            // CloudKit Sync Badge
            ToolbarItem(placement: .navigationBarTrailing) {
                CloudKitSyncBadge()
            }
            
            // Share button
            ToolbarItem(placement: .primaryAction) {
                RecipeShareButton(recipe: recipe)
            }
            
            // Export to Reminders button
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    Task {
                        await exportIngredientsToReminders()
                    }
                } label: {
                    if isExportingToReminders {
                        ProgressView()
                    } else {
                        Label("Add to Reminders", systemImage: "list.bullet.clipboard")
                    }
                }
                .disabled(isExportingToReminders)
            }
            
            // FODMAP Guide button
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    showingFODMAPGuide = true
                } label: {
                    Label("FODMAP Guide", systemImage: "book.circle")
                }
            }
            
            // Edit button (only for saved recipes)
            if isSaved {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let savedRecipe = savedRecipe {
                RecipeEditorView(recipe: savedRecipe)
            }
        }
        .sheet(isPresented: $showingAllergenDetail) {
            if let score = allergenScore {
                RecipeAllergenDetailView(recipe: recipe, score: score)
            }
        }
        .sheet(isPresented: $showingFODMAPGuide) {
            FODMAPQuickReferenceView()
        }
        .sheet(isPresented: $showingAddTip) {
            AddTipSheet(
                tipText: $newTipText,
                onSave: {
                    addPendingTip()
                },
                onCancel: {
                    newTipText = ""
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Reminders", isPresented: $showingRemindersAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(remindersAlertMessage)
        }
        .onAppear {
            checkForPendingAnalysis()
            
            // Auto-load diabetic analysis if profile has diabetes concern
            if let profile = activeProfile, profile.hasDiabetesConcern, diabeticInfo == nil, !isLoadingDiabeticInfo {
                Task {
                    await loadDiabeticInfo()
                }
            }
        }
        .trackTask(
            type: .diabeticAnalysis,
            recipeId: recipe.id,
            progress: analysisProgress,
            isActive: isLoadingDiabeticInfo
        )
        .alert("Resume Analysis?", isPresented: $showPendingAnalysisAlert) {
            Button("Resume") {
                Task {
                    await resumeAnalysis()
                }
            }
            Button("Cancel", role: .cancel) {
                appState.completeTask()
            }
        } message: {
            Text("You have a diabetic analysis in progress for this recipe. Would you like to resume?")
        }
    }
    
    // MARK: - Export to Reminders
    
    private func exportIngredientsToReminders() async {
        isExportingToReminders = true
        
        do {
            try await remindersService.addIngredientsToReminders(recipe: recipe)
            
            // Count total ingredients
            let totalIngredients = recipe.ingredientSections.reduce(0) { $0 + $1.ingredients.count }
            
            remindersAlertMessage = "Successfully added \(totalIngredients) ingredient\(totalIngredients == 1 ? "" : "s") to your Reminders app in a list called '\(recipe.title)'."
            showingRemindersAlert = true
        } catch RemindersError.permissionDenied {
            remindersAlertMessage = "Permission to access Reminders was denied. Please enable it in Settings > Privacy & Security > Reminders to use this feature."
            showingRemindersAlert = true
        } catch {
            remindersAlertMessage = "Failed to add ingredients to Reminders: \(error.localizedDescription)"
            showingRemindersAlert = true
        }
        
        isExportingToReminders = false
    }
    
    // MARK: - Diabetic Analysis
    
    private func loadDiabeticInfo() async {
        isLoadingDiabeticInfo = true
        analysisProgress = 0.0
        defer { 
            isLoadingDiabeticInfo = false
            analysisProgress = 0.0
        }
        
        do {
            // Progress: Preparing request
            analysisProgress = 0.1
            logInfo("Starting diabetic analysis for recipe: \(recipe.title)", category: "diabetic")
            
            // Get the model container from the context
            let modelContainer = modelContext.container
            
            // Progress: Container ready
            analysisProgress = 0.2
            
            // For saved recipes, use the saved Recipe entity
            if let savedRecipe = savedRecipe {
                analysisProgress = 0.3
                logInfo("Analyzing saved recipe", category: "diabetic")
                
                diabeticInfo = try await DiabeticAnalyzer.shared.analyzeDiabeticInfo(
                    for: savedRecipe,
                    modelContainer: modelContainer
                )
            } else {
                analysisProgress = 0.3
                logInfo("Analyzing unsaved recipe", category: "diabetic")
                
                // For unsaved recipes, use RecipeModel
                diabeticInfo = try await DiabeticAnalyzer.shared.analyzeDiabeticInfo(
                    for: recipe,
                    modelContainer: modelContainer
                )
            }
            
            // Progress: Analysis complete
            analysisProgress = 1.0
            logInfo("Diabetic analysis completed successfully", category: "diabetic")
            
        } catch {
            // Handle error - show alert to user
            logError("Diabetic analysis failed: \(error)", category: "diabetic")
            remindersAlertMessage = "Failed to analyze recipe: \(error.localizedDescription)"
            showingRemindersAlert = true
        }
    }
    
    // MARK: - Task Restoration
    
    private func checkForPendingAnalysis() {
        // Check if there's a pending analysis task for this recipe
        if let task = appState.activeTask,
           task.taskType == .diabeticAnalysis,
           task.recipeId == recipe.id {
            logInfo("Found pending diabetic analysis for recipe: \(recipe.title)", category: "state")
            showPendingAnalysisAlert = true
        }
    }
    
    private func resumeAnalysis() async {
        // Resume from saved progress
        guard let task = appState.activeTask,
              task.recipeId == recipe.id else { 
            appState.completeTask()
            return 
        }
        
        logInfo("Resuming diabetic analysis from progress: \(task.progress)", category: "state")
        analysisProgress = task.progress
        
        // Continue analysis from where it left off
        await loadDiabeticInfo()
    }
    
    // MARK: - Helper Functions
    
    private func addPendingTip() {
        guard !newTipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showingAddTip = false
            return
        }
        
        let tip = RecipeNote(type: .tip, text: newTipText)
        pendingTips.append(tip)
        newTipText = ""
        showingAddTip = false
    }
    
    private func removePendingTip(_ tip: RecipeNote) {
        pendingTips.removeAll { $0.id == tip.id }
    }
    
    private func saveRecipeWithTips() {
        // If there are pending tips, we need to create an updated recipe with them
        if !pendingTips.isEmpty {
            // Create a new RecipeModel with the pending tips included
            let updatedNotes = recipe.notes + pendingTips
            
            // Create updated recipe model
            let updatedRecipe = RecipeModel(
                id: recipe.id,
                title: recipe.title,
                headerNotes: recipe.headerNotes,
                yield: recipe.yield,
                ingredientSections: recipe.ingredientSections,
                instructionSections: recipe.instructionSections,
                notes: updatedNotes,
                reference: recipe.reference,
                imageName: recipe.imageName,
                additionalImageNames: recipe.additionalImageNames,
                imageURLs: recipe.imageURLs
            )
            
            // Save the updated recipe to SwiftData
            let savedRecipe = Recipe(from: updatedRecipe)
            modelContext.insert(savedRecipe)
            
            // Clear pending tips after saving
            pendingTips.removeAll()
            
            // Call the original onSave callback (for UI updates)
            onSave()
        } else {
            // No pending tips, just call the original save
            onSave()
        }
    }
    
    private func savePendingTipsToExistingRecipe() {
        guard let savedRecipe = savedRecipe, !pendingTips.isEmpty else {
            logWarning("Cannot save tips - recipe not found or no pending tips", category: "tips")
            return
        }
        
        // Store count before clearing for the success message
        let tipCount = pendingTips.count
        
        // Get existing notes from the saved recipe
        let decoder = JSONDecoder()
        var existingNotes: [RecipeNote] = []
        if let notesData = savedRecipe.notesData,
           let notes = try? decoder.decode([RecipeNote].self, from: notesData) {
            existingNotes = notes
        }
        
        // Add pending tips to existing notes
        let updatedNotes = existingNotes + pendingTips
        
        // Encode and save
        let encoder = JSONEncoder()
        if let encodedNotes = try? encoder.encode(updatedNotes) {
            savedRecipe.notesData = encodedNotes
            
            // Update version tracking
            savedRecipe.version = savedRecipe.currentVersion + 1
            savedRecipe.lastModified = Date()
            
            // Try to save context
            do {
                try modelContext.save()
                logInfo("Successfully saved \(tipCount) tip(s) to recipe: \(recipe.title)", category: "tips")
                
                // Clear pending tips after successful save
                pendingTips.removeAll()
                
                // Show success feedback with correct count
                remindersAlertMessage = "Successfully added \(tipCount) tip\(tipCount == 1 ? "" : "s") to the recipe!"
                showingRemindersAlert = true
            } catch {
                logError("Failed to save tips: \(error)", category: "tips")
                remindersAlertMessage = "Failed to save tips: \(error.localizedDescription)"
                showingRemindersAlert = true
            }
        }
    }
    
    private func getAllImageNames(for recipe: RecipeModel) -> [String] {
        var names: [String] = []
        
        // If this is a saved recipe, get images from the live SwiftData entity
        // This ensures we see newly added images from the editor
        if let savedRecipe = savedRecipe {
            // Add main image
            if let imageName = savedRecipe.imageName {
                names.append(imageName)
            }
            
            // Add additionalImageNames from the live entity
            if let additionalNames = savedRecipe.additionalImageNames {
                names.append(contentsOf: additionalNames)
            }
        } else {
            // For unsaved recipes, use the RecipeModel data
            // Add main image
            if let imageName = recipe.imageName {
                names.append(imageName)
            }
            
            // Add additionalImageNames if available
            if let additionalNames = recipe.additionalImageNames {
                names.append(contentsOf: additionalNames)
            }
            
            // Add imageURLs if available (these might be local file names)
            if let imageURLs = recipe.imageURLs {
                names.append(contentsOf: imageURLs)
            }
        }
        
        // Remove duplicates while preserving order
        let uniqueNames = names.reduce(into: [String]()) { result, item in
            if !result.contains(item) {
                result.append(item)
            }
        }
        
        // Debug: Log image count
        logDebug("Recipe '\(recipe.title)' has \(uniqueNames.count) images: \(uniqueNames)", category: "images")
        
        return uniqueNames
    }
    
    private func iconForNoteType(_ type: RecipeNote.NoteType) -> String {
        switch type {
        case .tip: return "lightbulb.fill"
        case .substitution: return "arrow.left.arrow.right"
        case .warning: return "exclamationmark.triangle.fill"
        case .timing: return "clock.fill"
        case .general: return "info.circle.fill"
        }
    }
    
    private func colorForNoteType(_ type: RecipeNote.NoteType) -> Color {
        switch type {
        case .tip: return .blue
        case .substitution: return .orange
        case .warning: return .red
        case .timing: return .purple
        case .general: return .gray
        }
    }
}

// MARK: - Add Tip Sheet

struct AddTipSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var tipText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Add a Tip", systemImage: "lightbulb.fill")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("Share your cooking tips, tricks, or modifications for this recipe.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Add character count
                HStack {
                    Spacer()
                    Text("\(tipText.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                
                TextEditor(text: $tipText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .focused($isFocused)
                    .padding(.horizontal)
                
                // Add a prominent save button at the bottom as well
                Button {
                    onSave()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Add Tip")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(tipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                .padding(.bottom)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(tipText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Auto-focus the text editor
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isFocused = true
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(
            recipe: RecipeModel(
                title: "Lassi",
                headerNotes: "Yogurt Sherbet - Very refreshing and cooling.",
                yield: "Serves 1 to 2",
                ingredientSections: [
                    IngredientSection(
                        ingredients: [
                            Ingredient(quantity: "¾", unit: "cup", name: "plain yogurt", metricQuantity: "175", metricUnit: "mL"),
                            Ingredient(quantity: "1", unit: "cup", name: "water", metricQuantity: "250", metricUnit: "mL"),
                            Ingredient(quantity: "⅛", unit: "tsp.", name: "salt", metricQuantity: "0.5", metricUnit: "mL"),
                            Ingredient(quantity: "⅛", unit: "tsp.", name: "ground black pepper", metricQuantity: "0.5", metricUnit: "mL"),
                            Ingredient(quantity: "⅛", unit: "tsp.", name: "cumin powder", metricQuantity: "0.5", metricUnit: "mL"),
                            Ingredient(quantity: "", unit: "", name: "ice cubes")
                        ]
                    )
                ],
                instructionSections: [
                    InstructionSection(
                        steps: [
                            InstructionStep(text: "Combine all ingredients in the blender and blend until smooth. Sugar can be added instead of salt and pepper, if preferred.")
                        ]
                    )
                ],
                notes: [],
                reference: "See photograph, page 48."
            ),
            isSaved: false,
            onSave: {}
        )
    }
}
