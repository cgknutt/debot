import SwiftUI

// MARK: - Font Extensions
extension Font {
    /// Creates a Cooper Black font with the specified size
    /// Falls back to an appropriate system font if Cooper Black is unavailable
    static func cooperBlack(size: CGFloat) -> Font {
        // Adobe Fonts tends to use the PostScript name of the font
        // Try multiple possible names for Cooper Black
        let possibleFontNames = [
            "CooperBlack-Regular",   // Common PostScript name
            "Cooper Black",          // Display name
            "CooperBlack",           // Another common variation
            "Cooper-Black"           // Hyphenated variation
        ]
        
        // Try each possible font name
        for fontName in possibleFontNames {
            if let _ = UIFont(name: fontName, size: size) {
                print("Found Cooper Black font with name: \(fontName)")
                return Font.custom(fontName, size: size)
            }
        }
        
        // If none of the Cooper Black variations work, fall back to system font
        print("Cooper Black not available from Adobe Fonts, using system font fallback")
        return Font.system(size: size, weight: .black, design: .rounded)
    }
    
    /// Returns the default text font (Cooper Black) with standard size
    static var cooperBody: Font {
        return .cooperBlack(size: 17)
    }
    
    /// Returns a small Cooper Black font
    static var cooperSmall: Font {
        return .cooperBlack(size: 15)
    }
    
    /// Returns a large Cooper Black font for headlines
    static var cooperHeadline: Font {
        return .cooperBlack(size: 20)
    }
    
    /// Returns a Cooper Black font for titles
    static var cooperTitle: Font {
        return .cooperBlack(size: 28)
    }
    
    /// Returns a large Cooper Black font for large titles
    static var cooperLargeTitle: Font {
        return .cooperBlack(size: 34)
    }
}

// MARK: - Text Extension
extension Text {
    /// Applies Cooper Black font with the specified size
    func cooperBlack(size: CGFloat) -> Text {
        return self.font(.cooperBlack(size: size))
    }
}

// MARK: - View Extension for Font Modifier
extension View {
    /// Applies Cooper Black font with the specified size to any view that supports fonts
    func cooperBlack(size: CGFloat) -> some View {
        return self.font(.cooperBlack(size: size))
    }
} 