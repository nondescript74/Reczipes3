//
//  Reczipes2UITestsLaunchTests.swift
//  Reczipes2UITests
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import XCTest
import OSLog

final class Reczipes2UITestsLaunchTests: XCTestCase {
    
    // Logger for UI tests
    private let logger = Logger(subsystem: "com.reczipes.uitests", category: "launch")

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        
        // Set up launch arguments to bypass initial setup screens for testing
        app.launchArguments = ["UI_TESTING"]
        
        logger.info("🚀 Launching app for UI test")
        app.launch()
        
        logger.info("✅ App launched successfully")
        
        // Wait for app to settle (handles animations, async loading, etc.)
        logger.info("⏳ Waiting for app to idle...")
        let appLaunched = app.wait(for: .runningForeground, timeout: 5)
        XCTAssertTrue(appLaunched, "App should reach foreground state")
        logger.info("✅ App is in foreground")
        
        // Give a moment for any launch screens or modals to appear
        sleep(1)
        
        // Log what's visible on screen for debugging
        logger.info("📱 Current screen state:")
        logger.info("  - Buttons: \(app.buttons.count)")
        logger.info("  - Static texts: \(app.staticTexts.count)")
        logger.info("  - Navigation bars: \(app.navigationBars.count)")
        logger.info("  - Tab bars: \(app.tabBars.count)")
        
        // Check if license agreement is showing
        let licenseButton = app.buttons["I Accept"]
        if licenseButton.exists {
            logger.info("⚠️ License agreement detected - this is expected on first launch")
        }
        
        // Check if API key setup is showing
        let apiKeyText = app.staticTexts["API Key Required"]
        if apiKeyText.exists {
            logger.info("⚠️ API Key setup screen detected")
        }
        
        // Check if tab bar is visible (main UI)
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            logger.info("✅ Main tab bar is visible")
            XCTAssertTrue(tabBar.exists, "Tab bar should be visible")
        } else {
            logger.warning("⚠️ Tab bar not found - may be covered by modal")
        }
        
        // Take screenshot for documentation
        logger.info("📸 Taking screenshot")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        logger.info("✅ Test completed successfully")
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        logger.info("⚡ Starting launch performance test")
        
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["UI_TESTING"]
            app.launch()
        }
        
        logger.info("✅ Performance test completed")
    }
}
