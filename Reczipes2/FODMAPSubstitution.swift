//
//  FODMAPSubstitution.swift
//  Reczipes2
//
//  FODMAP ingredient substitution system
//  Created on 12/20/25.
//

import Foundation

// MARK: - FODMAP Substitution Models

/// A substitution suggestion for a high FODMAP ingredient
struct FODMAPSubstitution: Identifiable, Codable {
    let id: UUID
    let originalIngredient: String
    let fodmapCategories: [FODMAPCategory]
    let substitutes: [SubstituteOption]
    let explanation: String
    let portionNote: String?
    
    init(id: UUID = UUID(),
         originalIngredient: String,
         fodmapCategories: [FODMAPCategory],
         substitutes: [SubstituteOption],
         explanation: String,
         portionNote: String? = nil) {
        self.id = id
        self.originalIngredient = originalIngredient
        self.fodmapCategories = fodmapCategories
        self.substitutes = substitutes
        self.explanation = explanation
        self.portionNote = portionNote
    }
}

/// A single substitute option
struct SubstituteOption: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let quantity: String?
    let notes: String?
    let confidence: SubstituteConfidence
    
    init(id: UUID = UUID(),
         name: String,
         quantity: String? = nil,
         notes: String? = nil,
         confidence: SubstituteConfidence = .high) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.notes = notes
        self.confidence = confidence
    }
    
    enum SubstituteConfidence: String, Codable {
        case high = "Recommended"
        case medium = "Good Alternative"
        case low = "Limited Option"
        
        var color: String {
            switch self {
            case .high: return "green"
            case .medium: return "orange"
            case .low: return "yellow"
            }
        }
    }
}

// MARK: - Recipe FODMAP Substitution Analysis

/// Complete FODMAP substitution analysis for a recipe
struct RecipeFODMAPSubstitutions: Identifiable {
    let id: UUID
    let recipeID: UUID
    let recipeTitle: String
    let substitutions: [IngredientSubstitutionGroup]
    let overallFODMAPScore: FODMAPLevel
    let isSafeWithoutSubstitutions: Bool
    
    var hasSubstitutions: Bool {
        !substitutions.isEmpty
    }
    
    var totalHighFODMAPIngredients: Int {
        substitutions.count
    }
    
    init(id: UUID = UUID(),
         recipeID: UUID,
         recipeTitle: String,
         substitutions: [IngredientSubstitutionGroup],
         overallFODMAPScore: FODMAPLevel,
         isSafeWithoutSubstitutions: Bool) {
        self.id = id
        self.recipeID = recipeID
        self.recipeTitle = recipeTitle
        self.substitutions = substitutions
        self.overallFODMAPScore = overallFODMAPScore
        self.isSafeWithoutSubstitutions = isSafeWithoutSubstitutions
    }
}

/// Groups an ingredient with its FODMAP substitution options
struct IngredientSubstitutionGroup: Identifiable {
    let id: UUID
    let originalIngredient: Ingredient
    let substitution: FODMAPSubstitution
    let sectionTitle: String? // Which ingredient section this belongs to
    
    init(id: UUID = UUID(),
         originalIngredient: Ingredient,
         substitution: FODMAPSubstitution,
         sectionTitle: String? = nil) {
        self.id = id
        self.originalIngredient = originalIngredient
        self.substitution = substitution
        self.sectionTitle = sectionTitle
    }
}

// MARK: - FODMAP Substitution Database

/// Comprehensive database of FODMAP substitutions based on Monash University guidelines
class FODMAPSubstitutionDatabase {
    static let shared = FODMAPSubstitutionDatabase()
    
    private init() {}
    
    // MARK: - Substitution Lookup
    
    /// Get substitutions for a specific ingredient
    func getSubstitutions(for ingredientName: String) -> FODMAPSubstitution? {
        let lowercased = ingredientName.lowercased()
        
        // Search through our database
        for substitution in allSubstitutions {
            if lowercased.contains(substitution.originalIngredient.lowercased()) {
                return substitution
            }
        }
        
        return nil
    }
    
