//
//  DiabeticInfo.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/24/25.
//
import SwiftUI
import SwiftData

// MARK: - Main Model

struct DiabeticInfo: Codable, Identifiable {
    let id: UUID
    let recipeId: UUID
    let lastUpdated: Date
    
    // Glycemic data
    let estimatedGlycemicLoad: GlycemicLoad?
    let glycemicImpactFactors: [GlycemicFactor]
    
    // Nutritional focus
    let carbCount: CarbInfo
    let fiberContent: FiberInfo
    let sugarBreakdown: SugarBreakdown
    
    // Guidance
    let diabeticGuidance: [GuidanceItem]
    let portionRecommendations: PortionGuidance?
    let substitutionSuggestions: [IngredientSubstitution]
    
    // Source verification
    let sources: [VerifiedSource]
    let consensusLevel: ConsensusLevel
}

// MARK: - Consensus Level

enum ConsensusLevel: String, Codable {
    case strongConsensus      // 3+ sources agree
    case moderateConsensus    // 2 sources agree
    case limitedEvidence      // 1 source or conflicting
    case needsReview          // Outdated or no sources
}
// MARK: - Glycemic Data

struct GlycemicLoad: Codable {
    let value: Double
    let explanation: String?
    
    init(value: Double, explanation: String? = nil) {
        self.value = value
        self.explanation = explanation
    }
}

struct GlycemicFactor: Codable, Identifiable {
    let id: UUID
    let ingredient: String
    let glycemicIndex: Int
    let impact: ImpactLevel
    let explanation: String
    
    enum ImpactLevel: String, Codable {
        case low
        case medium
        case high
    }
    
    init(id: UUID = UUID(), ingredient: String, glycemicIndex: Int, impact: ImpactLevel, explanation: String) {
        self.id = id
        self.ingredient = ingredient
        self.glycemicIndex = glycemicIndex
        self.impact = impact
        self.explanation = explanation
    }
}

// MARK: - Nutritional Info

struct CarbInfo: Codable {
    let totalCarbs: Double
    let netCarbs: Double
    let fiber: Double
    
    init(totalCarbs: Double, netCarbs: Double, fiber: Double) {
        self.totalCarbs = totalCarbs
        self.netCarbs = netCarbs
        self.fiber = fiber
    }
}

struct FiberInfo: Codable {
    let total: Double
    let soluble: Double?
    let insoluble: Double?
    
    init(total: Double, soluble: Double? = nil, insoluble: Double? = nil) {
        self.total = total
        self.soluble = soluble
        self.insoluble = insoluble
    }
}

struct SugarBreakdown: Codable {
    let total: Double
    let added: Double?
    let natural: Double?
    
    init(total: Double, added: Double? = nil, natural: Double? = nil) {
        self.total = total
        self.added = added
        self.natural = natural
    }
}

// MARK: - Guidance

struct GuidanceItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let detailedExplanation: String
    let icon: String
    let color: CodableColor
    let practicalTips: [String]?
    
    init(id: UUID = UUID(), title: String, summary: String, detailedExplanation: String, icon: String, color: Color, practicalTips: [String]? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.detailedExplanation = detailedExplanation
        self.icon = icon
        self.color = CodableColor(color: color)
        self.practicalTips = practicalTips
    }
    
    var swiftUIColor: Color {
        color.color
    }
}

// Helper to make Color codable
struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        // Note: This is a simplified version. In production, you'd want proper color extraction
        // For now, we'll use named colors
        self.red = 0
        self.green = 0
        self.blue = 1
        self.opacity = 1
    }
    
    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct PortionGuidance: Codable {
    let recommendedServing: String
    let servingSize: String?
    let explanation: String
    
    init(recommendedServing: String, servingSize: String? = nil, explanation: String) {
        self.recommendedServing = recommendedServing
        self.servingSize = servingSize
        self.explanation = explanation
    }
}

// MARK: - Substitutions

struct IngredientSubstitution: Codable, Identifiable {
    let id: UUID
    let originalIngredient: String
    let substitute: String
    let reason: String?
    let nutritionalImprovement: String?
    
    init(id: UUID = UUID(), originalIngredient: String, substitute: String, reason: String? = nil, nutritionalImprovement: String? = nil) {
        self.id = id
        self.originalIngredient = originalIngredient
        self.substitute = substitute
        self.reason = reason
        self.nutritionalImprovement = nutritionalImprovement
    }
}

// MARK: - Source Verification

struct VerifiedSource: Codable, Identifiable {
    let id: UUID
    let title: String
    let organization: String?
    let url: URL?
    let publishDate: Date?
    let credibilityScore: SourceCredibility?
    
    init(id: UUID = UUID(), title: String, organization: String? = nil, url: URL? = nil, publishDate: Date? = nil, credibilityScore: SourceCredibility? = nil) {
        self.id = id
        self.title = title
        self.organization = organization
        self.url = url
        self.publishDate = publishDate
        self.credibilityScore = credibilityScore
    }
}

enum SourceCredibility: String, Codable {
    case high       // ADA, Mayo Clinic, CDC, NIH
    case medium     // University hospitals, peer-reviewed journals
    case low        // General health websites
}

