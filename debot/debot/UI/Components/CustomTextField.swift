import SwiftUI

struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var errorMessage: String? = nil
    
    @State private var isEditing: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.paddingSmall) {
            // Title
            Text(title)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(.secondary)
            
            // Text Field
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .onTapGesture {
                            isEditing = true
                        }
                }
            }
            .textFieldStyle(CustomTextFieldStyle(isEditing: isEditing, hasError: errorMessage != nil))
            .onChange(of: text) { _ in
                isEditing = true
            }
            
            // Error Message
            if let error = errorMessage {
                Text(error)
                    .font(Theme.Typography.bodySmall)
                    .foregroundColor(.red)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    let isEditing: Bool
    let hasError: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(Theme.Layout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall)
                    .stroke(borderColor, lineWidth: isEditing ? 2 : 1)
            )
    }
    
    private var borderColor: Color {
        if hasError {
            return .red
        }
        return isEditing ? .accentColor : Color(.systemGray4)
    }
}

#Preview {
    VStack(spacing: Theme.Layout.paddingMedium) {
        CustomTextField(
            title: "Username",
            placeholder: "Enter your username",
            text: .constant(""),
            errorMessage: nil
        )
        
        CustomTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant("password123"),
            isSecure: true,
            errorMessage: "Password must be at least 8 characters"
        )
    }
    .padding()
} 