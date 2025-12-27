//
//  LaunchScreenView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/16/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var wipeProgress: CGFloat = 0
    @State private var imageOpacity: Double = 0
    @State private var isComplete = false
    let onComplete: () -> Void
    
    // App version information
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Reczipes"
    }
    
    private var logFileSize: String {
        DiagnosticLogger.shared.getFormattedLogFileSize()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient for a subtle base
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Recipe image from asset catalog that fades in as glass wipes away
                // Replace "launch_recipe_image" with your actual asset name
                Image("launch_recipe_image")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 40) // Add margins on left and right
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(imageOpacity)
                
                // Liquid Glass overlay that wipes left to right
                if wipeProgress < 1.0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: geometry.size.width * (1 - wipeProgress))
                        .glassEffect(.regular.tint(.white.opacity(0.2)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
                
                // App information overlay
                VStack(spacing: 0) {
                    // App name at the top with background
                    Text(appName)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
                        .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 4)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.black.opacity(0.5))
                                .blur(radius: 10)
                        )
                        .padding(.top, 60)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Version and diagnostic info at the bottom with background
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Version")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text(appVersion)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                        }
                        .foregroundStyle(.white)
                        
                        HStack(spacing: 4) {
                            Text("Build")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text(buildNumber)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                        }
                        .foregroundStyle(.white)
                        
                        HStack(spacing: 4) {
                            Text("Diagnostic Log")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                            Text(logFileSize)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                        }
                        .foregroundStyle(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.5))
                            .blur(radius: 10)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 3)
                    .padding(.bottom, 40)
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            // Start fading in the image immediately
            withAnimation(.easeIn(duration: 0.3)) {
                imageOpacity = 1.0
            }
            
            // Slightly delayed wipe animation for better effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 1.3)) {
                    wipeProgress = 1.0
                }
            }
            
            // Complete after 2.0 seconds total
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isComplete = true
                onComplete()
            }
        }
    }
}

#Preview {
    LaunchScreenView {
        print("Launch screen completed")
    }
}
