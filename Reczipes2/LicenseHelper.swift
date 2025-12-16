//
//  LicenseHelper.swift
//  Reczipes2
//
//  Created by Zahirudeen Premji on 12/16/25.
//

import Foundation

/// Helper class to manage the user's license agreement acceptance status
struct LicenseHelper {
    // MARK: - UserDefaults Keys
    
    private static let hasAcceptedLicenseKey = "hasAcceptedLicenseAgreement"
    private static let licenseAcceptanceDateKey = "licenseAcceptanceDate"
    private static let licenseVersionKey = "acceptedLicenseVersion"
    
    // MARK: - Current License Version
    
    /// Update this version number whenever the license terms change
    /// Users who accepted older versions may need to re-accept
    static let currentLicenseVersion = "1.0"
    
    // MARK: - License Status
    
    /// Check if the user has accepted the current license agreement
    static var hasAcceptedLicense: Bool {
        let hasAccepted = UserDefaults.standard.bool(forKey: hasAcceptedLicenseKey)
        let acceptedVersion = UserDefaults.standard.string(forKey: licenseVersionKey)
        
        // User must have accepted AND be on the current version
        return hasAccepted && acceptedVersion == currentLicenseVersion
    }
    
    /// Date when the user accepted the license (if available)
    static var acceptanceDate: Date? {
        return UserDefaults.standard.object(forKey: licenseAcceptanceDateKey) as? Date
    }
    
    // MARK: - License Management
    
    /// Record that the user has accepted the license agreement
    static func acceptLicense() {
        UserDefaults.standard.set(true, forKey: hasAcceptedLicenseKey)
        UserDefaults.standard.set(Date(), forKey: licenseAcceptanceDateKey)
        UserDefaults.standard.set(currentLicenseVersion, forKey: licenseVersionKey)
        print("✅ License agreement accepted (version \(currentLicenseVersion))")
    }
    
    /// Reset the license acceptance status (for testing or settings)
    static func resetLicenseAcceptance() {
        UserDefaults.standard.removeObject(forKey: hasAcceptedLicenseKey)
        UserDefaults.standard.removeObject(forKey: licenseAcceptanceDateKey)
        UserDefaults.standard.removeObject(forKey: licenseVersionKey)
        print("🔄 License acceptance status reset")
    }
    
    // MARK: - License Text
    
    /// The full text of the license agreement
    static let licenseText = """
    END USER LICENSE AGREEMENT
    
    Last Updated: December 16, 2025
    Version 1.0
    
    PLEASE READ THIS LICENSE AGREEMENT CAREFULLY BEFORE USING RECZIPES.
    
    By accepting this agreement, you acknowledge and agree to the following terms:
    
    1. USER RESPONSIBILITY FOR CONTENT
    
    You, the user, assume full responsibility for:
    
    • All content, including recipes, text, and descriptions, that you input, extract, store, or share through this application
    • All images that you capture, upload, select, assign, or share through this application
    • Ensuring you have the legal right to use, store, and share any content or images you provide to the application
    • Verifying that any shared content does not infringe on copyrights, trademarks, or other intellectual property rights
    • Any consequences arising from the use or sharing of content through this application
    
    2. CONTENT USAGE AND INTELLECTUAL PROPERTY
    
    You acknowledge that:
    
    • Recipes, food photography, and culinary content may be protected by copyright or other intellectual property rights
    • You are solely responsible for obtaining necessary permissions before capturing, storing, or sharing content that you do not own
    • The application developer assumes no liability for your use of third-party content
    • You should respect the intellectual property rights of cookbook authors, chefs, food bloggers, and other content creators
    
    3. AI-POWERED EXTRACTION
    
    You understand that:
    
    • This application uses artificial intelligence (Claude API by Anthropic) to extract recipe information from images and text
    • AI-extracted content may contain errors, inaccuracies, or omissions
    • You are responsible for reviewing and verifying all extracted recipe information for accuracy, safety, and completeness before use
    • The application developer is not liable for any issues arising from inaccurate recipe extraction
    
    4. PRIVACY AND DATA HANDLING
    
    • Your recipes and images are stored locally on your device
    • When using the recipe extraction feature, images and text are sent to Anthropic's Claude API for processing
    • You are responsible for understanding Anthropic's privacy policy and data handling practices
    • Your API key is stored securely in your device's Keychain
    
    5. NO WARRANTY
    
    This application is provided "as is" without warranty of any kind, either express or implied, including but not limited to:
    
    • Fitness for a particular purpose
    • Accuracy of recipe extraction
    • Availability of third-party services (Claude API)
    • Data integrity or security
    
    6. LIMITATION OF LIABILITY
    
    To the maximum extent permitted by law, the application developer shall not be liable for any:
    
    • Direct, indirect, incidental, or consequential damages
    • Loss of data, revenue, or profits
    • Copyright infringement or intellectual property violations
    • Food safety issues, allergic reactions, or health problems arising from recipe use
    • Damages resulting from the use or inability to use this application
    
    7. ACCEPTANCE
    
    By clicking "I Accept" below, you acknowledge that:
    
    • You have read and understood this agreement
    • You agree to be bound by these terms
    • You accept full responsibility for all content and images you use or share
    • You will use this application in compliance with all applicable laws and regulations
    
    If you do not agree to these terms, you may not use this application.
    """
}
