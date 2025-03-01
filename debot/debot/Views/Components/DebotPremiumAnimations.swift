import SwiftUI

/// Premium animations for the Debot app
struct DebotPremiumAnimations {
    
    /// Creates a beautiful animated gradient background
    /// - Parameters:
    ///   - colors: Array of colors for the gradient
    ///   - speed: Animation speed (lower is faster)
    /// - Returns: A view with the animated gradient
    static func animatedGradient(colors: [Color], speed: Double = 5.0) -> some View {
        AnimatedGradientView(colors: colors, speed: speed)
    }
    
    /// Creates a particle effect for flight animations
    /// - Parameters:
    ///   - count: Number of particles
    ///   - color: Color of particles
    /// - Returns: A view with the particle effect
    static func particleEffect(count: Int = 50, color: Color = .white) -> some View {
        ParticleEffectView(particleCount: count, particleColor: color)
    }
    
    /// Creates a pulsing effect for UI elements
    /// - Parameters:
    ///   - initialScale: Starting scale
    ///   - finalScale: Ending scale
    ///   - duration: Animation duration
    /// - Returns: A view modifier for the pulsing effect
    static func pulsingEffect(initialScale: CGFloat = 1.0, finalScale: CGFloat = 1.05, duration: Double = 1.5) -> some ViewModifier {
        PulsingEffectModifier(initialScale: initialScale, finalScale: finalScale, duration: duration)
    }
    
    /// Creates a parallax effect for card views
    /// - Parameter magnitude: Strength of the parallax effect
    /// - Returns: A view modifier for the parallax effect
    static func parallaxEffect(magnitude: CGFloat = 10) -> some ViewModifier {
        ParallaxEffectModifier(magnitude: magnitude)
    }
    
    /// Creates a typing animation for text
    /// - Parameters:
    ///   - text: Text to animate
    ///   - speed: Characters per second
    /// - Returns: A view with typing animation
    static func typingAnimation(text: String, speed: Double = 10) -> some View {
        TypingTextView(finalText: text, charactersPerSecond: speed)
    }
}

// MARK: - Animation Components

/// A view that displays an animated gradient background
struct AnimatedGradientView: View {
    let colors: [Color]
    let speed: Double
    
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                    self.start = UnitPoint(x: 1, y: 0)
                    self.end = UnitPoint(x: 0, y: 1)
                }
            }
            .ignoresSafeArea()
    }
}

/// A view that displays a particle effect
struct ParticleEffectView: View {
    let particleCount: Int
    let particleColor: Color
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let timeInterval = timeline.date.timeIntervalSince1970
                let _ = timeInterval.remainder(dividingBy: 2 * .pi)
                
                for i in 0..<particleCount {
                    let position = getParticlePosition(index: i, time: timeInterval, size: size)
                    let opacity = getParticleOpacity(index: i, time: timeInterval)
                    let path = Path(ellipseIn: CGRect(x: position.x - 1, y: position.y - 1, width: 2, height: 2))
                    
                    context.opacity = opacity
                    context.fill(path, with: .color(particleColor))
                }
            }
        }
    }
    
    private func getParticlePosition(index: Int, time: TimeInterval, size: CGSize) -> CGPoint {
        let angle = (Double(index) / Double(particleCount)) * 2 * .pi + time.remainder(dividingBy: 2 * .pi)
        let radius = sin(time + Double(index)) * 0.4 + 0.6
        let x = size.width / 2 + size.width * 0.4 * radius * cos(angle)
        let y = size.height / 2 + size.height * 0.4 * radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    private func getParticleOpacity(index: Int, time: TimeInterval) -> Double {
        let base = 0.5
        let fluctuation = 0.5
        let value = base + fluctuation * sin(time * 2 + Double(index))
        return value
    }
}

/// A view modifier that creates a pulsing effect
struct PulsingEffectModifier: ViewModifier {
    let initialScale: CGFloat
    let finalScale: CGFloat
    let duration: Double
    
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? finalScale : initialScale)
            .animation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// A view modifier that creates a parallax effect
struct ParallaxEffectModifier: ViewModifier {
    let magnitude: CGFloat
    
    @State private var offset: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset.width, y: offset.height)
            .onAppear {
                let motionManager = MotionManager.shared
                motionManager.startMonitoringMotion { pitch, roll in
                    withAnimation(.spring()) {
                        offset = CGSize(width: roll * magnitude, height: pitch * magnitude)
                    }
                }
            }
    }
}

/// A view that displays text with a typing animation
struct TypingTextView: View {
    let finalText: String
    let charactersPerSecond: Double
    
    @State private var displayedText = ""
    @State private var isAnimating = false
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                animateText()
            }
    }
    
    private func animateText() {
        displayedText = ""
        isAnimating = true
        
        let characterDelay = 1.0 / charactersPerSecond
        
        for (index, character) in finalText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay * Double(index)) {
                displayedText += String(character)
                
                if index == finalText.count - 1 {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Support Classes

/// A singleton class for monitoring device motion
class MotionManager {
    static let shared = MotionManager()
    
    private init() { }
    
    // In a real implementation, this would use Core Motion
    // For now, we'll simulate motion
    
    private var timer: Timer?
    private var currentPitch: Double = 0
    private var currentRoll: Double = 0
    
    func startMonitoringMotion(callback: @escaping (Double, Double) -> Void) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Simulate slight device motion
            self.currentPitch = sin(Date().timeIntervalSince1970 * 0.5) * 0.05
            self.currentRoll = cos(Date().timeIntervalSince1970 * 0.3) * 0.05
            
            callback(self.currentPitch, self.currentRoll)
        }
    }
    
    func stopMonitoringMotion() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a pulsing animation to the view
    func pulsing(initialScale: CGFloat = 1.0, finalScale: CGFloat = 1.05, duration: Double = 1.5) -> some View {
        modifier(DebotPremiumAnimations.pulsingEffect(initialScale: initialScale, finalScale: finalScale, duration: duration))
    }
    
    /// Applies a parallax effect to the view
    func parallax(magnitude: CGFloat = 10) -> some View {
        modifier(DebotPremiumAnimations.parallaxEffect(magnitude: magnitude))
    }
} 