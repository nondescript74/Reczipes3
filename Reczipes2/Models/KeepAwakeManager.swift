//
//  KeepAwakeManager.swift
//  reczipes2-imageextract
//
//  Created for dual-recipe cooking mode
//

import SwiftUI
import Observation

@Observable
final class KeepAwakeManager {
    var isEnabled: Bool = false {
        didSet {
            updateIdleTimer()
        }
    }
    
    init() {}
    
    private func updateIdleTimer() {
        Task { @MainActor in
            UIApplication.shared.isIdleTimerDisabled = isEnabled
        }
    }
    
    func enable() {
        isEnabled = true
    }
    
    func disable() {
        isEnabled = false
    }
    
    deinit {
        // Ensure we re-enable idle timer when manager is deallocated
        Task { @MainActor in
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}
