//
//  WebImageDownloader.swift
//  Reczipes2
//
//  Created for downloading images from web URLs
//

import Foundation
#if os(iOS)
import UIKit
#endif
import Combine

struct WebImageDownloader {
    
    /// Download an image from a URL
    /// - Parameter urlString: The URL string of the image
    /// - Returns: UIImage if successful
    func downloadImage(from urlString: String) async throws -> UIImage {
        DiagnosticLogger.shared.info("IMAGE DOWNLOAD START", category: "network")
        DiagnosticLogger.shared.debug("URL: \(urlString)", category: "network")
        
        guard let url = URL(string: urlString) else {
            DiagnosticLogger.shared.error("Invalid URL: \(urlString)", category: "network")
            throw ImageDownloadError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        // Set a user agent to avoid being blocked
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        DiagnosticLogger.shared.info("Downloading image", category: "network")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            DiagnosticLogger.shared.error("Invalid response type", category: "network")
            throw ImageDownloadError.networkError
        }
        
        DiagnosticLogger.shared.debug("HTTP Status: \(httpResponse.statusCode)", category: "network")
        
        guard httpResponse.statusCode == 200 else {
            DiagnosticLogger.shared.error("HTTP error: \(httpResponse.statusCode)", category: "network")
            throw ImageDownloadError.httpError(statusCode: httpResponse.statusCode)
        }
        
        guard let image = UIImage(data: data) else {
            DiagnosticLogger.shared.error("Failed to create UIImage from data", category: "network")
            throw ImageDownloadError.invalidImageData
        }
        
        DiagnosticLogger.shared.info("Successfully downloaded image", category: "network")
        DiagnosticLogger.shared.debug("Image size: \(image.size)", category: "network")
        DiagnosticLogger.shared.info("IMAGE DOWNLOAD END", category: "network")
        
        return image
    }
}

// MARK: - Error Types

enum ImageDownloadError: LocalizedError {
    case invalidURL
    case networkError
    case httpError(statusCode: Int)
    case invalidImageData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .networkError:
            return "Network error while downloading image"
        case .httpError(let statusCode):
            switch statusCode {
            case 403:
                return "Access denied to image"
            case 404:
                return "Image not found"
            default:
                return "HTTP error: \(statusCode)"
            }
        case .invalidImageData:
            return "Downloaded data is not a valid image"
        }
    }
}
