//
//  SafariView.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 1/29/26.
//


// MARK: - SafariView Wrapper

import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let entersReaderIfAvailable: Bool
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = entersReaderIfAvailable
        configuration.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        safariVC.dismissButtonStyle = .done
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

// Alternative: Use the standard SwiftUI approach
extension View {
    func safariView(url: Binding<URL?>, isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            if let url = url.wrappedValue {
                SafariView(url: url, entersReaderIfAvailable: true)
                    .ignoresSafeArea()
            }
        }
    }
}
