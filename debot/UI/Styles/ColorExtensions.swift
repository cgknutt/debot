import SwiftUI

// MARK: - Color Extensions
public extension Color {
    // Brand colors
    static let debotOrange = Color(UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0))
    static let debotGold = Color(UIColor(red: 0.85, green: 0.65, blue: 0.3, alpha: 1.0))
    static let debotBrown = Color(UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0))
    
    // Legacy neutral colors - replaced with system colors
    static let neutralGray1 = Color(UIColor.systemGray)
    static let neutralGray2 = Color(UIColor.systemGray2)
    static let neutralGray3 = Color(UIColor.systemGray3)
    static let neutralGray4 = Color(UIColor.systemGray4)
    static let neutralGray5 = Color(UIColor.systemGray5)
    static let neutralGray6 = Color(UIColor.systemGray6)
    
    // Background colors
    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
    
    // Alert Colors
    static let alertRed = Color(UIColor.systemRed)
    static let alertYellow = Color(UIColor.systemYellow)
    static let alertGreen = Color(UIColor.systemGreen)
    static let alertBlue = Color(UIColor.systemBlue)
    
    // Other UI Elements
    static let searchBackground = Color(UIColor.systemGray6)
    
    // Hex color initializer with unique name to avoid conflicts
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 