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
    static let currentLicenseVersion = "2.2"
    
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
    
    Last Updated: January 28, 2026
    Version 2.2
    
    PLEASE READ THIS LICENSE AGREEMENT CAREFULLY BEFORE USING RECZIPES.
    
    By accepting this agreement, you acknowledge and agree to the following terms:
    
    1. NO MEDICAL, DIETARY, OR NUTRITIONAL ADVICE
    
    ⚠️ IMPORTANT DISCLAIMER:
    
    • This application DOES NOT provide medical, dietary, nutritional, or health advice
    • All recipe information, ingredient lists, and allergen data displayed in this application are sourced from the internet or user-provided content
    • This application is a TOOL for organizing and viewing recipes only — it is NOT a substitute for professional medical, dietary, or nutritional guidance
    • The AI-powered features MAY MAKE MISTAKES in extracting recipe information, identifying ingredients, or detecting allergens
    • You MUST verify all recipe information, especially regarding food allergies, dietary restrictions, and health conditions
    • NEVER rely solely on this application for allergen detection or dietary safety
    • Always consult qualified healthcare professionals, registered dietitians, or certified nutritionists for personalized dietary advice
    • The developer assumes NO RESPONSIBILITY for any health issues, allergic reactions, or adverse effects resulting from recipes or information found through this application
    
    2. USER RESPONSIBILITY FOR CONTENT
    
    You, the user, assume full responsibility for:
    
    • All content, including recipes, text, and descriptions, that you input, extract, store, or share through this application
    • All images that you capture, upload, select, assign, or share through this application
    • Ensuring you have the legal right to use, store, and share any content or images you provide to the application
    • Verifying that any shared content does not infringe on copyrights, trademarks, or other intellectual property rights
    • Any consequences arising from the use or sharing of content through this application
    
    3. CONTENT USAGE AND INTELLECTUAL PROPERTY
    
    You acknowledge that:
    
    • Recipes, food photography, and culinary content may be protected by copyright or other intellectual property rights
    • You are solely responsible for obtaining necessary permissions before capturing, storing, or sharing content that you do not own
    • The application developer assumes no liability for your use of third-party content
    • You should respect the intellectual property rights of cookbook authors, chefs, food bloggers, and other content creators
    
    4. PUBLIC SHARING AND LICENSING
    
    You understand and agree that:
    
    • Public sharing is OPTIONAL - you have full control over what you share
    • When you choose to publicly share recipes or recipe books through this application, they are automatically licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0)
    • This means others can use, share, and adapt your shared content, provided they give you appropriate credit
    • You retain ownership of your content and can stop sharing at any time
    • Once content has been shared publicly, others may have already downloaded or saved copies under the CC BY 4.0 license terms
    • You confirm that you have the legal right to share any content under this license
    • Private recipes stored on your device or synced via iCloud remain private and are NOT automatically shared
    • You control which specific recipes or books to share publicly through the app's sharing settings
    
    5. AI-POWERED EXTRACTION AND ACCURACY
    
    You understand that:
    
    • This application uses artificial intelligence (Claude API by Anthropic) to extract recipe information from images and text
    • AI systems are not perfect and CAN AND WILL MAKE MISTAKES
    • AI-extracted content may contain errors, inaccuracies, omissions, or misidentifications of ingredients and allergens
    • You are responsible for reviewing and verifying all extracted recipe information for accuracy, safety, and completeness before use
    • The application developer is not liable for any issues arising from inaccurate recipe extraction, including but not limited to missed allergens, incorrect ingredients, or wrong measurements
    • You should always cross-reference recipe information with the original source
    
    6. ALLERGEN DETECTION AND FOOD SAFETY
    
    You specifically acknowledge that:
    
    • The allergen profile and sensitivity features are informational tools ONLY
    • This application MAY FAIL to identify allergens or may incorrectly identify safe foods as unsafe (or vice versa)
    • You MUST read all ingredient labels and recipe information yourself
    • This application is NOT a replacement for careful ingredient verification
    • The developer is NOT LIABLE for any allergic reactions, health issues, or medical emergencies resulting from missed or misidentified allergens
    
    7. DIABETIC-FRIENDLY ANALYSIS AND NUTRITIONAL INFORMATION
    
    You specifically acknowledge that:
    
    • The diabetic-friendly analysis feature provides INFORMATIONAL GUIDANCE ONLY and is NOT medical, dietary, or nutritional advice
    • Glycemic load estimates, carbohydrate calculations, and ingredient substitution suggestions are generated by AI analysis and may contain errors, inaccuracies, or be incomplete
    • This feature relies on third-party medical sources (ADA, Mayo Clinic, CDC, NIH) that are aggregated and interpreted by AI, which CAN AND WILL MAKE MISTAKES
    • Source information is provided for transparency but does not guarantee accuracy or suitability for your specific health needs
    • The consensus level indicators (verified, moderate, limited, review needed) reflect source agreement but DO NOT constitute medical endorsement
    • Glycemic index and glycemic load calculations are estimates based on typical ingredient compositions and may not reflect your specific recipe variations, portion sizes, or individual metabolic responses
    • You MUST consult with your healthcare provider, registered dietitian, certified diabetes educator, or other qualified healthcare professional before making any dietary changes based on this information
    • This feature is NOT designed to replace blood glucose monitoring, insulin calculations, meal planning with healthcare providers, or any aspect of diabetes management
    • The developer is NOT LIABLE for any health complications, blood sugar issues, diabetic complications, medical emergencies, or adverse health effects resulting from reliance on the diabetic-friendly analysis
    • Information is cached for 30 days for performance and cost reasons, but dietary guidelines may evolve - always verify current medical recommendations with healthcare professionals
    • The "last updated" timestamp indicates when the analysis was performed, not when the underlying medical guidelines were published
    • You understand that individual responses to foods vary significantly based on factors including but not limited to: overall health, medications, activity level, portion sizes, food combinations, and individual metabolism
    
    8. PRIVACY AND DATA HANDLING
    
    • Your recipes and images are stored locally on your device
    • When using the recipe extraction feature, images and text are sent to Anthropic's Claude API for processing
    • When using the diabetic-friendly analysis feature, recipe ingredient and instruction data is sent to Anthropic's Claude API for AI-powered nutritional analysis
    • You are responsible for understanding Anthropic's privacy policy and data handling practices
    • Your API key is stored securely in your device's Keychain
    • Diabetic analysis results are cached locally for 30 days to improve performance and reduce API costs
    • No personal health information, diabetic status, or analysis history is tracked, stored, or shared with third parties
    • All dietary preference settings (FODMAP, diabetic analysis) are stored locally on your device only
    • Publicly shared recipes are stored in iCloud and visible to all users who browse community content
    
    9. NO WARRANTY
    
    This application is provided "as is" without warranty of any kind, either express or implied, including but not limited to:
    
    • Fitness for a particular purpose
    • Accuracy of recipe extraction, allergen detection, or diabetic-friendly analysis
    • Correctness of glycemic load calculations, carbohydrate counts, or nutritional estimates
    • Availability of third-party services (Claude API)
    • Data integrity or security
    • Suitability for any medical, dietary, nutritional, or health-related purpose
    
    10. LIMITATION OF LIABILITY
    
    To the maximum extent permitted by law, the application developer shall not be liable for any:
    
    • Direct, indirect, incidental, or consequential damages
    • Loss of data, revenue, or profits
    • Copyright infringement or intellectual property violations
    • Food safety issues, allergic reactions, adverse health effects, medical emergencies, or any health problems arising from recipe use
    • Injuries, illnesses, or death resulting from the use of recipes or information obtained through this application
    • Damages resulting from AI errors, omissions, inaccuracies, or incorrect nutritional analyses
    • Blood sugar complications, diabetic emergencies, or health issues resulting from reliance on diabetic-friendly analysis
    • Damages resulting from the use or inability to use this application
    • Issues arising from content shared under the Creative Commons BY 4.0 license
    
    11. THIRD-PARTY CONTENT AND SOURCES
    
    • All recipes and information displayed are sourced from the web or provided by users
    • The application developer does not create, verify, endorse, or guarantee the accuracy of any recipe content
    • Diabetic-friendly analysis aggregates information from third-party medical sources (ADA, Mayo Clinic, CDC, NIH, etc.)
    • While we prioritize reputable medical sources, the developer does not independently verify the accuracy or currentness of source information
    • Medical guidelines and nutritional science evolve over time - what is current today may be outdated tomorrow
    • Source URLs and citations are provided for transparency and user verification, not as endorsement or guarantee of accuracy
    • You use all recipe information and health analysis at your own risk
    
    12. ACCEPTANCE
    
    By clicking "I Accept" below, you acknowledge that:
    
    • You have read and understood this agreement
    • You agree to be bound by these terms
    • You accept full responsibility for all content and images you use or share
    • You understand this app provides NO medical, dietary, or nutritional advice
    • You understand the diabetic-friendly analysis is INFORMATIONAL ONLY and you will consult healthcare professionals for medical guidance
    • You understand the AI features can make mistakes in recipe extraction, allergen detection, and nutritional analysis
    • You will verify all recipe information independently, especially regarding allergens, dietary restrictions, and blood sugar management
    • You understand glycemic load and carbohydrate calculations are estimates and may not reflect your individual metabolic response
    • You understand that publicly sharing content licenses it under Creative Commons BY 4.0 (attribution required)
    • You have the legal right to share any content you choose to make public
    • You can choose to keep your recipes private or share them publicly at your discretion
    • You will use this application in compliance with all applicable laws and regulations
    
    If you do not agree to these terms, you may not use this application.
    """
}
