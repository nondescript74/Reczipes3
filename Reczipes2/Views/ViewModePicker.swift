//
//  ViewModePicker.swift
//  Reczipes2
//
//  Created on 1/27/26.
//

import SwiftUI

/// A segmented picker for switching between legacy and new data models
struct ViewModePicker: View {
    @Binding var selectedMode: BookViewMode
    let legacyCount: Int
    let newCount: Int
    let contentType: String // "Books" or "Recipes"
    
    var body: some View {
        VStack(spacing: 8) {
            Picker("View Mode", selection: $selectedMode) {
                ForEach(BookViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Description of current mode with count info
            HStack {
                Image(systemName: modeSystemImage)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                Text(modeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func count(for mode: BookViewMode) -> Int {
        switch mode {
        case .legacy:
            return legacyCount
        case .new:
            return newCount
        }
    }
    
    private var modeSystemImage: String {
        switch selectedMode {
        case .legacy:
            return "clock.arrow.circlepath"
        case .new:
            return "sparkles"
        }
    }
    
    private var modeDescription: String {
        let currentCount = count(for: selectedMode)
        let countText = currentCount == 1 ? "1 item" : "\(currentCount) items"
        
        switch selectedMode {
        case .legacy:
            return "Legacy format: \(countText)"
        case .new:
            return "New format: \(countText)"
        }
    }
}

#Preview {
    VStack {
        ViewModePicker(
            selectedMode: .constant(.legacy),
            legacyCount: 5,
            newCount: 2,
            contentType: "Books"
        )
        
        ViewModePicker(
            selectedMode: .constant(.new),
            legacyCount: 5,
            newCount: 2,
            contentType: "Books"
        )
        
        ViewModePicker(
            selectedMode: .constant(.legacy),
            legacyCount: 0,
            newCount: 10,
            contentType: "Recipes"
        )
    }
}
