import SwiftUI

// MARK: - Font Extensions
extension Font {
    /// Creates a Titan One font with the specified size (replacement for Cooper Black)
    /// Falls back to an appropriate system font if Titan One is unavailable
    static func cooperBlack(size: CGFloat) -> Font {
        // Use the exact PostScript name for Titan One
        let titanOneFont = "TitanOne-Regular"
        
        if let _ = UIFont(name: titanOneFont, size: size) {
            print("Using Titan One font!")
            return Font.custom(titanOneFont, size: size)
        }
        
        // Try alternative PostScript names for Titan One
        let possibleFontNames = [
            "TitanOne",
            "Titan One",
            "Titan-One",
            "TitanOneRegular"
        ]
        
        // Try each possible font name
        for fontName in possibleFontNames {
            if let _ = UIFont(name: fontName, size: size) {
                print("Found Titan One font with name: \(fontName)")
                return Font.custom(fontName, size: size)
            }
        }
        
        // If Cooper Black is still installed, try using it as fallback
        let cooperBlackFont = "CooperBlackStd"
        if let _ = UIFont(name: cooperBlackFont, size: size) {
            print("Falling back to Cooper Black font")
            return Font.custom(cooperBlackFont, size: size)
        }
        
        // If none of the Titan One or Cooper Black variations work, fall back to system font
        print("⚠️ Titan One not available, using system font fallback")
        return Font.system(size: size, weight: .black, design: .rounded)
    }
    
    /// Returns the default text font (Titan One) with standard size
    /// (Kept original name for compatibility)
    static var cooperBody: Font {
        return .cooperBlack(size: 17)
    }
    
    /// Returns a small Titan One font
    /// (Kept original name for compatibility)
    static var cooperSmall: Font {
        return .cooperBlack(size: 15)
    }
    
    /// Returns a large Titan One font for headlines
    /// (Kept original name for compatibility)
    static var cooperHeadline: Font {
        return .cooperBlack(size: 20)
    }
    
    /// Returns a Titan One font for titles
    /// (Kept original name for compatibility)
    static var cooperTitle: Font {
        return .cooperBlack(size: 28)
    }
    
    /// Returns a large Titan One font for large titles
    /// (Kept original name for compatibility)
    static var cooperLargeTitle: Font {
        return .cooperBlack(size: 34)
    }
}

// MARK: - Text Extensions
extension Text {
    /// Applies Titan One font with the specified size
    /// (Kept original name for compatibility)
    func cooperBlack(size: CGFloat) -> Text {
        return self.font(.cooperBlack(size: size))
    }
}

// MARK: - View Extensions
extension View {
    /// Applies Titan One font with the specified size to any view that supports fonts
    /// (Kept original name for compatibility)
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