//
//  ImagePreprocessor.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//
//  Note: Uses global logging functions (logInfo, logDebug, etc.) 
//  defined in DiagnosticLogger.swift
//

import Foundation

#if os(iOS)
import UIKit
import SwiftUI
#endif
import CoreImage
import CoreImage.CIFilterBuiltins

class ImagePreprocessor {
    
    private let context = CIContext()
    
    /// Preprocess an image for optimal OCR results
    /// Applies: grayscale conversion, contrast enhancement, and sharpening
    func preprocessForOCR(_ image: UIImage, compressionQuality: CGFloat = 0.9) -> Data? {
        guard let inputImage = CIImage(image: image) else {
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        // Step 1: Convert to grayscale
        let grayscaleImage = applyGrayscale(to: inputImage)
        
        // Step 2: Enhance contrast
        let contrastedImage = enhanceContrast(grayscaleImage)
        
        // Step 3: Sharpen for better text recognition
        let sharpenedImage = sharpenImage(contrastedImage)
        
        // Step 4: Reduce noise
        let cleanedImage = reduceNoise(sharpenedImage)
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(cleanedImage, from: cleanedImage.extent) else {
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        let processedImage = UIImage(cgImage: cgImage)
        return processedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Quick preprocessing with just contrast and sharpening (preserves color)
    func preprocessLightweight(_ image: UIImage, compressionQuality: CGFloat = 0.9) -> Data? {
        guard let inputImage = CIImage(image: image) else {
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        let contrastedImage = enhanceContrast(inputImage)
        let sharpenedImage = sharpenImage(contrastedImage)
        
        guard let cgImage = context.createCGImage(sharpenedImage, from: sharpenedImage.extent) else {
            return image.jpegData(compressionQuality: compressionQuality)
        }
        
        let processedImage = UIImage(cgImage: cgImage)
        return processedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    // MARK: - Individual Filters
    
    private func applyGrayscale(to image: CIImage) -> CIImage {
        let filter = CIFilter.photoEffectMono()
        filter.inputImage = image
        return filter.outputImage ?? image
    }
    
    private func enhanceContrast(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.contrast = 1.5  // Increase contrast significantly
        filter.brightness = 0.1
        return filter.outputImage ?? image
    }
    
    private func sharpenImage(_ image: CIImage) -> CIImage {
        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = image
        filter.sharpness = 0.7
        return filter.outputImage ?? image
    }
    
    private func reduceNoise(_ image: CIImage) -> CIImage {
        let filter = CIFilter.noiseReduction()
        filter.inputImage = image
        filter.noiseLevel = 0.02
        filter.sharpness = 0.8
        return filter.outputImage ?? image
    }
    
    /// Create a side-by-side comparison of original and processed images
    func createComparisonImage(original: UIImage, processed: UIImage) -> UIImage? {
        let size = CGSize(width: original.size.width * 2, height: original.size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, original.scale)
        defer { UIGraphicsEndImageContext() }
        
        original.draw(in: CGRect(x: 0, y: 0, width: original.size.width, height: original.size.height))
        processed.draw(in: CGRect(x: original.size.width, y: 0, width: original.size.width, height: original.size.height))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Reduce image size to stay under a target size in bytes
    /// This uses progressive compression and resizing to meet the target
    /// - Parameters:
    ///   - image: The input image to reduce
    ///   - maxSizeBytes: Maximum size in bytes (default 500KB)
    /// - Returns: Data representation of the reduced image, or nil if failed
    func reduceImageSize(_ image: UIImage, maxSizeBytes: Int = 500_000) -> Data? {
        logInfo("Reducing image size, target: \(maxSizeBytes) bytes", category: "image")
        logDebug("Original image size: \(image.size.width) x \(image.size.height)", category: "image")
        
        // Try different compression qualities first
        let compressionQualities: [CGFloat] = [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3]
        
        for quality in compressionQualities {
            if let data = image.jpegData(compressionQuality: quality) {
                logDebug("Compression quality \(quality): \(data.count) bytes", category: "image")
                if data.count <= maxSizeBytes {
                    logInfo("Image reduced to \(data.count) bytes with compression \(quality)", category: "image")
                    return data
                }
            }
        }
        
        // If compression alone didn't work, resize the image
        logDebug("Compression alone insufficient, resizing image", category: "image")
        
        // Calculate target dimensions (reduce by steps of 10%)
        let resizeFactors: [CGFloat] = [0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3]
        
        for factor in resizeFactors {
            let newSize = CGSize(
                width: image.size.width * factor,
                height: image.size.height * factor
            )
            
            logDebug("Trying resize to \(newSize.width) x \(newSize.height) (factor: \(factor))", category: "image")
            
            guard let resizedImage = resizeImage(image, to: newSize) else {
                logWarning("Failed to resize image to \(newSize)", category: "image")
                continue
            }
            
            // Try compression qualities on resized image
            for quality in compressionQualities {
                if let data = resizedImage.jpegData(compressionQuality: quality) {
                    if data.count <= maxSizeBytes {
                        logInfo("Image reduced to \(data.count) bytes with resize factor \(factor) and compression \(quality)", category: "image")
                        return data
                    }
                }
            }
        }
        
        // Last resort: heavy compression on heavily reduced image
        logWarning("Using last resort heavy compression", category: "image")
        if let finalResize = resizeImage(image, to: CGSize(width: image.size.width * 0.2, height: image.size.height * 0.2)),
           let finalData = finalResize.jpegData(compressionQuality: 0.2) {
            logInfo("Final image size: \(finalData.count) bytes", category: "image")
            return finalData
        }
        
        logError("Failed to reduce image to target size", category: "image")
        return nil
    }
    
    /// Resize an image to a target size while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // Use the smaller ratio to maintain aspect ratio
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