    /// Get all available substitutions (for display/reference purposes)
    func getAllSubstitutions() -> [FODMAPSubstitution] {
        return allSubstitutions
    }
    
    /// Analyze a full recipe for FODMAP substitutions
    func analyzeRecipe(_ recipe: RecipeModel) -> RecipeFODMAPSubstitutions {
        var substitutionGroups: [IngredientSubstitutionGroup] = []
        
        // Analyze each ingredient section
        for section in recipe.ingredientSections {
            for ingredient in section.ingredients {
                // Check if this ingredient has FODMAP concerns
                if let substitution = getSubstitutions(for: ingredient.name) {
                    let group = IngredientSubstitutionGroup(
                        originalIngredient: ingredient,
                        substitution: substitution,
                        sectionTitle: section.title
                    )
                    substitutionGroups.append(group)
                }
            }
        }
        
        // Calculate overall score
        let fodmapAnalysis = FODMAPAnalyzer.shared.analyzeRecipe(recipe)
        let isSafe = fodmapAnalysis.isSafe
        let level: FODMAPLevel
        
        if substitutionGroups.isEmpty {
            level = .low
        } else if substitutionGroups.count <= 2 {
            level = .moderate
        } else {
            level = .high
        }
        
        return RecipeFODMAPSubstitutions(
            recipeID: recipe.id,
            recipeTitle: recipe.title,
            substitutions: substitutionGroups,
            overallFODMAPScore: level,
            isSafeWithoutSubstitutions: isSafe
        )
    }
    
    // MARK: - Substitution Database
    
