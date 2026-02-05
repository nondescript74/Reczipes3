//
//  AppClipLogging.swift
//  Reczipes2Clip
//
//  Lightweight logging shims for the App Clip target.
//
//  The main app's LoggingHelpers.swift defines global functions like logInfo(),
//  logError(), etc. that forward to DiagnosticLogger (a file-backed singleton
//  the App Clip doesn't include).  This file provides the exact same function
//  signatures so that shared files — ClaudeAPIClient, WebRecipeExtractor,
//  ImagePreprocessor — compile unchanged in the App Clip target.
//
//  All output goes to OSLog (visible in Xcode console and Console.app).
//  No files, no singletons, no SwiftData.
//
//  TARGET MEMBERSHIP: Reczipes2Clip only
//
//  ⚠️  Do NOT add this file to the main Reczipes2 target — it would conflict
//      with LoggingHelpers.swift.
//

import Foundation
import os.log

// MARK: - OSLog-backed global functions (match LoggingHelpers.swift signatures)

private let clipSubsystem = Bundle.main.bundleIdentifier ?? "com.headydiscy.reczipes.Clip"

func logInfo(_ message: String, category: String = "general") {
    Logger(subsystem: clipSubsystem, category: category).info("\(message)")
}

func logError(_ message: String, category: String = "general") {
    Logger(subsystem: clipSubsystem, category: category).error("\(message)")
}

func logDebug(_ message: String, category: String = "general") {
    Logger(subsystem: clipSubsystem, category: category).debug("\(message)")
}

func logWarning(_ message: String, category: String = "general") {
    Logger(subsystem: clipSubsystem, category: category).warning("\(message)")
}

// MARK: - App-Clip-specific convenience logger

/// Minimal log helper used directly by App Clip code (Reczipes2ClipApp,
/// AppClipContentView, AppClipAPIKeyHelper).  Keeps call sites short and
/// makes it obvious at a glance which log lines come from the clip.
enum ClipLogLevel { case info, warning, error }

func clipLog(_ message: String, level: ClipLogLevel = .info) {
    let logger = Logger(subsystem: clipSubsystem, category: "app-clip")
    switch level {
    case .info:    logger.info("[Clip] \(message)")
    case .warning: logger.warning("[Clip] \(message)")
    case .error:   logger.error("[Clip] \(message)")
    }
}
