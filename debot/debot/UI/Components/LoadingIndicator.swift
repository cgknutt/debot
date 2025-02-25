import SwiftUI

struct LoadingIndicator: View {
    enum Size {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 32
            case .large: return 48
            }
        }
    }
    
    let size: Size
    var tintColor: Color = .accentColor
    
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: tintColor))
            .frame(width: size.dimension, height: size.dimension)
    }
}

struct LoadingOverlay: View {
    let message: String?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.8)
            
            VStack(spacing: Theme.Layout.paddingMedium) {
                LoadingIndicator(size: .large)
                
                if let message = message {
                    Text(message)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundColor(.secondary)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    VStack(spacing: Theme.Layout.paddingLarge) {
        // Different sizes
        HStack(spacing: Theme.Layout.paddingLarge) {
            LoadingIndicator(size: .small)
            LoadingIndicator(size: .medium)
            LoadingIndicator(size: .large)
        }
        
        // Different colors
        HStack(spacing: Theme.Layout.paddingLarge) {
            LoadingIndicator(size: .medium, tintColor: .red)
            LoadingIndicator(size: .medium, tintColor: .green)
            LoadingIndicator(size: .medium, tintColor: .blue)
        }
        
        // Loading overlay
        ZStack {
            Color(.systemGray6)
            LoadingOverlay(message: "Loading...")
        }
        .frame(height: 200)
        .cornerRadius(Theme.Layout.cornerRadiusMedium)
    }
    .padding()
} 