import SwiftUI

/// Mode for the app's theme (dark, light, system)
public enum ThemeMode: String, CaseIterable {
    case dark, light, system
    
    /// Icon representation for UI
    public var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "gear"
        }
    }
} 