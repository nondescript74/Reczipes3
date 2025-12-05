//
//  RecipeImageView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI

/// A view that displays a recipe's image with a fallback placeholder
struct RecipeImageView: View {
    let imageName: String?
    let size: CGSize
    let cornerRadius: CGFloat
    
    init(imageName: String?, 
         size: CGSize = CGSize(width: 100, height: 100),
         cornerRadius: CGFloat = 8) {
        self.imageName = imageName
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let imageName = imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: size.width * 0.4))
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }
}

#Preview("With Image") {
    RecipeImageView(imageName: "recipe1")
}

#Preview("Without Image") {
    RecipeImageView(imageName: nil)
}

#Preview("Large Size") {
    RecipeImageView(
        imageName: "recipe1",
        size: CGSize(width: 300, height: 300),
        cornerRadius: 16
    )
}
