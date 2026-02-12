# Logging Settings Implementation Guide

## Overview

A comprehensive, user-configurable logging system has been implemented to allow users to control logging verbosity and improve app performance. The system provides granular control over what gets logged, where it gets logged, and at what level.

## Key Features

### 1. Configurable Logging Levels
Users can choose from five logging levels, each with different performance impacts:

- **Off**: No logging - best performance (no overhead)
- **Errors Only**: Only critical errors - minimal impact
- **Warnings & Errors**: Warnings and errors - slight impact
- **Info, Warnings & Errors**: General information - moderate impact
- **All (Debug Mode)**: Everything including debug - performance impact

### 2. Category-Specific Control
Users can enable/disable logging for specific categories:

- **General**: General app operations
- **Allergen Detection**: Allergen detection and matching
- **FODMAP Analysis**: FODMAP analysis
- **Recipe Operations**: Recipe CRUD operations
- **Network Requests**: API calls and network activity
- **Data Storage**: Database and file operations
- **UI Events**: User interface events
- **Recipe Extraction**: Recipe extraction from text/images
- **Image Processing**: Image processing and compression
- **CloudKit Sync**: iCloud synchronization
- **Analytics**: Usage analytics and metrics

### 3. File Logging Toggle
Users can enable/disable writing logs to a diagnostic file, with options to:
- View the log file contents
- Share the log file
- Clear the log file
- See the current file size

### 4. Quick Presets
Three preset configurations for common scenarios:

- **Disable All Logging**: Maximum performance (all logging off)
- **Balanced (Recommended)**: Errors only + essential categories (general, recipe, cloudkit)
- **Enable Full Logging**: Debug mode for troubleshooting

## Implementation Details

### Files Created

1. **Reczipes2/Models/LoggingSettings.swift**
   - Main settings model with @Observable support
   - Thread-safe LoggingHelper for non-MainActor contexts
   - Persistent storage via UserDefaults
   - Default: Errors only + essential categories

2. **Reczipes2/Views/LoggingSettingsView.swift**
   - User interface for logging configuration
   - Performance impact indicator
   - Category toggles with descriptions
   - Log file management tools
   - Quick preset buttons

### Files Modified

1. **Reczipes2/Models/DiagnosticLogger.swift**
   - Updated to respect user logging settings
   - Thread-safe access via LoggingHelper
   - Filters logs by level and category before writing

2. **Reczipes2/Views/SettingsView.swift**
   - Added "Logging Settings" entry in Diagnostics section
   - Added LoggingStatusBadge to show current logging level

## Architecture

### Thread Safety

The implementation handles Swift concurrency correctly:

- **LoggingSettings**: Uses @Observable for UI binding (MainActor-isolated)
- **LoggingHelper**: Thread-safe enum with nonisolated static methods
- **DiagnosticLogger**: Calls thread-safe LoggingHelper methods from nonisolated contexts

This allows logging to work from any thread without actor isolation issues.

### Performance Optimization

Logging checks are performed before expensive operations:

1. **Level Check**: Returns early if logging level is too low
2. **Category Check**: Returns early if category is disabled
3. **Message Formatting**: Only happens if logging will occur
4. **File Writing**: Only happens if file logging is enabled

With logging off, the overhead is minimal (just two boolean checks reading from UserDefaults).

## User Guide

### Accessing Logging Settings

1. Open the app
2. Navigate to Settings
3. Scroll to "Diagnostics" section
4. Tap "Logging Settings"

### Improving Performance

If experiencing performance issues during recipe extraction or image processing:

1. Go to Logging Settings
2. Tap "Disable All Logging" preset
3. Or manually select "Off" as the logging level

### Troubleshooting / Reporting Issues

When reporting bugs or issues:

1. Go to Logging Settings
2. Tap "Enable Full Logging" preset
3. Reproduce the issue
4. Return to Logging Settings
5. Tap "Share Log File"
6. Include the log file with your bug report

### Customizing Logging

For focused debugging:

1. Choose appropriate logging level (e.g., "Info" for moderate detail)
2. Enable only relevant categories:
   - For extraction issues: Enable "Recipe Extraction", "Network", "Image Processing"
   - For sync issues: Enable "CloudKit Sync", "Data Storage"
   - For UI issues: Enable "UI Events", "General"

## Default Behavior

Out of the box, the app uses a balanced configuration:

- **Level**: Errors Only
- **Categories**: General, Recipe Operations, CloudKit Sync
- **File Logging**: Enabled

This provides essential diagnostic information with minimal performance impact.

## Performance Impact

Based on the logging level chosen:

| Level | Impact | Use Case |
|-------|--------|----------|
| Off | None (0%) | Maximum performance |
| Errors Only | Minimal (~1%) | Production use |
| Warnings & Errors | Slight (~2-3%) | Normal development |
| Info, Warnings & Errors | Moderate (~5-10%) | Debugging |
| All (Debug Mode) | Significant (~15-20%) | Deep troubleshooting |

Note: Impact percentages are estimates and vary based on app usage patterns.

## Technical Notes

### UserDefaults Keys

- `com.reczipes.logging.level`: Current logging level
- `com.reczipes.logging.fileLogging`: Whether file logging is enabled
- `com.reczipes.logging.categories`: Array of enabled category names

### Thread-Safe Access Pattern

```swift
// From any thread (including nonisolated contexts)
if LoggingHelper.shouldLog(category: "network") {
    if LoggingHelper.shouldLog(level: .debug) {
        // Perform logging
    }
}
```

### UI Binding Pattern

```swift
// In SwiftUI views
@State private var settings = LoggingSettings.shared

// Bind to UI
Toggle("Enable Logging", isOn: $settings.enableFileLogging)
Picker("Level", selection: $settings.loggingLevel) { ... }
```

## Future Enhancements

Potential improvements:

1. **Remote Logging**: Send logs to a remote server for analysis
2. **Log Rotation**: Automatically manage log file size
3. **Export Formats**: Export logs as JSON or CSV
4. **Performance Metrics**: Track actual performance impact of logging
5. **Category Templates**: Saved category combinations for different scenarios

## Summary

This implementation provides users with full control over app logging, allowing them to:

- **Maximize performance** by disabling unnecessary logging
- **Troubleshoot issues** by enabling detailed logging
- **Customize logging** to focus on specific areas of interest
- **Share diagnostic information** easily when reporting bugs

The system is thread-safe, performance-optimized, and follows Apple's best practices for iOS logging.
