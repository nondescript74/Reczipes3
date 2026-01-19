//
//  DiagnosticManager.swift
//  Reczipes2
//
//  Created on 1/19/26.
//  Manages diagnostic events and provides user-facing diagnostic information
//

import Foundation
import SwiftUI
import Combine

/// Manages diagnostic events throughout the app lifecycle
@MainActor
class DiagnosticManager: ObservableObject {
    static let shared = DiagnosticManager()
    
    /// All diagnostic events (persisted)
    @Published private(set) var events: [DiagnosticEvent] = []
    
    /// Maximum number of events to keep in memory
    private let maxEvents = 500
    
    /// UserDefaults key for persistence
    private let eventsKey = "com.reczipes.diagnosticEvents"
    
    private init() {
        loadEvents()
        
        // Log initialization
        logDiagnostic(.info, .general, "Diagnostic Manager Initialized", 
                     message: "Ready to track app diagnostics")
    }
    
    // MARK: - Event Management
    
    /// Add a new diagnostic event
    func addEvent(_ event: DiagnosticEvent) {
        events.insert(event, at: 0) // Most recent first
        
        // Trim to max events
        if events.count > maxEvents {
            events = Array(events.prefix(maxEvents))
        }
        
        // Also log to the traditional logger for technical debugging
        let technicalMessage = "\(event.title): \(event.message)"
        switch event.severity {
        case .info:
            DiagnosticLogger.shared.info(technicalMessage, category: event.category.rawValue.lowercased())
        case .warning:
            DiagnosticLogger.shared.warning(technicalMessage, category: event.category.rawValue.lowercased())
        case .error:
            DiagnosticLogger.shared.error(technicalMessage, category: event.category.rawValue.lowercased())
        case .critical:
            DiagnosticLogger.shared.critical(technicalMessage, category: event.category.rawValue.lowercased())
        }
        
        saveEvents()
    }
    
    /// Mark an event as resolved
    func markResolved(eventId: UUID) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            events[index] = events[index].resolved()
            saveEvents()
        }
    }
    
    /// Clear all events
    func clearAllEvents() {
        events.removeAll()
        saveEvents()
        
        addEvent(DiagnosticEvent(
            severity: .info,
            category: .general,
            title: "Diagnostics Cleared",
            message: "All diagnostic events have been cleared."
        ))
    }
    
    /// Clear resolved events
    func clearResolvedEvents() {
        let beforeCount = events.count
        events.removeAll { $0.isResolved }
        saveEvents()
        
        if beforeCount > events.count {
            addEvent(DiagnosticEvent(
                severity: .info,
                category: .general,
                title: "Resolved Events Cleared",
                message: "Cleared \(beforeCount - events.count) resolved diagnostic events."
            ))
        }
    }
    
    // MARK: - Filtering
    
    /// Get events filtered by severity
    func events(withSeverity severity: DiagnosticSeverity) -> [DiagnosticEvent] {
        events.filter { $0.severity == severity }
    }
    
    /// Get events filtered by category
    func events(inCategory category: DiagnosticCategory) -> [DiagnosticEvent] {
        events.filter { $0.category == category }
    }
    
    /// Get unresolved events only
    var unresolvedEvents: [DiagnosticEvent] {
        events.filter { !$0.isResolved }
    }
    
    /// Get critical and error events only
    var failureEvents: [DiagnosticEvent] {
        events.filter { 
            $0.severity == .critical || $0.severity == .error 
        }
    }
    
    /// Get unresolved failures
    var unresolvedFailures: [DiagnosticEvent] {
        events.filter { 
            !$0.isResolved && ($0.severity == .critical || $0.severity == .error)
        }
    }
    
    // MARK: - Statistics
    
    var eventCounts: [DiagnosticSeverity: Int] {
        Dictionary(grouping: events, by: { $0.severity })
            .mapValues { $0.count }
    }
    
    var categoryCounts: [DiagnosticCategory: Int] {
        Dictionary(grouping: events, by: { $0.category })
            .mapValues { $0.count }
    }
    
    // MARK: - Persistence
    
    private func saveEvents() {
        do {
            let data = try JSONEncoder().encode(events)
            UserDefaults.standard.set(data, forKey: eventsKey)
        } catch {
            DiagnosticLogger.shared.error("Failed to save diagnostic events: \(error)", category: "general")
        }
    }
    
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: eventsKey) else {
            return
        }
        
        do {
            events = try JSONDecoder().decode([DiagnosticEvent].self, from: data)
        } catch {
            DiagnosticLogger.shared.error("Failed to load diagnostic events: \(error)", category: "general")
            events = []
        }
    }
    
    // MARK: - Export
    
    /// Export all events as formatted text
    func exportAsText() -> String {
        var output = """
        Reczipes Diagnostic Report
        Generated: \(Date().formatted(date: .long, time: .standard))
        
        ═══════════════════════════════════════════════════════════════
        
        """
        
        let counts = eventCounts
        output += """
        SUMMARY
        ───────
        Total Events: \(events.count)
        Critical: \(counts[.critical] ?? 0)
        Errors: \(counts[.error] ?? 0)
        Warnings: \(counts[.warning] ?? 0)
        Info: \(counts[.info] ?? 0)
        
        ═══════════════════════════════════════════════════════════════
        
        """
        
        for event in events {
            output += """
            
            [\(event.severity.rawValue.uppercased())] \(event.title)
            Time: \(event.timestamp.formatted(date: .abbreviated, time: .standard))
            Category: \(event.category.rawValue)
            
            \(event.message)
            
            """
            
            if let technical = event.technicalDetails {
                output += """
                Technical Details:
                \(technical)
                
                """
            }
            
            if !event.suggestedActions.isEmpty {
                output += "Suggested Actions:\n"
                for action in event.suggestedActions {
                    output += "  • \(action.title): \(action.description)\n"
                }
                output += "\n"
            }
            
            output += "───────────────────────────────────────────────────────────────\n"
        }
        
        return output
    }
    
    /// Export events as JSON
    func exportAsJSON() -> Data? {
        try? JSONEncoder().encode(events)
    }
}

// MARK: - Convenience Logging Functions

extension DiagnosticManager {
    
    /// Log a diagnostic event with common parameters
    func logDiagnostic(
        _ severity: DiagnosticSeverity,
        _ category: DiagnosticCategory,
        _ title: String,
        message: String,
        technicalDetails: String? = nil,
        suggestedActions: [DiagnosticAction] = []
    ) {
        let event = DiagnosticEvent(
            severity: severity,
            category: category,
            title: title,
            message: message,
            technicalDetails: technicalDetails,
            suggestedActions: suggestedActions
        )
        addEvent(event)
    }
}

// MARK: - Global Convenience Functions

/// Log a user-facing diagnostic event
func logUserDiagnostic(
    _ severity: DiagnosticSeverity,
    category: DiagnosticCategory = .general,
    title: String,
    message: String,
    technicalDetails: String? = nil,
    suggestedActions: [DiagnosticAction] = []
) {
    Task { @MainActor in
        DiagnosticManager.shared.logDiagnostic(
            severity,
            category,
            title,
            message: message,
            technicalDetails: technicalDetails,
            suggestedActions: suggestedActions
        )
    }
}
