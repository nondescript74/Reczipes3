//
//  UserDiabeticSettings.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//


import Foundation
import SwiftUI
import Combine

// MARK: - Diabetic User Settings

/// User preferences for diabetic-friendly analysis functionality
class UserDiabeticSettings: ObservableObject {
    static let shared = UserDiabeticSettings()
    
    @AppStorage("diabeticEnabled") var isDiabeticEnabled: Bool = false
    @AppStorage("diabeticShowGlycemicLoad") var showGlycemicLoad: Bool = true
    @AppStorage("diabeticAutoExpandGuidance") var autoExpandGuidance: Bool = false
    @AppStorage("diabeticHighlightHighGI") var highlightHighGI: Bool = true
    
    private init() {}
    
    /// Enable diabetic-friendly analysis mode
    func enableDiabeticMode() {
        isDiabeticEnabled = true
    }
    
    /// Disable diabetic-friendly analysis mode
    func disableDiabeticMode() {
        isDiabeticEnabled = false
    }
}