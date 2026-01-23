//
//  CookingModeView.swift
//  Reczipes2
//
//  Dedicated cooking mode view for step-by-step recipe following
//

import SwiftUI

struct CookingModeView: View {
    let item: RecipeDisplayItem
    
    @State private var completedSteps: Set<Int> = []
    @State private var servingMultiplier: Double = 1.0
    @Environment(\.dismiss) private var dismiss
    
    // Convenience accessor for the recipe model
    private var recipe: RecipeModel {
        item.toRecipeModel()
    }
    
    // Convenience initializer for backward compatibility
    init(recipe: RecipeModel) {
        self.item = .owned(recipe)
    }
    
    // New initializer for RecipeDisplayItem
    init(item: RecipeDisplayItem) {
        self.item = item
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recipe Header
                recipeHeader
                
                // Serving Controls
                servingControls
                
                // Ingredients Section
                if !recipe.ingredientSections.isEmpty {
                    ingredientsSection
                }
                
                // Instructions Section
                if !recipe.instructionSections.isEmpty {
                    instructionsSection
                }
                
                // Notes Section
                if !recipe.notes.isEmpty {
                    notesSection
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Cooking Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Recipe Header
    
    @ViewBuilder
    private var recipeHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(recipe.title)
                .font(.largeTitle.bold())
            
            HStack(spacing: 16) {
                if let cuisine = recipe.cuisine {
                    Label(cuisine, systemImage: "flag.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let servings = recipe.servings, servings > 0 {
                    Label("\(servings) servings", systemImage: "person.2.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let prepTime = recipe.prepTime {
                    Label(prepTime, systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Serving Controls
    
    @ViewBuilder
    private var servingControls: some View {
        if let servings = recipe.servings, servings > 0 {
            VStack(alignment: .leading, spacing: 8) {
                Text("Adjust Servings")
                    .font(.headline)
                
                HStack {
                    Button {
                        if servingMultiplier > 0.5 {
                            servingMultiplier -= 0.5
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(servingMultiplier <= 0.5)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("\(Int(Double(servings) * servingMultiplier))")
                            .font(.title.bold())
                        Text("servings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        servingMultiplier += 0.5
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Ingredients Section
    
    @ViewBuilder
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(recipe.ingredientSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        if let title = section.title {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.blue)
                        }
                        
                        ForEach(section.ingredients) { ingredient in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 6)
                                
                                Text(scaledIngredient(ingredient))
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Instructions Section
    
    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(recipe.instructionSections) { section in
                    VStack(alignment: .leading, spacing: 12) {
                        if let title = section.title {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.green)
                                .padding(.top, 8)
                        }
                        
                        ForEach(Array(section.steps.enumerated()), id: \.offset) { index, step in
                            instructionRow(globalIndex: calculateGlobalIndex(section: section, localIndex: index), step: step)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func instructionRow(globalIndex: Int, step: InstructionStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                toggleStepCompletion(globalIndex)
            } label: {
                Image(systemName: completedSteps.contains(globalIndex) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(completedSteps.contains(globalIndex) ? .green : .secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let stepNumber = step.stepNumber {
                    Text("Step \(stepNumber)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                
                Text(step.text)
                    .font(.body)
                    .strikethrough(completedSteps.contains(globalIndex))
                    .foregroundStyle(completedSteps.contains(globalIndex) ? .secondary : .primary)
            }
        }
        .padding()
        .background(
            completedSteps.contains(globalIndex) ? Color(.systemGray6) : Color(.systemGray5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Notes Section
    
    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
            
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
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func calculateGlobalIndex(section: InstructionSection, localIndex: Int) -> Int {
        // Calculate the global step index across all sections
        var globalIndex = 0
        for instructionSection in recipe.instructionSections {
            if instructionSection.id == section.id {
                return globalIndex + localIndex
            }
            globalIndex += instructionSection.steps.count
        }
        return globalIndex + localIndex
    }
    
    private func toggleStepCompletion(_ index: Int) {
        if completedSteps.contains(index) {
            completedSteps.remove(index)
        } else {
            completedSteps.insert(index)
        }
    }
    
    private func scaledIngredient(_ ingredient: Ingredient) -> String {
        // Format ingredient with scaling
        var parts: [String] = []
        
        // Scale quantity if multiplier is not 1.0
        if let quantity = ingredient.quantity, !quantity.isEmpty {
            if servingMultiplier != 1.0, let numericQuantity = parseQuantity(quantity) {
                let scaled = numericQuantity * servingMultiplier
                let formatted = formatQuantity(scaled)
                parts.append(formatted)
            } else {
                parts.append(quantity)
            }
        }
        
        // Add unit
        if let unit = ingredient.unit, !unit.isEmpty {
            parts.append(unit)
        }
        
        // Add name
        parts.append(ingredient.name)
        
        // Add preparation if present
        if let preparation = ingredient.preparation, !preparation.isEmpty {
            parts.append("(\(preparation))")
        }
        
        return parts.joined(separator: " ")
    }
    
    private func parseQuantity(_ quantity: String) -> Double? {
        // Handle fractions like "1/2", "1 1/2", etc.
        let trimmed = quantity.trimmingCharacters(in: .whitespaces)
        
        // Try simple double first
        if let value = Double(trimmed) {
            return value
        }
        
        // Handle fractions
        let components = trimmed.components(separatedBy: .whitespaces)
        var total = 0.0
        
        for component in components {
            if component.contains("/") {
                let parts = component.split(separator: "/")
                if parts.count == 2,
                   let numerator = Double(parts[0]),
                   let denominator = Double(parts[1]),
                   denominator != 0 {
                    total += numerator / denominator
                }
            } else if let value = Double(component) {
                total += value
            }
        }
        
        return total > 0 ? total : nil
    }
    
    private func formatQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value).replacingOccurrences(of: ".00", with: "")
        }
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

// MARK: - RecipeModel Extensions for Cooking Mode

extension RecipeModel {
    /// Cuisine type extracted from headerNotes or reference
    var cuisine: String? {
        // You can parse this from headerNotes or reference if available
        // For now, return nil - you can enhance this later
        return nil
    }
    
    /// Prep time extracted from headerNotes
    var prepTime: String? {
        // You can parse this from headerNotes if available
        // For now, return nil - you can enhance this later
        return nil
    }
    
    /// Number of servings extracted from yield string
    var servings: Int? {
        guard let yieldString = yield else { return nil }
        
        // Try to extract number from yield string
        // Example: "Serves 4" → 4, "Makes 12 cookies" → 12
        let numbers = yieldString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        return numbers.first
    }
}

#Preview {
    NavigationStack {
        CookingModeView(
            recipe: RecipeModel(
                title: "Spaghetti Carbonara",
                headerNotes: "Classic Italian pasta dish",
                yield: "Serves 4",
                ingredientSections: [
                    IngredientSection(
                        ingredients: [
                            Ingredient(quantity: "1", unit: "lb", name: "spaghetti"),
                            Ingredient(quantity: "6", unit: "oz", name: "guanciale or pancetta", preparation: "diced"),
                            Ingredient(quantity: "4", unit: "", name: "large eggs"),
                            Ingredient(quantity: "1", unit: "cup", name: "Pecorino Romano", preparation: "grated"),
                            Ingredient(quantity: "", unit: "", name: "Black pepper to taste"),
                            Ingredient(quantity: "", unit: "", name: "Salt for pasta water")
                        ]
                    )
                ],
                instructionSections: [
                    InstructionSection(
                        steps: [
                            InstructionStep(stepNumber: 1, text: "Bring a large pot of salted water to boil. Cook spaghetti according to package directions until al dente."),
                            InstructionStep(stepNumber: 2, text: "While pasta cooks, render the guanciale in a large skillet over medium heat until crispy, about 8 minutes."),
                            InstructionStep(stepNumber: 3, text: "In a bowl, whisk together eggs and Pecorino Romano cheese."),
                            InstructionStep(stepNumber: 4, text: "When pasta is ready, reserve 1 cup pasta water, then drain the spaghetti."),
                            InstructionStep(stepNumber: 5, text: "Remove skillet from heat. Add hot pasta to the guanciale and toss to coat."),
                            InstructionStep(stepNumber: 6, text: "Slowly add the egg mixture while tossing constantly. Add pasta water as needed to create a creamy sauce."),
                            InstructionStep(stepNumber: 7, text: "Season generously with black pepper and serve immediately.")
                        ]
                    )
                ],
                notes: [
                    RecipeNote(type: .tip, text: "The key is to work quickly and off the heat when adding eggs to prevent scrambling."),
                    RecipeNote(type: .substitution, text: "Use freshly grated Pecorino Romano for best results.")
                ]
            )
        )
    }
}
