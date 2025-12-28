//
//  RecipeEditorView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/10/25.
//

import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let recipe: Recipe
    
    // Editable properties
    @State private var title: String
    @State private var headerNotes: String
    @State private var recipeYield: String
    @State private var reference: String
    
    // Editable sections
    @State private var ingredientSections: [EditableIngredientSection]
    @State private var instructionSections: [EditableInstructionSection]
    @State private var notes: [EditableRecipeNote]
    
    @State private var showingSaveConfirmation = false
    @State private var hasUnsavedChanges = false
    
    init(recipe: Recipe) {
        self.recipe = recipe
        
        // Initialize state from recipe
        _title = State(initialValue: recipe.title)
        _headerNotes = State(initialValue: recipe.headerNotes ?? "")
        _recipeYield = State(initialValue: recipe.recipeYield ?? "")
        _reference = State(initialValue: recipe.reference ?? "")
        
        // Decode and convert sections
        let decoder = JSONDecoder()
        
        // Ingredient sections
        let decodedIngredients: [IngredientSection]
        if let ingredientsData = recipe.ingredientSectionsData,
           let decoded = try? decoder.decode([IngredientSection].self, from: ingredientsData) {
            decodedIngredients = decoded
        } else {
            decodedIngredients = []
        }
        _ingredientSections = State(initialValue: decodedIngredients.map { EditableIngredientSection(from: $0) })
        
        // Instruction sections
        let decodedInstructions: [InstructionSection]
        if let instructionsData = recipe.instructionSectionsData,
           let decoded = try? decoder.decode([InstructionSection].self, from: instructionsData) {
            decodedInstructions = decoded
        } else {
            decodedInstructions = []
        }
        _instructionSections = State(initialValue: decodedInstructions.map { EditableInstructionSection(from: $0) })
        
        // Notes
        let decodedNotes: [RecipeNote]
        if let notesData = recipe.notesData,
           let decoded = try? decoder.decode([RecipeNote].self, from: notesData) {
            decodedNotes = decoded
        } else {
            decodedNotes = []
        }
        _notes = State(initialValue: decodedNotes.map { EditableRecipeNote(from: $0) })
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Recipe Title", text: $title)
                        .onChange(of: title) { hasUnsavedChanges = true }
                    
                    TextField("Header Notes", text: $headerNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: headerNotes) { hasUnsavedChanges = true }
                    
                    TextField("Yield (e.g., Serves 4)", text: $recipeYield)
                        .onChange(of: recipeYield) { hasUnsavedChanges = true }
                    
                    TextField("Reference", text: $reference)
                        .onChange(of: reference) { hasUnsavedChanges = true }
                }
                
                // Ingredients Section
                Section {
                    ForEach($ingredientSections) { $section in
                        IngredientSectionEditor(section: $section, onChange: { hasUnsavedChanges = true })
                    }
                    .onDelete { indices in
                        ingredientSections.remove(atOffsets: indices)
                        hasUnsavedChanges = true
                    }
                    .onMove { source, destination in
                        ingredientSections.move(fromOffsets: source, toOffset: destination)
                        hasUnsavedChanges = true
                    }
                    
                    Button {
                        ingredientSections.append(EditableIngredientSection())
                        hasUnsavedChanges = true
                    } label: {
                        Label("Add Ingredient Section", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Ingredients")
                        Spacer()
                        EditButton()
                    }
                }
                
                // Instructions Section
                Section {
                    ForEach($instructionSections) { $section in
                        InstructionSectionEditor(section: $section, onChange: { hasUnsavedChanges = true })
                    }
                    .onDelete { indices in
                        instructionSections.remove(atOffsets: indices)
                        hasUnsavedChanges = true
                    }
                    .onMove { source, destination in
                        instructionSections.move(fromOffsets: source, toOffset: destination)
                        hasUnsavedChanges = true
                    }
                    
                    Button {
                        instructionSections.append(EditableInstructionSection())
                        hasUnsavedChanges = true
                    } label: {
                        Label("Add Instruction Section", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Instructions")
                        Spacer()
                        EditButton()
                    }
                }
                
                // Notes Section
                Section {
                    ForEach($notes) { $note in
                        RecipeNoteEditor(note: $note, onChange: { hasUnsavedChanges = true })
                    }
                    .onDelete { indices in
                        notes.remove(atOffsets: indices)
                        hasUnsavedChanges = true
                    }
                    
                    Button {
                        notes.append(EditableRecipeNote())
                        hasUnsavedChanges = true
                    } label: {
                        Label("Add Note", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("Notes")
                        Spacer()
                        EditButton()
                    }
                }
            }
            .navigationTitle("Edit Recipe")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloudKitSyncBadge()
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasUnsavedChanges {
                            showingSaveConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Unsaved Changes", isPresented: $showingSaveConfirmation) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
        }
    }
    
    private func saveChanges() {
        let encoder = JSONEncoder()
        
        // Convert editable sections back to model types
        let ingredientSectionModels = ingredientSections.map { $0.toModel() }
        let instructionSectionModels = instructionSections.map { $0.toModel() }
        let noteModels = notes.map { $0.toModel() }
        
        // Encode ingredients to check if they changed
        let newIngredientsData = try? encoder.encode(ingredientSectionModels)
        let ingredientsChanged = (newIngredientsData != recipe.ingredientSectionsData)
        
        // Update recipe properties
        recipe.title = title
        recipe.headerNotes = headerNotes.isEmpty ? nil : headerNotes
        recipe.recipeYield = recipeYield.isEmpty ? nil : recipeYield
        recipe.reference = reference.isEmpty ? nil : reference
        
        recipe.instructionSectionsData = try? encoder.encode(instructionSectionModels)
        recipe.notesData = try? encoder.encode(noteModels)
        
        // Update ingredients with version tracking if they changed
        if ingredientsChanged, let ingredientsData = newIngredientsData {
            print("📝 Ingredients changed - updating version and hash")
            recipe.updateIngredients(ingredientsData)
            
            // Clear any cached diabetic analysis since ingredients changed
            Task {
                DiabeticInfoCache.shared.clear(recipeId: recipe.id)
                print("🗑️ Cleared in-memory diabetic cache for recipe: \(recipe.title)")
            }
        } else {
            // Still update lastModified even if ingredients didn't change
            recipe.lastModified = Date()
        }
        
        // Save context
        do {
            try modelContext.save()
            print("💾 Recipe saved successfully with version \(recipe.currentVersion)")
        } catch {
            print("❌ Failed to save recipe: \(error)")
        }
        
        dismiss()
    }
}

