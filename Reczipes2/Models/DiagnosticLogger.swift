//
//  DiagnosticLogger.swift
//  Reczipes
//
//  Created on December 19, 2025.
//

import Foundation
import OSLog

/// Centralized logging system that writes to both OSLog and a diagnostic file
@preconcurrency
final class DiagnosticLogger: @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = DiagnosticLogger()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private let logFileName = "reczipes_diagnostics.log"
    private nonisolated(unsafe) var logFileURL: URL?
    private let logQueue = DispatchQueue(label: "com.reczipes.diagnosticlogger", qos: .utility)
    
    // OSLog subsystems for different areas of the app
    private let subsystems: [String: Logger] = [
        "general": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "general"),
        "allergen": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "allergen"),
        "fodmap": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "fodmap"),
        "recipe": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "recipe"),
        "network": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "network"),
        "storage": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "storage"),
        "ui": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "ui"),
        "extraction": Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "extraction")
    ]
    
    // MARK: - Initialization
    
    private init() {
        setupLogFile()
        logInitialization()
    }
    
    private func setupLogFile() {
        do {
            // Get Documents directory
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            logFileURL = documentsURL.appendingPathComponent(logFileName)
            
            // Create file if it doesn't exist
            if let url = logFileURL, !fileManager.fileExists(atPath: url.path) {
                fileManager.createFile(atPath: url.path, contents: nil)
                writeToFile("=== Reczipes Diagnostic Log Started ===\n")
                writeToFile("Date: \(Date().formatted())\n")
                writeToFile("=====================================\n\n")
            }
        } catch {
            // Fallback to OSLog only if file setup fails
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.reczipes", category: "logger")
                .error("Failed to setup log file: \(error.localizedDescription)")
        }
    }
    
    private func logInitialization() {
        info("DiagnosticLogger initialized", category: "general")
        if let url = logFileURL {
            info("Log file location: \(url.path)", category: "general")
        }
    }
    
    // MARK: - Public Logging Methods
    
    /// Log a debug message
    nonisolated func debug(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// Log an info message
    nonisolated func info(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    nonisolated func warning(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .default, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message
    nonisolated func error(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// Log a critical/fault message
    nonisolated func critical(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Private Logging Implementation
    
    private nonisolated func log(
        _ message: String,
        level: OSLogType,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = (file as NSString).lastPathComponent
        let timestamp = Date()
        let formattedTimestamp = timestamp.formatted(date: .numeric, time: .standard)
        
        // Get appropriate logger
        let logger = subsystems[category] ?? subsystems["general"]!
        
        // Log to OSLog
        switch level {
        case .debug:
            logger.debug("[\(fileName):\(line)] \(function) - \(message)")
        case .info:
            logger.info("[\(fileName):\(line)] \(function) - \(message)")
        case .error:
            logger.error("[\(fileName):\(line)] \(function) - \(message)")
        case .fault:
            logger.critical("[\(fileName):\(line)] \(function) - \(message)")
        default:
            logger.notice("[\(fileName):\(line)] \(function) - \(message)")
        }
        
        // Format for file
        let levelString = logLevelString(level)
        let fileLogMessage = "[\(formattedTimestamp)] [\(levelString)] [\(category)] [\(fileName):\(line)] \(function)\n  → \(message)\n"
        
        // Write to file
        writeToFile(fileLogMessage)
    }
    
    private nonisolated func logLevelString(_ level: OSLogType) -> String {
        switch level {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .error:
            return "ERROR"
        case .fault:
            return "CRITICAL"
        case .default:
            return "WARNING"
        default:
            return "NOTICE"
        }
    }
    
    private nonisolated func writeToFile(_ message: String) {
        guard let url = logFileURL else { return }
        
        logQueue.async {
            do {
                let fileHandle = try FileHandle(forWritingTo: url)
                defer { try? fileHandle.close() }
                
                fileHandle.seekToEndOfFile()
                if let data = message.data(using: .utf8) {
                    fileHandle.write(data)
                }
            } catch {
                // If file handle fails, try appending
                if let data = message.data(using: .utf8) {
                    try? data.append(fileOrURL: url)
                }
            }
        }
    }
    
    // MARK: - Log Management
    
    /// Get the current log file URL
    nonisolated func getLogFileURL() -> URL? {
        return logFileURL
    }
    
    /// Get the contents of the log file
    nonisolated func getLogContents() -> String {
        guard let url = logFileURL else {
            return "Log file not available"
        }
        
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            return "Error reading log file: \(error.localizedDescription)"
        }
    }
    
    /// Clear the log file
    nonisolated func clearLog() {
        guard let url = logFileURL else { return }
        
        logQueue.async { [weak self] in
            do {
                // Clear the file
                try "".write(to: url, atomically: true, encoding: .utf8)
                
                // Write new header
                let header = """
                === Reczipes Diagnostic Log Cleared ===
                Date: \(Date().formatted())
                =====================================
                
                
                """
                try header.write(to: url, atomically: false, encoding: .utf8)
                
                self?.info("Diagnostic log cleared by user", category: "general")
            } catch {
                self?.error("Failed to clear log file: \(error.localizedDescription)", category: "general")
            }
        }
    }
    
    /// Get the size of the log file in bytes
    nonisolated func getLogFileSize() -> Int64 {
        guard let url = logFileURL else { return 0 }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Get formatted file size (e.g., "1.5 MB")
    nonisolated func getFormattedLogFileSize() -> String {
        let bytes = getLogFileSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Data Extension for File Appending

private extension Data {
    func append(fileOrURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileOrURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: fileOrURL, options: .atomic)
        }
    }
}

// MARK: - Convenience Global Functions

/// Global convenience function for debug logging
func logDebug(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
    DiagnosticLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for info logging
func logInfo(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
    DiagnosticLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for warning logging
func logWarning(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
    DiagnosticLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for error logging
func logError(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
    DiagnosticLogger.shared.error(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for critical logging
func logCritical(_ message: String, category: String = "general", file: String = #file, function: String = #function, line: Int = #line) {
    DiagnosticLogger.shared.critical(message, category: category, file: file, function: function, line: line)
}
