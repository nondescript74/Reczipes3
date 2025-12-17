//
//  RecipeShareCardView.swift
//  Reczipes2
//
//  Created for recipe sharing functionality
//

import SwiftUI

/// A beautiful, shareable recipe card that fits on an iPhone screen
struct RecipeShareCardView: View {
    let recipe: RecipeModel
    let sourceType: RecipeSourceType
    let showFullDetails: Bool
    
    @State private var showingIngredients = false
    @State private var showingInstructions = false
    @State private var showingNotes = false
    
    enum RecipeSourceType {
        case email
        case text
        case app
        
        var icon: String {
            switch self {
            case .email: return "envelope.fill"
            case .text: return "message.fill"
            case .app: return "menucard.fill"
            }
        }
        
        var label: String {
            switch self {
            case .email: return "Shared via Email"
            case .text: return "Shared via Text"
            case .app: return "From Reczipes"
            }
        }
        
        var color: Color {
            switch self {
            case .email: return .blue
            case .text: return .green
            case .app: return .purple
            }
        }
    }
    
    init(recipe: RecipeModel, sourceType: RecipeSourceType = .app, showFullDetails: Bool = false) {
        self.recipe = recipe
        self.sourceType = sourceType
        self.showFullDetails = showFullDetails
    }
    
    var body: some View {
        if showFullDetails {
            fullCardView
        } else {
            compactCardView
        }
    }
    
    // MARK: - Compact Card (for sharing as image)
    
