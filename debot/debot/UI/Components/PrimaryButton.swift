import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                }
                
                Text(title)
                    .font(Theme.Typography.bodyLarge)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Layout.paddingMedium)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(Theme.Layout.cornerRadiusMedium)
        }
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton(title: "Regular Button", action: {})
        PrimaryButton(title: "Loading Button", action: {}, isLoading: true)
    }
    .padding()
} 