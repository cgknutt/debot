import SwiftUI

struct Card<Content: View>: View {
    enum Style {
        case plain
        case bordered
        case elevated
    }
    
    let style: Style
    let content: Content
    
    init(
        style: Style = .plain,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Theme.Layout.paddingMedium)
            .background(backgroundColor)
            .cornerRadius(Theme.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusMedium)
                    .stroke(Color(.systemGray5), lineWidth: style == .bordered ? 1 : 0)
            )
            .shadow(
                color: Color.black.opacity(style == .elevated ? 0.1 : 0),
                radius: 10,
                x: 0,
                y: 2
            )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .plain, .bordered, .elevated:
            return Color(.systemBackground)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Theme.Layout.paddingMedium) {
            Card(style: .plain) {
                cardContent("Plain Card")
            }
            
            Card(style: .bordered) {
                cardContent("Bordered Card")
            }
            
            Card(style: .elevated) {
                cardContent("Elevated Card")
            }
        }
        .padding()
    }
    .background(Color(.systemGray6))
}

private func cardContent(_ title: String) -> some View {
    VStack(alignment: .leading, spacing: Theme.Layout.paddingSmall) {
        Text(title)
            .font(Theme.Typography.titleSmall)
        
        Text("This is a sample card component that can be used throughout the app. It supports different styles and can contain any content.")
            .font(Theme.Typography.bodyMedium)
            .foregroundColor(.secondary)
    }
} 