    private var compactCardView: some View {
        VStack(spacing: 0) {
            // Header with gradient
            headerSection
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recipe image if available
                    if let imageName = recipe.imageName {
                        RecipeImageView(
                            imageName: imageName,
                            size: nil,
                            aspectRatio: .fill,
                            cornerRadius: 0
                        )
                        .frame(height: 200)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Yield and basic info
                        if let yield = recipe.yield {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .foregroundStyle(sourceType.color)
                                Text(yield)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(sourceType.color.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        // Quick stats
                        HStack(spacing: 20) {
                            StatBadge(
                                icon: "list.bullet",
                                count: totalIngredientsCount,
                                label: "ingredients"
                            )
                            
                            StatBadge(
                                icon: "list.number",
                                count: totalStepsCount,
                                label: "steps"
                            )
                            
                            if !recipe.notes.isEmpty {
                                StatBadge(
                                    icon: "note.text",
                                    count: recipe.notes.count,
                                    label: "notes"
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Info buttons for full details
                        VStack(spacing: 12) {
                            InfoButton(
                                title: "View Ingredients",
                                icon: "list.bullet",
                                count: totalIngredientsCount,
                                color: .blue
                            ) {
                                showingIngredients = true
                            }
                            
                            InfoButton(
                                title: "View Instructions",
                                icon: "list.number",
                                count: totalStepsCount,
                                color: .green
                            ) {
                                showingInstructions = true
                            }
                            
                            if !recipe.notes.isEmpty {
                                InfoButton(
                                    title: "View Notes",
                                    icon: "note.text",
                                    count: recipe.notes.count,
                                    color: .orange
                                ) {
                                    showingNotes = true
                                }
                            }
                        }
                        
                        // Reference
                        if let reference = recipe.reference {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Reference", systemImage: "link")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(reference)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                }
            }
            
            // Footer
            footerSection
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .sheet(isPresented: $showingIngredients) {
            NavigationStack {
                IngredientsListView(sections: recipe.ingredientSections)
                    .navigationTitle("Ingredients")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingIngredients = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingInstructions) {
            NavigationStack {
                InstructionsListView(sections: recipe.instructionSections)
                    .navigationTitle("Instructions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingInstructions = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingNotes) {
            NavigationStack {
                NotesListView(notes: recipe.notes)
                    .navigationTitle("Notes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingNotes = false
                            }
                        }
                    }
            }
        }
    }
    
    // MARK: - Full Card (for in-app preview)
    
    private var fullCardView: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                
                VStack(alignment: .leading, spacing: 24) {
                    // Recipe image if available
                    if let imageName = recipe.imageName {
                        RecipeImageView(
                            imageName: imageName,
                            size: nil,
                            aspectRatio: .fill,
                            cornerRadius: 0
                        )
                        .frame(height: 250)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Ingredients
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Ingredients", systemImage: "list.bullet")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(recipe.ingredientSections) { section in
                                IngredientSectionView(section: section)
                            }
                        }
                        
                        Divider()
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Instructions", systemImage: "list.number")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            ForEach(recipe.instructionSections) { section in
                                InstructionSectionView(section: section)
                            }
                        }
                        
                        // Notes
                        if !recipe.notes.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Notes", systemImage: "note.text")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                ForEach(recipe.notes) { note in
                                    RecipeNoteView(note: note)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                footerSection
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Source badge
            HStack {
                Image(systemName: sourceType.icon)
                Text(sourceType.label)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(sourceType.color)
            .clipShape(Capsule())
            
            // Title
            Text(recipe.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Header notes
            if let headerNotes = recipe.headerNotes {
                Text(headerNotes)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [sourceType.color, sourceType.color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "menucard.fill")
                Text("Reczipes")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(sourceType.color)
            
            Text("Your personal recipe collection")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Computed Properties
    
    private var totalIngredientsCount: Int {
        recipe.ingredientSections.reduce(0) { $0 + $1.ingredients.count }
    }
    
    private var totalStepsCount: Int {
        recipe.instructionSections.reduce(0) { $0 + $1.steps.count }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct InfoButton: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct IngredientSectionView: View {
    let section: IngredientSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = section.title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            ForEach(section.ingredients) { ingredient in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                        .padding(.top, 6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            if let quantity = ingredient.quantity, !quantity.isEmpty {
                                Text(quantity)
                                    .fontWeight(.semibold)
                            }
                            if let unit = ingredient.unit, !unit.isEmpty {
                                Text(unit)
                            }
                            Text(ingredient.name)
                        }
                        .font(.subheadline)
                        
                        if let prep = ingredient.preparation {
                            Text(prep)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
            }
        }
    }
}

struct InstructionSectionView: View {
    let section: InstructionSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = section.title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
            
            ForEach(section.steps) { step in
                HStack(alignment: .top, spacing: 12) {
                    if let stepNum = step.stepNumber {
                        Text("\(stepNum)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(Color.green)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                    }
                    
                    Text(step.text)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct RecipeNoteView: View {
    let note: RecipeNote
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconForType)
                .font(.title3)
                .foregroundStyle(colorForType)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(note.type.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorForType)
                
                Text(note.text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
        .padding(12)
        .background(colorForType.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var iconForType: String {
        switch note.type {
        case .tip: return "lightbulb.fill"
        case .substitution: return "arrow.left.arrow.right"
        case .warning: return "exclamationmark.triangle.fill"
        case .timing: return "clock.fill"
        case .general: return "info.circle.fill"
        }
    }
    
    private var colorForType: Color {
        switch note.type {
        case .tip: return .blue
        case .substitution: return .orange
        case .warning: return .red
        case .timing: return .purple
        case .general: return .gray
        }
    }
}

// MARK: - Full List Views for Sheets

struct IngredientsListView: View {
    let sections: [IngredientSection]
    
    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.ingredients) { ingredient in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                if let quantity = ingredient.quantity, !quantity.isEmpty {
                                    Text(quantity)
                                        .fontWeight(.semibold)
                                }
                                if let unit = ingredient.unit, !unit.isEmpty {
                                    Text(unit)
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
                } header: {
                    if let title = section.title {
                        Text(title)
                    }
                }
                
                if let transitionNote = section.transitionNote {
                    Section {
                        Text(transitionNote)
                            .font(.subheadline)
                            .italic()
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
}

struct InstructionsListView: View {
    let sections: [InstructionSection]
    
    var body: some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.steps) { step in
                        HStack(alignment: .top, spacing: 12) {
                            if let stepNum = step.stepNumber {
                                Text("\(stepNum)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                            
                            Text(step.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } header: {
                    if let title = section.title {
                        Text(title)
                    }
                }
            }
        }
    }
}

struct NotesListView: View {
    let notes: [RecipeNote]
    
    var body: some View {
        List(notes) { note in
            RecipeNoteView(note: note)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
}

// MARK: - Preview

#Preview("Compact Card - Email") {
    RecipeShareCardView(
        recipe: RecipeModel(
            title: "Classic Lasagna",
            headerNotes: "A hearty Italian favorite",
            yield: "Serves 8",
            ingredientSections: [
                IngredientSection(
                    title: "Meat Sauce",
                    ingredients: [
                        Ingredient(quantity: "1", unit: "lb", name: "ground beef"),
                        Ingredient(quantity: "1", unit: "jar", name: "marinara sauce"),
                        Ingredient(quantity: "2", unit: "cloves", name: "garlic", preparation: "minced")
                    ]
                )
            ],
            instructionSections: [
                InstructionSection(
                    steps: [
                        InstructionStep(stepNumber: 1, text: "Brown the meat in a large skillet"),
                        InstructionStep(stepNumber: 2, text: "Add sauce and simmer")
                    ]
                )
            ],
            notes: [
                RecipeNote(type: .tip, text: "Let it rest 15 minutes before serving")
            ],
            reference: "Family recipe"
        ),
        sourceType: .email
    )
    .frame(width: 390, height: 844) // iPhone 14 Pro size
    .padding()
}

#Preview("Full Card") {
    NavigationStack {
        RecipeShareCardView(
            recipe: RecipeModel(
                title: "Homemade Pizza",
                headerNotes: "Better than takeout!",
                yield: "Serves 4",
                ingredientSections: [
                    IngredientSection(
                        ingredients: [
                            Ingredient(quantity: "2", unit: "cups", name: "flour"),
                            Ingredient(quantity: "1", unit: "cup", name: "water")
                        ]
                    )
                ],
                instructionSections: [
                    InstructionSection(
                        steps: [
                            InstructionStep(stepNumber: 1, text: "Mix flour and water")
                        ]
                    )
                ],
                notes: []
            ),
            sourceType: .text,
            showFullDetails: true
        )
    }
}
