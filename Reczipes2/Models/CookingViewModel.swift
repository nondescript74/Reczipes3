//
//  CookingViewModel.swift
//  reczipes2-imageextract
//
//  View model managing cooking session state
//

import SwiftUI
import SwiftData
import Observation

@Observable
final class CookingViewModel {
    var selectedRecipes: [Recipe?] = [nil, nil]
    var currentRecipeIndex: Int = 0
    var keepAwakeManager = KeepAwakeManager()
    
    private var modelContext: ModelContext
    private var session: CookingSession?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadSession() {
        let descriptor = FetchDescriptor<CookingSession>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            if let existingSession = sessions.first {
                session = existingSession
                loadRecipesFromSession(existingSession)
                keepAwakeManager.isEnabled = existingSession.keepAwakeEnabled
            } else {
                createNewSession()
            }
        } catch {
            logError("Error loading cooking session: \(error)", category: "recipe")
            createNewSession()
        }
    }
    
    func selectRecipe(_ recipe: Recipe, slot: Int) {
        guard slot >= 0 && slot < 2 else { return }
        selectedRecipes[slot] = recipe
        session?.updateRecipe(recipe.id, slot: slot)
        saveSession()
    }
    
    func clearRecipe(slot: Int) {
        guard slot >= 0 && slot < 2 else { return }
        selectedRecipes[slot] = nil
        session?.updateRecipe(nil, slot: slot)
        saveSession()
    }
    
    func saveSession() {
        guard let session = session else { return }
        session.keepAwakeEnabled = keepAwakeManager.isEnabled
        session.lastUpdated = Date()
        
        do {
            try modelContext.save()
        } catch {
            logError("Error saving cooking session: \(error)", category: "recipe")
        }
    }
    
    func cleanup() {
        keepAwakeManager.disable()
        saveSession()
    }
    
    // MARK: - Private Methods
    
    private func createNewSession() {
        let newSession = CookingSession()
        modelContext.insert(newSession)
        session = newSession
        
        do {
            try modelContext.save()
        } catch {
            logError("Error creating new session: \(error)", category: "recipe")
        }
    }
    
    private func loadRecipesFromSession(_ session: CookingSession) {
        selectedRecipes = [
            loadRecipe(by: session.primaryRecipeID),
            loadRecipe(by: session.secondaryRecipeID)
        ]
    }
    
    private func loadRecipe(by id: UUID?) -> Recipe? {
        guard let id = id else { return nil }
        
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { recipe in
                recipe.id == id
            }
        )
        
        do {
            let recipes = try modelContext.fetch(descriptor)
            return recipes.first
        } catch {
            logError("Error loading recipe \(id): \(error)", category: "recipe")
            return nil
        }
    }
}
