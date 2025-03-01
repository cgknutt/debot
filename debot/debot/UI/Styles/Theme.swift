import SwiftUI

/// Theme contains all the core styling elements for the app
enum Theme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color("AppPrimaryColor", bundle: .main)
        static let secondary = Color("Secondary", bundle: .main)
        static let accent = Color("Accent", bundle: .main)
        static let background = Color("Background", bundle: .main)
        static let text = Color("Text", bundle: .main)
        
        // Brand colors
        static let debotOrange = Color(UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0))
        static let debotGold = Color(UIColor(red: 0.85, green: 0.65, blue: 0.3, alpha: 1.0))
        static let debotBrown = Color(UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0))
    }
    
    // MARK: - Typography
    enum Typography {
        // All typography now uses Cooper Black
        static let titleLarge = Font.cooperBlack(size: 34)
        static let titleMedium = Font.cooperBlack(size: 28)
        static let titleSmall = Font.cooperBlack(size: 22)
        
        static let bodyLarge = Font.cooperBlack(size: 17)
        static let bodyMedium = Font.cooperBlack(size: 15)
        static let bodySmall = Font.cooperBlack(size: 13)
    }
    
    // MARK: - Layout
    enum Layout {
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
    }
    
    // MARK: - Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.6)
    }
} 