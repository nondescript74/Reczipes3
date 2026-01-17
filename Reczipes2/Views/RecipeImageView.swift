//
//  RecipeImageView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/4/25.
//

import SwiftUI

/// A view that displays a recipe's image with a fallback placeholder
/// Supports both Assets catalog images and images saved to Documents directory
struct RecipeImageView: View {
    let imageName: String?
    let size: CGSize?
    let aspectRatio: ContentMode
    let cornerRadius: CGFloat
    
    @State private var loadedImage: UIImage?
    
    init(imageName: String?, 
         size: CGSize? = CGSize(width: 100, height: 100),
         aspectRatio: ContentMode = .fill,
         cornerRadius: CGFloat = 8) {
        self.imageName = imageName
        self.size = size
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Group {
            if let loadedImage {
                // Display loaded image from documents
                if let size {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: aspectRatio)
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                } else {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: aspectRatio)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            } else if let imageName = imageName, let assetImage = UIImage(named: imageName) {
                // Try to load from Assets catalog
                if let size {
                    Image(uiImage: assetImage)
                        .resizable()
                        .aspectRatio(contentMode: aspectRatio)
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                } else {
                    Image(uiImage: assetImage)
                        .resizable()
                        .aspectRatio(contentMode: aspectRatio)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                }
            } else {
                // Placeholder
                if let size {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: size.width, height: size.height)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: size.width * 0.4))
                                .foregroundStyle(.secondary)
                        )
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        )
                }
            }
        }
        .task(id: imageName) {
            if let imageName {
                loadedImage = loadImageFromDocuments(imageName)
            } else {
                loadedImage = nil
            }
        }
    }
    
    private func loadImageFromDocuments(_ filename: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        return UIImage(data: data)
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
