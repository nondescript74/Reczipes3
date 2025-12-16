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
                    .aspectRatio(contentMode: .fill)
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
                
                // Optional: Add app title or logo that fades out as wipe progresses
                VStack {
                    Spacer()
                    
                    Text("Reczipes")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .opacity(1 - wipeProgress * 0.7) // Gradually fade as wipe progresses
                    
                    Spacer()
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
            
            // Complete after 1.5 seconds total
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
