import UIKit

/// Provides sophisticated haptic feedback throughout the app
class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    // Success feedback generator
    private let successGenerator = UINotificationFeedbackGenerator()
    
    // Error feedback generator
    private let errorGenerator = UINotificationFeedbackGenerator()
    
    // Selection feedback generator
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // Impact feedback generators (light, medium, heavy)
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    // For iOS 13+, soft and rigid impact
    private let softImpactGenerator: UIImpactFeedbackGenerator?
    private let rigidImpactGenerator: UIImpactFeedbackGenerator?
    
    // Whether haptics are enabled
    private(set) var isEnabled: Bool = true
    
    private init() {
        // Initialize iOS 13+ generators if available
        if #available(iOS 13.0, *) {
            softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
            rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
        } else {
            softImpactGenerator = nil
            rigidImpactGenerator = nil
        }
        
        // Check user defaults for haptic setting
        if let enabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool {
            isEnabled = enabled
        }
        
        // Prepare generators
        prepareGenerators()
    }
    
    /// Prepare all generators for immediate use
    private func prepareGenerators() {
        successGenerator.prepare()
        errorGenerator.prepare()
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        softImpactGenerator?.prepare()
        rigidImpactGenerator?.prepare()
    }
    
    /// Enable or disable haptic feedback
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "hapticFeedbackEnabled")
        
        // If re-enabling, prepare generators
        if enabled {
            prepareGenerators()
        }
    }
    
    // MARK: - Basic Feedback Types
    
    /// Trigger success feedback
    func success() {
        guard isEnabled else { return }
        successGenerator.notificationOccurred(.success)
    }
    
    /// Trigger warning feedback
    func warning() {
        guard isEnabled else { return }
        successGenerator.notificationOccurred(.warning)
    }
    
    /// Trigger error feedback
    func error() {
        guard isEnabled else { return }
        errorGenerator.notificationOccurred(.error)
    }
    
    /// Trigger selection feedback
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    /// Trigger light impact feedback
    func lightImpact() {
        guard isEnabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    /// Trigger medium impact feedback
    func mediumImpact() {
        guard isEnabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    /// Trigger heavy impact feedback
    func heavyImpact() {
        guard isEnabled else { return }
        heavyImpactGenerator.impactOccurred()
    }
    
    /// Trigger soft impact feedback (iOS 13+)
    func softImpact() {
        guard isEnabled else { return }
        if #available(iOS 13.0, *) {
            softImpactGenerator?.impactOccurred()
        } else {
            // Fallback for older iOS
            lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Trigger rigid impact feedback (iOS 13+)
    func rigidImpact() {
        guard isEnabled else { return }
        if #available(iOS 13.0, *) {
            rigidImpactGenerator?.impactOccurred()
        } else {
            // Fallback for older iOS
            mediumImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - Complex Feedback Patterns
    
    /// Heartbeat effect - used when focusing on a flight
    func heartbeat() {
        guard isEnabled else { return }
        
        // First beat (stronger)
        mediumImpactGenerator.impactOccurred()
        
        // Second beat (lighter, delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.lightImpactGenerator.impactOccurred()
        }
    }
    
    /// Elevation change feedback - used for altitude changes
    func elevationChange(up: Bool) {
        guard isEnabled else { return }
        
        if up {
            // Rising pattern
            lightImpactGenerator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.mediumImpactGenerator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.heavyImpactGenerator.impactOccurred()
            }
        } else {
            // Falling pattern
            heavyImpactGenerator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.mediumImpactGenerator.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.lightImpactGenerator.impactOccurred()
            }
        }
    }
    
    /// Success sequence - used for completed operations
    func successSequence() {
        guard isEnabled else { return }
        
        lightImpactGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumImpactGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.successGenerator.notificationOccurred(.success)
        }
    }
    
    /// Error sequence - used for failed operations
    func errorSequence() {
        guard isEnabled else { return }
        
        mediumImpactGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.heavyImpactGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.errorGenerator.notificationOccurred(.error)
        }
    }
    
    /// Focus sequence - used when focusing on a specific flight
    func focusSequence() {
        guard isEnabled else { return }
        
        // Initial attention
        selectionGenerator.selectionChanged()
        
        // Build up to focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.lightImpactGenerator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.mediumImpactGenerator.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            // Final lock on
            self?.rigidImpact()
        }
    }
    
    /// Animation feedback - provides tactile feedback for animations
    func animationFeedback(duration: TimeInterval, intensity: Double) {
        guard isEnabled else { return }
        
        let steps = Int(duration / 0.1) // One step every 100ms
        let maxSteps = 20 // Safety limit
        
        for i in 0..<min(steps, maxSteps) {
            // Calculate dynamic intensity based on animation curve
            let progress = Double(i) / Double(steps)
            let currentIntensity = intensity * sin(progress * .pi)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * progress) { [weak self] in
                if currentIntensity > 0.7 {
                    self?.mediumImpactGenerator.impactOccurred(intensity: currentIntensity)
                } else {
                    self?.lightImpactGenerator.impactOccurred(intensity: currentIntensity)
                }
            }
        }
    }
} 