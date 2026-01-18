//
//  LoggingHelpers.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation
import os.log

/// Cached bundle identifier to avoid repeated I/O operations
private let subsystem = Bundle.main.bundleIdentifier ?? "com.app.reczipes"

/// Global logging functions for consistent logging throughout the app
func logInfo(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.info("\(message)")
}

func logError(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.error("\(message)")
}

func logDebug(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.debug("\(message)")
}

func logWarning(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: subsystem, category: category)
    logger.warning("\(message)")
}
