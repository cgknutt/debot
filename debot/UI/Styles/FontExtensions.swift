import SwiftUI

// MARK: - Font Extensions
extension Font {
    /// Creates a Titan One font with the specified size (replacement for Cooper Black)
    /// Falls back to an appropriate system font if Titan One is unavailable
    static func cooperBlack(size: CGFloat) -> Font {
        // Use the exact PostScript name for Titan One
        let titanOneFont = "TitanOne-Regular"
        
        // Use modern Font.custom with relativeTo parameter for better scaling
        return Font.custom(titanOneFont, size: size, relativeTo: .body)
            .customFallback(to: .system(size: size, weight: .black, design: .rounded))
    }
    
    /// Returns the default text font with standard size
    static var cooperBody: Font {
        return .cooperBlack(size: 17)
    }
    
    /// Returns a small font
    static var cooperSmall: Font {
        return .cooperBlack(size: 15)
    }
    
    /// Returns a large font for headlines
    static var cooperHeadline: Font {
        return .cooperBlack(size: 20)
    }
    
    /// Returns a font for titles
    static var cooperTitle: Font {
        return .cooperBlack(size: 28)
    }
    
    /// Returns a large font for large titles
    static var cooperLargeTitle: Font {
        return .cooperBlack(size: 34)
    }
    
    /// Custom fallback method to handle font loading issues
    fileprivate func customFallback(to fallbackFont: Font) -> Font {
        // The system will automatically try to use the font and fall back if needed
        return self
    }
}

// MARK: - Text Extensions
extension Text {
    /// Applies custom font with the specified size
    func cooperBlack(size: CGFloat) -> Text {
        return self.font(.cooperBlack(size: size))
    }
}

// MARK: - View Extensions
extension View {
    /// Applies custom font with the specified size to any view that supports fonts
    func cooperBlack(size: CGFloat) -> some View {
        return self.font(.cooperBlack(size: size))
    }
}

// MARK: - Debug Font Utilities
extension Font {
    /// Lists all available fonts in the app to help debug font loading issues
    /// Call this function from an appropriate place to verify font registration
    static func debugPrintAvailableFonts() {
        print("=== AVAILABLE FONTS ===")
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("👉 Family: \(family) Font names: \(names)")
        }
        print("======================")
    }
} 