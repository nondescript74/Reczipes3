//
//  LoggingHelpers.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/28/25.
//

import Foundation
import os.log

/// Global logging functions for consistent logging throughout the app
func logInfo(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.reczipes", category: category)
    logger.info("\(message)")
}

func logError(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.reczipes", category: category)
    logger.error("\(message)")
}

func logDebug(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.reczipes", category: category)
    logger.debug("\(message)")
}

func logWarning(_ message: String, category: String = "general") {
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.app.reczipes", category: category)
    logger.warning("\(message)")
}
