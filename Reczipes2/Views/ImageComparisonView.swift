//
//  ImageComparisonView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/29/26.
//

import SwiftUI

struct ImageComparisonView: View {
    let original: UIImage
    let processed: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Original")
                            .font(.headline)
                        Image(uiImage: original)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Processed (Enhanced)")
                            .font(.headline)
                        Image(uiImage: processed)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Image Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
