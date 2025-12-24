//
//  CachedDiabeticAnalysis.swift
//  Reczipes2
//
//  Persistent cache for diabetic analysis results
//  Created by Zahirudeen Premji on 12/24/25.
//

import Foundation
import SwiftData

@Model
final class CachedDiabeticAnalysis {
    @Attribute(.unique) var recipeId: UUID
    var analysisData: Data // Encoded DiabeticInfo
    var cachedAt: Date
    
    init(recipeId: UUID, analysisData: Data, cachedAt: Date = Date()) {
        self.recipeId = recipeId
        self.analysisData = analysisData
        self.cachedAt = cachedAt
    }
    
    /// Check if this cached analysis is still valid (30 days per guidelines)
    var isStale: Bool {
        let expirationInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days in seconds
        return Date().timeIntervalSince(cachedAt) > expirationInterval
    }
    
    /// Decode the stored analysis
    @MainActor func decodedAnalysis() throws -> DiabeticInfo {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DiabeticInfo.self, from: analysisData)
    }
    
    /// Create a cached analysis from DiabeticInfo
    @MainActor static func create(from info: DiabeticInfo, recipeId: UUID) throws -> CachedDiabeticAnalysis {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(info)
        return CachedDiabeticAnalysis(recipeId: recipeId, analysisData: data)
    }
}
