import SwiftUI
import Combine

// Remove incorrect import
// import AviationService

// Fix Flight typealias to use the correct model
// struct SimplifiedFlight {
//     let flightNumber: String
//     let departure: String
//     let arrival: String
//     let status: String
//     let altitude: String
//     
//     init(flightNumber: String, departure: String, arrival: String, status: String, altitude: String) {
//         self.flightNumber = flightNumber
//         self.departure = departure
//         self.arrival = arrival
//         self.status = status
//         self.altitude = altitude
//     }
// }

// Update to use our simplified flight type
// typealias AccessibilityFlight = SimplifiedFlight

// Remove the ViewFlight extension as we're using inline descriptions now

/// A manager for app-wide accessibility features and settings
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    // MARK: - Published Properties
    
    /// Whether larger text is enabled
    @Published var isLargeTextEnabled: Bool = false
    
    /// Whether reduced motion is enabled
    @Published var isReducedMotionEnabled: Bool = false
    
    /// Whether high contrast is enabled
    @Published var isHighContrastEnabled: Bool = false
    
    /// Whether VoiceOver is running
    @Published var isVoiceOverRunning: Bool = false
    
    /// Currently active accessibility features
    @Published var activeFeatures: [AccessibilityFeature] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        // Set initial values
        updateAccessibilityStatus()
        
        // Listen for accessibility notification changes
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in self?.updateAccessibilityStatus() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in self?.updateAccessibilityStatus() }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in self?.updateAccessibilityStatus() }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in self?.updateAccessibilityStatus() }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Update accessibility status based on system settings
    func updateAccessibilityStatus() {
        DispatchQueue.main.async {
            // Update all accessibility flags
            self.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
            self.isReducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
            self.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            
            // Check for large text
            let contentSize = UIApplication.shared.preferredContentSizeCategory
            self.isLargeTextEnabled = contentSize >= .accessibilityMedium
            
            // Update active features
            self.activeFeatures = self.determineActiveFeatures()
            
            // Log changes
            print("Accessibility status updated: VoiceOver: \(self.isVoiceOverRunning), Reduced Motion: \(self.isReducedMotionEnabled)")
        }
    }
    
    /// Get animation duration based on reduced motion setting
    func animationDuration(_ standardDuration: Double) -> Double {
        if isReducedMotionEnabled {
            return min(standardDuration * 0.5, 0.2) // Significantly reduced or eliminated
        } else {
            return standardDuration
        }
    }
    
    /// Get animation scale based on reduced motion setting
    func animationScale(_ standardScale: CGFloat) -> CGFloat {
        if isReducedMotionEnabled {
            return min(standardScale * 0.3, 0.05) // Significantly reduced or eliminated
        } else {
            return standardScale
        }
    }
    
    /// Whether to use complex animations
    var shouldUseComplexAnimations: Bool {
        return !isReducedMotionEnabled
    }
    
    /// Whether to use parallax effects
    var shouldUseParallaxEffects: Bool {
        return !isReducedMotionEnabled && !isVoiceOverRunning
    }
    
    /// Whether to use haptic feedback
    var shouldUseHaptics: Bool {
        return !UIAccessibility.isReduceTransparencyEnabled
    }
    
    /// Get font size modifier based on current accessibility settings
    func fontSizeModifier(for style: AccessibilityFontStyle) -> CGFloat {
        if isLargeTextEnabled {
            switch style {
            case .title:
                return 1.5
            case .heading:
                return 1.4
            case .body:
                return 1.3
            case .caption:
                return 1.2
            }
        } else {
            return 1.0
        }
    }
    
    /// Get appropriate line spacing for text
    var recommendedLineSpacing: CGFloat {
        if isLargeTextEnabled {
            return 8.0
        } else {
            return 4.0
        }
    }
    
    /// Get minimum tap target size to ensure accessibility
    var minimumTapTargetSize: CGFloat {
        return 44.0
    }
    
    /// Announce a message via VoiceOver
    func announceMessage(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// Get a descriptive label for a flight
    func flightDescription(flight: SimplifiedFlight) -> String {
        return "Flight \(flight.flightNumber) from \(flight.departure) to \(flight.arrival). Status: \(flight.status). Altitude: \(flight.altitude) feet."
    }
    
    // MARK: - Private Methods
    private func determineActiveFeatures() -> [AccessibilityFeature] {
        var features: [AccessibilityFeature] = []
        
        if isVoiceOverRunning {
            features.append(.voiceOver)
        }
        
        if isReducedMotionEnabled {
            features.append(.reducedMotion)
        }
        
        if isHighContrastEnabled {
            features.append(.highContrast)
        }
        
        if isLargeTextEnabled {
            features.append(.largeText)
        }
        
        return features
    }
}

// MARK: - Supporting Types

/// Font style categories for accessibility sizing
enum AccessibilityFontStyle {
    case title
    case heading
    case body
    case caption
}

/// Accessibility features that can be active
enum AccessibilityFeature: String, CaseIterable, Identifiable {
    case voiceOver = "VoiceOver"
    case reducedMotion = "Reduced Motion"
    case highContrast = "High Contrast"
    case largeText = "Large Text"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .voiceOver:
            return "ear"
        case .reducedMotion:
            return "hand.raised.slash"
        case .highContrast:
            return "circle.lefthalf.filled"
        case .largeText:
            return "textformat.size"
        }
    }
    
    var description: String {
        switch self {
        case .voiceOver:
            return "Screen reader is active"
        case .reducedMotion:
            return "Animations are simplified"
        case .highContrast:
            return "Using higher contrast colors"
        case .largeText:
            return "Using larger text sizes"
        }
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply accessibility enhancements based on current settings
    func withAccessibilityEnhancements(
        label: String? = nil,
        hint: String? = nil,
        isFlight: Bool = false
    ) -> some View {
        self.modifier(AccessibilityEnhancementModifier(
            label: label,
            hint: hint,
            isFlight: isFlight
        ))
    }
    
    /// Apply dynamic font sizing based on accessibility settings
    func dynamicAccessibilityFont(_ style: AccessibilityFontStyle) -> some View {
        self.modifier(DynamicFontModifier(style: style))
    }
}

/// Modifier that applies appropriate accessibility enhancements
struct AccessibilityEnhancementModifier: ViewModifier {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    let label: String?
    let hint: String?
    let isFlight: Bool
    
    func body(content: Content) -> some View {
        content
            .accessibility(label: label.map { Text($0) } ?? Text(""))
            .accessibility(hint: hint.map { Text($0) } ?? Text(""))
            .accessibility(addTraits: isFlight ? .updatesFrequently : [])
            .contentShape(Rectangle()) // Ensures the entire area is tappable
            .accessibilityElement(children: .combine)
    }
}

/// Modifier that applies dynamic font sizing
struct DynamicFontModifier: ViewModifier {
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    
    let style: AccessibilityFontStyle
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(accessibilityManager.fontSizeModifier(for: style))
            .lineSpacing(accessibilityManager.recommendedLineSpacing)
    }
} 