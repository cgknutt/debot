import SwiftUI

struct ComponentShowcase: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showLoadingOverlay = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.paddingLarge) {
                // MARK: - Typography
                Card(style: .bordered) {
                    VStack(alignment: .leading, spacing: Theme.Layout.paddingMedium) {
                        Text("Typography")
                            .font(Theme.Typography.titleMedium)
                        
                        Text("Title Large")
                            .font(Theme.Typography.titleLarge)
                        Text("Title Medium")
                            .font(Theme.Typography.titleMedium)
                        Text("Title Small")
                            .font(Theme.Typography.titleSmall)
                        Text("Body Large")
                            .font(Theme.Typography.bodyLarge)
                        Text("Body Medium")
                            .font(Theme.Typography.bodyMedium)
                        Text("Body Small")
                            .font(Theme.Typography.bodySmall)
                    }
                }
                
                // MARK: - Buttons
                Card(style: .bordered) {
                    VStack(alignment: .leading, spacing: Theme.Layout.paddingMedium) {
                        Text("Buttons")
                            .font(Theme.Typography.titleMedium)
                        
                        PrimaryButton(title: "Regular Button", action: {})
                        
                        PrimaryButton(
                            title: "Loading Button",
                            action: {
                                isLoading = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isLoading = false
                                }
                            },
                            isLoading: isLoading
                        )
                    }
                }
                
                // MARK: - Text Fields
                Card(style: .bordered) {
                    VStack(alignment: .leading, spacing: Theme.Layout.paddingMedium) {
                        Text("Text Fields")
                            .font(Theme.Typography.titleMedium)
                        
                        CustomTextField(
                            title: "Username",
                            placeholder: "Enter your username",
                            text: $username
                        )
                        
                        CustomTextField(
                            title: "Password",
                            placeholder: "Enter your password",
                            text: $password,
                            isSecure: true,
                            errorMessage: password.count < 8 ? "Password must be at least 8 characters" : nil
                        )
                    }
                }
                
                // MARK: - Cards
                Card(style: .bordered) {
                    VStack(alignment: .leading, spacing: Theme.Layout.paddingMedium) {
                        Text("Cards")
                            .font(Theme.Typography.titleMedium)
                        
                        Card(style: .plain) {
                            Text("Plain Card")
                        }
                        
                        Card(style: .bordered) {
                            Text("Bordered Card")
                        }
                        
                        Card(style: .elevated) {
                            Text("Elevated Card")
                        }
                    }
                }
                
                // MARK: - Loading Indicators
                Card(style: .bordered) {
                    VStack(alignment: .leading, spacing: Theme.Layout.paddingMedium) {
                        Text("Loading Indicators")
                            .font(Theme.Typography.titleMedium)
                        
                        HStack(spacing: Theme.Layout.paddingLarge) {
                            LoadingIndicator(size: .small)
                            LoadingIndicator(size: .medium)
                            LoadingIndicator(size: .large)
                        }
                        .frame(maxWidth: .infinity)
                        
                        PrimaryButton(
                            title: "Show Loading Overlay",
                            action: {
                                showLoadingOverlay = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showLoadingOverlay = false
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .overlay {
            if showLoadingOverlay {
                LoadingOverlay(message: "Loading...")
            }
        }
        .navigationTitle("Component Showcase")
    }
}

#Preview {
    NavigationView {
        ComponentShowcase()
    }
} 