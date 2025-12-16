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
    
    @Query private var savedRecipes: [Recipe]
    
    @State private var showingEditor = false
    @State private var showingRemindersAlert = false
    @State private var remindersAlertMessage = ""
    @State private var isExportingToReminders = false
    
    private let remindersService = RemindersService()
    
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
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                } else if let imageName = recipe.imageName {
                    // Show the saved image (for saved recipes)
                    RecipeImageView(
                        imageName: imageName,
                        size: nil,  // No fixed size - let it adapt
                        aspectRatio: .fit,
                        cornerRadius: 16
                    )
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 400)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)
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
                        
                        Button(action: onSave) {
                            Label(
                                isSaved ? "Saved" : "Save Recipe",
                                systemImage: isSaved ? "checkmark.circle.fill" : "plus.circle.fill"
                            )
                            .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(isSaved ? .green : .blue)
                        .disabled(isSaved)
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
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            if let quantity = ingredient.quantity, !quantity.isEmpty {
                                                Text(quantity)
                                                    .fontWeight(.semibold)
                                            }
                                            if let unit = ingredient.unit, !unit.isEmpty {
                                                Text(unit)
                                                    .fontWeight(.medium)
                                            }
                                            Text(ingredient.name)
                                        }
                                        
                                        if let prep = ingredient.preparation {
                                            Text(prep)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .italic()
                                        }
                                        
                                        if let metricQuantity = ingredient.metricQuantity,
                                           let metricUnit = ingredient.metricUnit {
                                            Text("(\(metricQuantity) \(metricUnit))")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
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
                
                // Notes Section
                if !recipe.notes.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Notes", systemImage: "note.text")
                            .font(.title2)
                            .fontWeight(.bold)
                        
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
            // Export to Reminders button
            ToolbarItem(placement: .primaryAction) {
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
        .alert("Reminders", isPresented: $showingRemindersAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(remindersAlertMessage)
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
