//
//  Reczipes2ClipUITests.swift
//  Reczipes2ClipUITests
//
//  Created by Zahirudeen Premji on 2/4/26.
//

import XCTest


final class Reczipes2ClipUITests: XCTestCase {
    
    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }
    
    func testAppClipLaunch() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // Verify the app launched successfully
        XCTAssertEqual(app.state, .runningForeground)
    }
    
    func testLaunchPerformance() throws {
        // This test verifies the app launches within a reasonable time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
