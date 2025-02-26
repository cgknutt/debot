import SwiftUI
import UIKit

/// A high-quality glass effect for UI elements that adapts to theme and appearance
struct SharedFlightGlassEffect: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    /// The intensity of the blur effect (0.0-1.0)
    var intensity: Double
    
    /// The opacity of the background tint (0.0-1.0)
    var opacity: Double
    
    /// Whether to use a refined border effect
    var useBorder: Bool
    
    /// The theme colors from the environment
    @Environment(\.themeColors) var colors
    
    init(intensity: Double = 0.7, opacity: Double = 0.2, useBorder: Bool = true) {
        self.intensity = max(0, min(1, intensity))
        self.opacity = max(0, min(1, opacity))
        self.useBorder = useBorder
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Dynamic blur based on color scheme and intensity
                    if colorScheme == .dark {
                        BlurView(style: blurStyle())
                            .opacity(0.7 + (intensity * 0.3))
                    } else {
                        BlurView(style: blurStyle())
                            .opacity(0.7 + (intensity * 0.3))
                    }
                    
                    // Subtle color overlay with dynamic opacity
                    colors.cardBackground
                        .opacity(opacity * (colorScheme == .dark ? 0.5 : 0.3))
                    
                    // Dynamic border if enabled
                    if useBorder {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colors.accent.opacity(0.6),
                                        colors.accent.opacity(0.3),
                                        colors.accent.opacity(0.1),
                                        colors.accent.opacity(0.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Determine the blur style based on intensity and color scheme
    private func blurStyle() -> UIBlurEffect.Style {
        if colorScheme == .dark {
            if intensity > 0.7 {
                return .systemMaterialDark
            } else if intensity > 0.4 {
                return .dark
            } else {
                return .systemUltraThinMaterialDark
            }
        } else {
            if intensity > 0.7 {
                return .systemMaterial
            } else if intensity > 0.4 {
                return .light
            } else {
                return .systemUltraThinMaterial
            }
        }
    }
}

// MARK: - View Extension
extension View {
    /// Applies the custom flight glass effect
    func sharedFlightGlassEffect(intensity: Double = 0.7, opacity: Double = 0.2, useBorder: Bool = true) -> some View {
        self.modifier(SharedFlightGlassEffect(intensity: intensity, opacity: opacity, useBorder: useBorder))
    }
    
    /// Applies a high-intensity glass effect for modal overlays
    func sharedModalGlassEffect() -> some View {
        self.modifier(SharedFlightGlassEffect(intensity: 0.9, opacity: 0.3, useBorder: true))
    }
    
    /// Applies a subtle glass effect for background elements
    func sharedSubtleGlassEffect() -> some View {
        self.modifier(SharedFlightGlassEffect(intensity: 0.4, opacity: 0.15, useBorder: false))
    }
    
    /// Applies a premium glass effect for featured content
    func sharedPremiumGlassEffect() -> some View {
        self.modifier(SharedFlightGlassEffect(intensity: 0.8, opacity: 0.25, useBorder: true))
    }
} 