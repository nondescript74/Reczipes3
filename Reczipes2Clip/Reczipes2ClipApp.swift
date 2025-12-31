//
//  Reczipes2ClipApp.swift
//  Reczipes2Clip
//
//  App Clip Entry Point
//  Created by Zahirudeen Premji on 12/30/25.
//
//  ⚠️ IMPORTANT: This file should ONLY be included in the Reczipes2Clip (App Clip) target
//  Do NOT add this file to the main Reczipes2 app target
//

import SwiftUI

@main
struct Reczipes2ClipApp: App {
    
    @State private var extractURL: String?
    
    init() {
        // Suppress Auto Layout warnings
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
    
    var body: some Scene {
        WindowGroup {
            AppClipContentView(extractURL: $extractURL)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    handleInvocation(userActivity: userActivity)
                }
        }
    }
    
    // MARK: - App Clip Invocation
    
    private func handleInvocation(userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else {
            print("❌ App Clip invoked without URL")
            return
        }
        
        print("✅ App Clip invoked with URL: \(url)")
        
        // Parse URL for recipe extraction
        // Expected format: https://yourdomain.com/clip/extract?url=RECIPE_URL
        // or: https://yourdomain.com/clip/extract?recipe=RECIPE_ID
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let recipeURL = components.queryItems?.first(where: { $0.name == "url" })?.value {
                extractURL = recipeURL
                print("📝 Will extract recipe from: \(recipeURL)")
            } else if let recipeID = components.queryItems?.first(where: { $0.name == "recipe" })?.value {
                // Handle direct recipe ID if you have a recipe sharing system
                print("📝 Will load recipe ID: \(recipeID)")
            }
        }
    }
}

