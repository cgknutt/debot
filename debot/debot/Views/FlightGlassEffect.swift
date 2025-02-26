// NOTE: This file is deprecated. 
// All glass effect modifiers are now defined in Views/SharedGlassEffects.swift
// All BlurView functionality is defined in Models/SharedModels.swift
// Please use the shared components instead.

// This file is kept for backwards compatibility but should not be used for new code.
// It will be removed in a future update.

import SwiftUI

/// A high-quality glass effect for UI elements that adapts to theme and appearance
struct FlightGlassEffect: ViewModifier {
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
                        FlightGlassBlurView(style: blurStyle())
                            .opacity(0.7 + (intensity * 0.3))
                    } else {
                        FlightGlassBlurView(style: blurStyle())
                            .opacity(0.7 + (intensity * 0.3))
                    }
                    
                    // Subtle color overlay with dynamic opacity - using cardBackground instead of glass
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

/// UIKit blur view for SwiftUI integration
struct FlightGlassBlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - View Extension
extension View {
    /// Applies the custom flight glass effect
    func flightGlassEffect(intensity: Double = 0.7, opacity: Double = 0.2, useBorder: Bool = true) -> some View {
        self.modifier(FlightGlassEffect(intensity: intensity, opacity: opacity, useBorder: useBorder))
    }
    
    /// Applies a high-intensity glass effect for modal overlays
    func modalGlassEffect() -> some View {
        self.modifier(FlightGlassEffect(intensity: 0.9, opacity: 0.3, useBorder: true))
    }
    
    /// Applies a subtle glass effect for background elements
    func subtleGlassEffect() -> some View {
        self.modifier(FlightGlassEffect(intensity: 0.4, opacity: 0.15, useBorder: false))
    }
    
    /// Applies a premium glass effect for featured content
    func premiumGlassEffect() -> some View {
        self.modifier(FlightGlassEffect(intensity: 0.8, opacity: 0.25, useBorder: true))
    }
} 