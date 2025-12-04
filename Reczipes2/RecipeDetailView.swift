//
//  RecipeDetailView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: RecipeModel
    let isSaved: Bool
    let onSave: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
                                            Text(ingredient.quantity)
                                                .fontWeight(.semibold)
                                            Text(ingredient.unit)
                                                .fontWeight(.medium)
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
            recipe: .limePickleExample,
            isSaved: false,
            onSave: {}
        )
    }
}
