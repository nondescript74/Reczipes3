//
//  ImagePreprocessor.swift
//  Reczipes2
//
//  Created for Claude-powered recipe extraction
//

#if os(iOS)
import UIKit
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
}
