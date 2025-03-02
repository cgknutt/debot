import SwiftUI

/// A view modifier that applies Titan One font to all text elements in a view hierarchy
/// (Previously used Cooper Black, kept the same name for compatibility)
struct CooperBlackTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transformEnvironment(\.font) { font in
                // If no font is set, we'll use Titan One with default size
                if font == nil {
                    font = .cooperBlack(size: 17)
                }
            }
            .onAppear {
                // Configure global UI font settings to use Titan One
                let fontName = "TitanOne-Regular"
                
                // Only proceed if the font is available
                guard let font = UIFont(name: fontName, size: 17) else {
                    print("⚠️ WARNING: Titan One font not available in GlobalTextStyle")
                    return
                }
                
                let fontDescriptor = font.fontDescriptor
                
                // Override default UIKit fonts
                UILabel.appearance().font = UIFont(descriptor: fontDescriptor, size: 0)
                UITextField.appearance().font = UIFont(descriptor: fontDescriptor, size: 0)
                UITextView.appearance().font = UIFont(descriptor: fontDescriptor, size: 0)
                UIButton.appearance().titleLabel?.font = UIFont(descriptor: fontDescriptor, size: 0)
            }
    }
}

// Extension to make applying the style easier
extension View {
    /// Applies Titan One font to all text elements in this view hierarchy
    /// (Previously used Cooper Black, kept the same function name for compatibility)
    func withCooperBlackStyle() -> some View {
        modifier(CooperBlackTextStyle())
    }
}

// Global fonts to use in the app
extension Font {
    static func defaultFont(size: CGFloat = 17) -> Font {
        return .cooperBlack(size: size)
    }
} 