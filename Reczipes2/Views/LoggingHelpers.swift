//
//  LoggingHelpers.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//  Updated 1/19/26 - Enhanced with user-facing diagnostics
//

import Foundation
import os.log

/// Cached bundle identifier to avoid repeated I/O operations
private let subsystem = Bundle.main.bundleIdentifier ?? "com.app.reczipes"

/// Global logging functions for consistent logging throughout the app
/// NOTE: These log to OSLog for technical debugging.
/// For user-facing diagnostics, use logUserDiagnostic() or DiagnosticManager.shared.addEvent()
func logInfo(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.info("\(message)")
    
    // Also log to diagnostic file for comprehensive debugging
    DiagnosticLogger.shared.info(message, category: category)
}

func logError(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.error("\(message)")
    
    // Also log to diagnostic file
    DiagnosticLogger.shared.error(message, category: category)
}

func logDebug(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.debug("\(message)")
    
    // Also log to diagnostic file
    DiagnosticLogger.shared.debug(message, category: category)
}

func logWarning(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.warning("\(message)")
    
    // Also log to diagnostic file
    DiagnosticLogger.shared.warning(message, category: category)
}
/// Enhanced logging with automatic user-facing diagnostic creation
/// Use this instead of logError/logWarning when the user should be informed
func logUserError(
    _ message: String,
    category: String = "general",
    userTitle: String? = nil,
    userMessage: String? = nil,
    suggestedActions: [DiagnosticAction] = []
) {
    // Log technically
    logError(message, category: category)
    
    // Create user-facing diagnostic
    let diagnosticCategory = DiagnosticCategory(rawValue: category.capitalized) ?? .general
    
    Task { @MainActor in
        DiagnosticManager.shared.logDiagnostic(
            .error,
            diagnosticCategory,
            userTitle ?? "An Error Occurred",
            message: userMessage ?? message,
            technicalDetails: message,
            suggestedActions: suggestedActions
        )
    }
}

/// Enhanced warning logging with user-facing diagnostic
func logUserWarning(
    _ message: String,
    category: String = "general",
    userTitle: String? = nil,
    userMessage: String? = nil,
    suggestedActions: [DiagnosticAction] = []
) {
    // Log technically
    logWarning(message, category: category)
    
    // Create user-facing diagnostic
    let diagnosticCategory = DiagnosticCategory(rawValue: category.capitalized) ?? .general
    
    Task { @MainActor in
        DiagnosticManager.shared.logDiagnostic(
            .warning,
            diagnosticCategory,
            userTitle ?? "Warning",
            message: userMessage ?? message,
            technicalDetails: message,
            suggestedActions: suggestedActions
        )
    }
}