// MARK: - Editable Models

struct EditableIngredientSection: Identifiable {
    let id: UUID
    var title: String
    var ingredients: [EditableIngredient]
    var transitionNote: String
    
    init(id: UUID = UUID(), title: String = "", ingredients: [EditableIngredient] = [], transitionNote: String = "") {
        self.id = id
        self.title = title
        self.ingredients = ingredients.isEmpty ? [EditableIngredient()] : ingredients
        self.transitionNote = transitionNote
    }
    
    init(from section: IngredientSection) {
        self.id = section.id
        self.title = section.title ?? ""
        self.ingredients = section.ingredients.map { EditableIngredient(from: $0) }
        self.transitionNote = section.transitionNote ?? ""
    }
    
    func toModel() -> IngredientSection {
        IngredientSection(
            id: id,
            title: title.isEmpty ? nil : title,
            ingredients: ingredients.map { $0.toModel() },
            transitionNote: transitionNote.isEmpty ? nil : transitionNote
        )
    }
}

struct EditableIngredient: Identifiable {
    let id: UUID
    var quantity: String
    var unit: String
    var name: String
    var preparation: String
    var metricQuantity: String
    var metricUnit: String
    
    init(id: UUID = UUID(), quantity: String = "", unit: String = "", name: String = "",
         preparation: String = "", metricQuantity: String = "", metricUnit: String = "") {
        self.id = id
        self.quantity = quantity
        self.unit = unit
        self.name = name
        self.preparation = preparation
        self.metricQuantity = metricQuantity
        self.metricUnit = metricUnit
    }
    
    init(from ingredient: Ingredient) {
        self.id = ingredient.id
        self.quantity = ingredient.quantity ?? ""
        self.unit = ingredient.unit ?? ""
        self.name = ingredient.name
        self.preparation = ingredient.preparation ?? ""
        self.metricQuantity = ingredient.metricQuantity ?? ""
        self.metricUnit = ingredient.metricUnit ?? ""
    }
    
    func toModel() -> Ingredient {
        Ingredient(
            id: id,
            quantity: quantity.isEmpty ? nil : quantity,
            unit: unit.isEmpty ? nil : unit,
            name: name,
            preparation: preparation.isEmpty ? nil : preparation,
            metricQuantity: metricQuantity.isEmpty ? nil : metricQuantity,
            metricUnit: metricUnit.isEmpty ? nil : metricUnit
        )
    }
}

struct EditableInstructionSection: Identifiable {
    let id: UUID
    var title: String
    var steps: [EditableInstructionStep]
    
    init(id: UUID = UUID(), title: String = "", steps: [EditableInstructionStep] = []) {
        self.id = id
        self.title = title
        self.steps = steps.isEmpty ? [EditableInstructionStep()] : steps
    }
    
    init(from section: InstructionSection) {
        self.id = section.id
        self.title = section.title ?? ""
        self.steps = section.steps.map { EditableInstructionStep(from: $0) }
    }
    
