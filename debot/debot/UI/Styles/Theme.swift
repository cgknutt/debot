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
    
    // MARK: - Button Styles
    
    /// Standard button style for primary actions
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusMedium)
                        .fill(Colors.debotOrange)
                        .opacity(configuration.isPressed ? 0.8 : 1.0)
                )
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(Animation.quick, value: configuration.isPressed)
        }
    }
    
    /// Secondary button style for alternative actions
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusMedium)
                        .stroke(Colors.debotOrange, lineWidth: 2)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.cornerRadiusMedium)
                                .fill(Color.white.opacity(0.1))
                        )
                )
                .foregroundColor(Colors.debotOrange)
                .font(.system(size: 16, weight: .medium))
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(Animation.quick, value: configuration.isPressed)
        }
    }
    
    /// Icon button style for circular buttons with icons
    struct IconButtonStyle: ButtonStyle {
        var size: CGFloat = 44
        var bgColor: Color = Colors.debotOrange
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(bgColor)
                        .opacity(configuration.isPressed ? 0.8 : 1.0)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .foregroundColor(.white)
                .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
                .animation(Animation.quick, value: configuration.isPressed)
        }
    }
    
    // MARK: - View Modifiers
    
    /// Card style modifier for consistent card appearance
    struct CardModifier: ViewModifier {
        var cornerRadius: CGFloat = Layout.cornerRadiusMedium
        
        func body(content: Content) -> some View {
            content
                .padding(Layout.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.05))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    /// Header text style for consistent header appearance
    struct HeaderTextModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(Typography.titleSmall)
                .foregroundColor(Colors.text)
                .padding(.vertical, Layout.paddingSmall)
        }
    }
    
    /// Input field style for consistent text input appearance
    struct InputFieldModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(Layout.paddingMedium)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusSmall)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cornerRadiusSmall)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Extension for ViewModifier convenience methods
extension View {
    /// Apply card styling
    func cardStyle(cornerRadius: CGFloat = Theme.Layout.cornerRadiusMedium) -> some View {
        self.modifier(Theme.CardModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply header text styling
    func headerStyle() -> some View {
        self.modifier(Theme.HeaderTextModifier())
    }
    
    /// Apply input field styling
    func inputFieldStyle() -> some View {
        self.modifier(Theme.InputFieldModifier())
    }
} 