    private var allSubstitutions: [FODMAPSubstitution] {
        [
            // OLIGOSACCHARIDES - Onions & Garlic
            FODMAPSubstitution(
                originalIngredient: "onion",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Green tops of spring onions/scallions only",
                        quantity: "Use green part only",
                        notes: "Discard white bulb part which is high FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Garlic-infused oil",
                        quantity: "2-3 tbsp",
                        notes: "Strain out any garlic solids - FODMAPs don't transfer to oil",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Asafoetida powder (hing)",
                        quantity: "¼ tsp per onion",
                        notes: "Indian spice with onion/garlic flavor, naturally low FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Chives",
                        quantity: "2-3 tbsp chopped",
                        notes: "Low FODMAP in normal portions",
                        confidence: .medium
                    )
                ],
                explanation: "Onions are very high in fructans (oligosaccharides). These substitutes provide similar flavor without FODMAPs.",
                portionNote: "No safe portion - avoid onions completely on low FODMAP diet"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "garlic",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Garlic-infused oil",
                        quantity: "1-2 tbsp",
                        notes: "Make by heating oil with garlic cloves, then strain. FODMAPs stay in solids",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Asafoetida powder (hing)",
                        quantity: "⅛ tsp per clove",
                        notes: "Pungent spice used in Indian cooking, mimics garlic flavor",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Garlic scape (green shoots)",
                        quantity: "Use sparingly",
                        notes: "Lower FODMAP than cloves, but still use small amounts",
                        confidence: .medium
                    )
                ],
                explanation: "Garlic is extremely high in fructans. Infused oil captures flavor without FODMAPs.",
                portionNote: "No safe portion - avoid garlic cloves completely"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "shallot",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Green spring onion tops",
                        quantity: "Equal amount",
                        notes: "Only the green part - white is high FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Chives",
                        quantity: "2-3 tbsp",
                        notes: "Milder flavor but low FODMAP",
                        confidence: .medium
                    )
                ],
                explanation: "Shallots are high in fructans like onions and garlic.",
                portionNote: nil
            ),
            
            FODMAPSubstitution(
                originalIngredient: "leek",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Leek leaves (green tops only)",
                        quantity: "Use full green portion",
                        notes: "Only the dark green leaves are low FODMAP. Discard white and light green bulb",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Spring onion greens",
                        quantity: "Equal amount",
                        notes: "Similar mild flavor",
                        confidence: .high
                    )
                ],
                explanation: "Leek bulbs are high FODMAP, but the dark green leaves are safe.",
                portionNote: "Only use dark green leaves - maximum 1 cup chopped"
            ),
            
            // OLIGOSACCHARIDES - Wheat & Grains
            FODMAPSubstitution(
                originalIngredient: "wheat flour",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Gluten-free flour blend",
                        quantity: "1:1 ratio",
                        notes: "Use rice, potato, tapioca blend. Check ingredients for no chickpea/soy flour",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Rice flour",
                        quantity: "1:1 ratio",
                        notes: "Works well for coating and thickening",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Oat flour",
                        quantity: "1:1 ratio",
                        notes: "Safe up to ½ cup per serving",
                        confidence: .medium
                    ),
                    SubstituteOption(
                        name: "Sourdough spelt flour",
                        quantity: "1:1 ratio",
                        notes: "Only if fermented >4 hours - fermentation breaks down FODMAPs",
                        confidence: .medium
                    )
                ],
                explanation: "Wheat contains fructans. Gluten-free alternatives are naturally low FODMAP.",
                portionNote: nil
            ),
            
            FODMAPSubstitution(
                originalIngredient: "bread",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Gluten-free bread",
                        quantity: "2 slices",
                        notes: "Check ingredients - no chickpea, lentil, or soy flour",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Sourdough spelt bread",
                        quantity: "2 slices",
                        notes: "Must be properly fermented for 4+ hours",
                        confidence: .medium
                    )
                ],
                explanation: "Regular bread contains wheat fructans.",
                portionNote: "2 slices maximum per meal"
            ),
            
            // OLIGOSACCHARIDES - Legumes
            FODMAPSubstitution(
                originalIngredient: "chickpea",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Canned lentils, rinsed",
                        quantity: "½ cup (75g)",
                        notes: "Canned and rinsed lentils are lower FODMAP than dried",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Firm tofu",
                        quantity: "⅔ cup (160g)",
                        notes: "Silken tofu is higher FODMAP - use firm only",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Tempeh",
                        quantity: "100g",
                        notes: "Fermented so lower in FODMAPs than unfermented soy",
                        confidence: .medium
                    )
                ],
                explanation: "Chickpeas are very high in GOS (galacto-oligosaccharides).",
                portionNote: "No safe portion - avoid chickpeas"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "kidney bean",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Canned lentils",
                        quantity: "½ cup, rinsed",
                        notes: "Use canned, not dried. Rinse well",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Firm tofu",
                        quantity: "⅔ cup",
                        notes: "Provides protein without FODMAPs",
                        confidence: .high
                    )
                ],
                explanation: "Kidney beans are high in GOS.",
                portionNote: "No safe portion in one sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "black bean",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Canned lentils",
                        quantity: "½ cup, rinsed well",
                        notes: "Green or brown lentils work best",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Firm tofu",
                        quantity: "⅔ cup",
                        notes: "Good protein substitute",
                        confidence: .high
                    )
                ],
                explanation: "Black beans are high in GOS.",
                portionNote: "No safe portion"
            ),
            
            // OLIGOSACCHARIDES - Nuts
            FODMAPSubstitution(
                originalIngredient: "cashew",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Macadamia nuts",
                        quantity: "Up to 20 nuts",
                        notes: "Low FODMAP and similar creamy texture",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Peanuts",
                        quantity: "32 nuts",
                        notes: "Low FODMAP up to this amount",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Pecans",
                        quantity: "10 pecan halves",
                        notes: "Low FODMAP portion",
                        confidence: .medium
                    )
                ],
                explanation: "Cashews are high in both fructans and GOS.",
                portionNote: "Maximum 10 cashews (high FODMAP above this)"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "pistachio",
                fodmapCategories: [.oligosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Macadamias",
                        quantity: "20 nuts",
                        notes: "Low FODMAP and rich flavor",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Peanuts",
                        quantity: "32 nuts",
                        notes: "Safe low FODMAP portion",
                        confidence: .high
                    )
                ],
                explanation: "Pistachios are high in GOS and fructans.",
                portionNote: "Maximum 15 pistachios (moderate FODMAP)"
            ),
            
            // DISACCHARIDES - Lactose
            FODMAPSubstitution(
                originalIngredient: "milk",
                fodmapCategories: [.disaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Lactose-free milk",
                        quantity: "1:1 ratio",
                        notes: "Lactase enzyme breaks down lactose - tastes like regular milk",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Almond milk",
                        quantity: "Up to 1 cup",
                        notes: "Choose unsweetened, no added inulin. Low FODMAP in moderate amounts",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Rice milk",
                        quantity: "1:1 ratio",
                        notes: "Naturally low FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Macadamia milk",
                        quantity: "1:1 ratio",
                        notes: "Creamy and naturally low FODMAP",
                        confidence: .medium
                    )
                ],
                explanation: "Regular milk contains lactose (a disaccharide). Lactose-free milk is identical except the lactose is pre-digested.",
                portionNote: "Regular milk: maximum ½ cup (125ml) per sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "yogurt",
                fodmapCategories: [.disaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Lactose-free yogurt",
                        quantity: "1:1 ratio",
                        notes: "Available in most supermarkets",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Greek yogurt",
                        quantity: "Up to ⅔ cup (160g)",
                        notes: "Straining process removes some lactose. Better tolerated than regular yogurt",
                        confidence: .medium
                    ),
                    SubstituteOption(
                        name: "Coconut yogurt",
                        quantity: "1:1 ratio",
                        notes: "Check ingredients - no inulin or high FODMAP thickeners",
                        confidence: .medium
                    )
                ],
                explanation: "Yogurt contains lactose. Greek yogurt has less due to straining.",
                portionNote: "Regular yogurt: maximum 2 tbsp per sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "cream",
                fodmapCategories: [.disaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Lactose-free cream",
                        quantity: "1:1 ratio",
                        notes: "Same richness, no lactose",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Coconut cream",
                        quantity: "1:1 ratio",
                        notes: "Rich and creamy. Check no added FODMAPs",
                        confidence: .high
                    )
                ],
                explanation: "Cream contains moderate lactose.",
                portionNote: "Regular cream: up to ¼ cup (60ml) is low FODMAP"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "ice cream",
                fodmapCategories: [.disaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Lactose-free ice cream",
                        quantity: "1:1 ratio",
                        notes: "Many brands now available",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Coconut milk ice cream",
                        quantity: "1 scoop",
                        notes: "Check ingredients for no inulin or high FODMAP sweeteners",
                        confidence: .medium
                    )
                ],
                explanation: "Ice cream is high in lactose.",
                portionNote: "No safe portion of regular ice cream"
            ),
            
            // MONOSACCHARIDES - Excess Fructose
            FODMAPSubstitution(
                originalIngredient: "honey",
                fodmapCategories: [.monosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Maple syrup",
                        quantity: "1:1 ratio",
                        notes: "Pure maple syrup is low FODMAP up to ¼ cup",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Table sugar (sucrose)",
                        quantity: "¾ amount",
                        notes: "Regular white or brown sugar is low FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Rice malt syrup",
                        quantity: "1:1 ratio",
                        notes: "No fructose - made from rice",
                        confidence: .high
                    )
                ],
                explanation: "Honey is very high in excess fructose.",
                portionNote: "Maximum 1 tsp honey per sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "apple",
                fodmapCategories: [.monosaccharides, .polyols],
                substitutes: [
                    SubstituteOption(
                        name: "Banana",
                        quantity: "1 medium (100g)",
                        notes: "Firm, slightly unripe bananas are lowest FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Blueberries",
                        quantity: "¼ cup (40g)",
                        notes: "Low FODMAP and antioxidant-rich",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Strawberries",
                        quantity: "10 medium (140g)",
                        notes: "Low FODMAP in this portion",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Kiwi fruit (green)",
                        quantity: "2 kiwis",
                        notes: "Low FODMAP",
                        confidence: .medium
                    )
                ],
                explanation: "Apples are high in both fructose and sorbitol (polyol).",
                portionNote: "Maximum ⅓ apple (20g) per sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "pear",
                fodmapCategories: [.monosaccharides, .polyols],
                substitutes: [
                    SubstituteOption(
                        name: "Banana",
                        quantity: "1 medium",
                        notes: "Similar soft texture when ripe",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Dragon fruit",
                        quantity: "1 cup (150g)",
                        notes: "Low FODMAP and sweet",
                        confidence: .medium
                    )
                ],
                explanation: "Pears are very high in fructose and sorbitol.",
                portionNote: "Maximum 30g per sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "mango",
                fodmapCategories: [.monosaccharides],
                substitutes: [
                    SubstituteOption(
                        name: "Pineapple",
                        quantity: "1 cup (140g)",
                        notes: "Low FODMAP and tropical flavor",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Papaya",
                        quantity: "1 cup (140g)",
                        notes: "Low FODMAP in this portion",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Cantaloupe",
                        quantity: "½ cup (75g)",
                        notes: "Sweet and refreshing",
                        confidence: .medium
                    )
                ],
                explanation: "Mango is high in excess fructose.",
                portionNote: "Maximum ½ cup (70g) per sitting"
            ),
            
            // POLYOLS
            FODMAPSubstitution(
                originalIngredient: "mushroom",
                fodmapCategories: [.polyols],
                substitutes: [
                    SubstituteOption(
                        name: "Oyster mushrooms",
                        quantity: "⅓ cup (33g)",
                        notes: "Lower in polyols than button/portobello mushrooms",
                        confidence: .medium
                    ),
                    SubstituteOption(
                        name: "Eggplant",
                        quantity: "1 cup",
                        notes: "Similar meaty texture when cooked",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Zucchini",
                        quantity: "⅔ cup (65g)",
                        notes: "Low FODMAP, mild flavor",
                        confidence: .high
                    )
                ],
                explanation: "Most mushrooms are high in mannitol (a polyol).",
                portionNote: "Maximum 1 small button mushroom (15g)"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "cauliflower",
                fodmapCategories: [.polyols],
                substitutes: [
                    SubstituteOption(
                        name: "Broccoli heads only",
                        quantity: "⅔ cup (75g)",
                        notes: "Broccoli heads (not stems) are low FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Green beans",
                        quantity: "15 beans (75g)",
                        notes: "Low FODMAP and similar texture when cooked",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Bok choy",
                        quantity: "1 cup",
                        notes: "Low FODMAP leafy green",
                        confidence: .medium
                    )
                ],
                explanation: "Cauliflower is high in mannitol.",
                portionNote: "Maximum ⅛ head (60g) per sitting"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "avocado",
                fodmapCategories: [.polyols],
                substitutes: [
                    SubstituteOption(
                        name: "Small portion of avocado",
                        quantity: "⅛ avocado (20g)",
                        notes: "This portion is low FODMAP - measure carefully",
                        confidence: .high
                    )
                ],
                explanation: "Avocado is high in sorbitol, but small portions are safe.",
                portionNote: "Maximum ⅛ avocado (20g) - larger portions are high FODMAP"
            ),
            
            FODMAPSubstitution(
                originalIngredient: "sweet corn",
                fodmapCategories: [.polyols],
                substitutes: [
                    SubstituteOption(
                        name: "Small sweet corn portion",
                        quantity: "½ cob or ⅓ cup kernels",
                        notes: "This amount is low FODMAP",
                        confidence: .high
                    ),
                    SubstituteOption(
                        name: "Green beans",
                        quantity: "15 beans",
                        notes: "Similar sweet vegetable",
                        confidence: .medium
                    )
                ],
                explanation: "Large portions of corn are high in sorbitol.",
                portionNote: "Maximum ½ cob - larger servings are high FODMAP"
            ),
        ]
    }
}