    func toModel() -> InstructionSection {
        InstructionSection(
            id: id,
            title: title.isEmpty ? nil : title,
            steps: steps.map { $0.toModel() }
        )
    }
}

struct EditableInstructionStep: Identifiable {
    let id: UUID
    var stepNumber: String
    var text: String
    
    init(id: UUID = UUID(), stepNumber: String = "", text: String = "") {
        self.id = id
        self.stepNumber = stepNumber
        self.text = text
    }
    
    init(from step: InstructionStep) {
        self.id = step.id
        self.stepNumber = step.stepNumber.map { String($0) } ?? ""
        self.text = step.text
    }
    
    func toModel() -> InstructionStep {
        InstructionStep(
            id: id,
            stepNumber: Int(stepNumber),
            text: text
        )
    }
}

struct EditableRecipeNote: Identifiable {
    let id: UUID
    var type: RecipeNote.NoteType
    var text: String
    
    init(id: UUID = UUID(), type: RecipeNote.NoteType = .general, text: String = "") {
        self.id = id
        self.type = type
        self.text = text
    }
    
    init(from note: RecipeNote) {
        self.id = note.id
        self.type = note.type
        self.text = note.text
    }
    
    func toModel() -> RecipeNote {
        RecipeNote(id: id, type: type, text: text)
    }
}

// MARK: - Editor Components

struct IngredientSectionEditor: View {
    @Binding var section: EditableIngredientSection
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Section Title (optional)", text: $section.title)
                .font(.headline)
                .onChange(of: section.title) { onChange() }
            
            ForEach($section.ingredients) { $ingredient in
                VStack(spacing: 8) {
                    HStack {
                        TextField("Qty", text: $ingredient.quantity)
                            .frame(width: 50)
                            .onChange(of: ingredient.quantity) { onChange() }
                        
                        TextField("Unit", text: $ingredient.unit)
                            .frame(width: 60)
                            .onChange(of: ingredient.unit) { onChange() }
                        
                        TextField("Ingredient Name", text: $ingredient.name)
                            .onChange(of: ingredient.name) { onChange() }
                    }
                    
                    TextField("Preparation (optional)", text: $ingredient.preparation)
                        .font(.caption)
                        .onChange(of: ingredient.preparation) { onChange() }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indices in
                section.ingredients.remove(atOffsets: indices)
                onChange()
            }
            
            Button {
                section.ingredients.append(EditableIngredient())
                onChange()
            } label: {
                Label("Add Ingredient", systemImage: "plus.circle")
                    .font(.caption)
            }
            
            TextField("Transition Note (optional)", text: $section.transitionNote)
                .font(.caption)
                .italic()
                .onChange(of: section.transitionNote) { onChange() }
            
            Divider()
        }
    }
}

struct InstructionSectionEditor: View {
    @Binding var section: EditableInstructionSection
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Section Title (optional)", text: $section.title)
                .font(.headline)
                .onChange(of: section.title) { onChange() }
            
            ForEach($section.steps) { $step in
                HStack(alignment: .top) {
                    TextField("#", text: $step.stepNumber)
                        .frame(width: 40)
                        .onChange(of: step.stepNumber) { onChange() }
                    
                    TextField("Step instructions", text: $step.text, axis: .vertical)
                        .lineLimit(2...10)
                        .onChange(of: step.text) { onChange() }
                }
                .padding(.vertical, 4)
            }
            .onDelete { indices in
                section.steps.remove(atOffsets: indices)
                onChange()
            }
            
            Button {
                section.steps.append(EditableInstructionStep())
                onChange()
            } label: {
                Label("Add Step", systemImage: "plus.circle")
                    .font(.caption)
            }
            
            Divider()
        }
    }
}

struct RecipeNoteEditor: View {
    @Binding var note: EditableRecipeNote
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Note Type", selection: $note.type) {
                Text("General").tag(RecipeNote.NoteType.general)
                Text("Tip").tag(RecipeNote.NoteType.tip)
                Text("Substitution").tag(RecipeNote.NoteType.substitution)
                Text("Warning").tag(RecipeNote.NoteType.warning)
                Text("Timing").tag(RecipeNote.NoteType.timing)
            }
            .onChange(of: note.type) { onChange() }
            
            TextField("Note text", text: $note.text, axis: .vertical)
                .lineLimit(2...6)
                .onChange(of: note.text) { onChange() }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    
    // Create a sample recipe
    let recipe = Recipe(
        title: "Sample Recipe",
        headerNotes: "A delicious recipe",
        recipeYield: "Serves 4"
    )
    container.mainContext.insert(recipe)
    
    return RecipeEditorView(recipe: recipe)
        .modelContainer(container)
}
