//
//  Reczipes2ClipApp.swift
//  Reczipes2Clip
//
//  Created by Zahirudeen Premji on 2/4/26.
//

import SwiftUI

@main
struct Reczipes2ClipApp: App {

    /// The URL passed in when the App Clip is invoked via a universal link
    /// (e.g. ?url=https://…).  Forwarded down to AppClipContentView so it
    /// can skip straight to extraction when present.
    @State private var invocationURL: String?

    var body: some Scene {
        WindowGroup {
            AppClipContentView(invocationURL: $invocationURL)
                .onOpenURL { url in
                    // Extract the "url" query-string parameter if present
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let target = components.queryItems?.first(where: { $0.name == "url" })?.value {
                        invocationURL = target
                    }
                }
        }
    }
}
