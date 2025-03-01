import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1  // Start with Slack tab (tab 1) selected
    @EnvironmentObject private var slackViewModel: SlackViewModel
    @State private var showingFontDebug = false
    @State private var showingTitanOneDebug = false
    @State private var showingSlackSetup = false
    @State private var showDebugControls = false
    @State private var tabChangeAnimating = false
    @State private var pulseToggleButton = false
    @State private var isDarkMode = true  // Add state for dark mode toggle
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @Environment(\.themeColors) private var colors // Use theme colors
    
    var body: some View {
        ZStack {
            // Set background color for the entire app - dynamic based on color scheme
            colors.background
                .edgesIgnoringSafeArea(.all)
            
            // Main content area with improved spacing
            VStack(spacing: 0) {
                // Header with theme toggle
                HStack {
                    // Title - single line, clean layout
                    Text("Slack Messages")
                        .font(.titanOne(size: 24))
                        .foregroundColor(colors.text)
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    // Improved theme toggle with icon
                    HStack(spacing: 8) {
                        Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(colors.text)
                            .font(.system(size: 16))
                            .imageScale(.medium)
                        
                        Toggle("", isOn: $isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: colors.accent))
                            .labelsHidden()
                            .onChange(of: isDarkMode) { oldValue, newValue in
                                // Force UI update when dark mode changes
                                withAnimation {
                                    // Update theme colors environment value
                                    // This will trigger view refresh
                                }
                            }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(colors.cardBackground)
                            .opacity(0.7)
                    )
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
                
                // Content based on selected tab - allow it to fill most of the screen
                if selectedTab == 0 {
                    // Flights Tab
                    FlightSearchViewContainer()
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        .padding(.bottom, 0) // Reduce bottom padding to maximize content area
                } else {
                    // Slack Tab
                    SlackTabView(viewModel: slackViewModel, isSelected: true, selectedTab: selectedTab)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                        .padding(.bottom, 0) // Reduce bottom padding to maximize content area
                }
                
                // Tab change indicator (subtle white flash when tab changes)
                if tabChangeAnimating {
                    Rectangle()
                        .fill(colors.accent.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                
                Spacer(minLength: 0) // Allow content to expand and push tab bar to bottom
                
                // Standard Tab Bar - fixed at bottom
                HStack(spacing: 0) {
                    // Flights button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = 0
                            tabChangeAnimating = true
                        }
                        
                        // Hide tab change animation after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                tabChangeAnimating = false
                            }
                        }
                        
                        HapticFeedbackManager.shared.selection()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "airplane")
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == 0 ? Theme.Colors.debotOrange : colors.secondaryText)
                                .scaleEffect(selectedTab == 0 ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                            
                            Text("Flights")
                                .font(.titanOne(size: 12))
                                .foregroundColor(selectedTab == 0 ? Theme.Colors.debotOrange : colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedTab == 0 {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.Colors.debotOrange.opacity(0.15))
                                        .padding(.horizontal, 12)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                        )
                    }
                    
                    // Slack button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedTab = 1
                            tabChangeAnimating = true
                        }
                        
                        // Hide tab change animation after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                tabChangeAnimating = false
                            }
                        }
                        
                        HapticFeedbackManager.shared.selection()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == 1 ? Theme.Colors.debotOrange : colors.secondaryText)
                                .scaleEffect(selectedTab == 1 ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                            
                            HStack(spacing: 2) {
                                Text("Slack")
                                    .font(.titanOne(size: 12))
                                
                                // Show badge for unread messages
                                if slackViewModel.unreadCount > 0 {
                                    Text("\(slackViewModel.unreadCount)")
                                        .font(.titanOne(size: 10))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Theme.Colors.debotOrange)
                                        .foregroundColor(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                            .foregroundColor(selectedTab == 1 ? Theme.Colors.debotOrange : colors.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                if selectedTab == 1 {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.Colors.debotOrange.opacity(0.15))
                                        .padding(.horizontal, 12)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                        )
                    }
                }
                .padding(.bottom, safeAreaInsets.bottom > 0 ? safeAreaInsets.bottom : 16)
                .background(
                    Rectangle()
                        .fill(colors.cardBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: -3)
                        .edgesIgnoringSafeArea(.bottom)
                )
                
                // Debug controls overlay - only shown when enabled
                if showDebugControls {
                    VStack {
                        // Debug buttons
                        HStack {
                            Button("Switch to Flights (0)") {
                                selectedTab = 0
                                print("Debug button: setting tab to 0")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("Switch to Slack (1)") {
                                selectedTab = 1
                                print("Debug button: setting tab to 1")
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.top, 50)
                        
                        // Emergency tab buttons (now in debug mode)
                        HStack {
                            Button(action: {
                                selectedTab = 0
                                print("🚨 EMERGENCY TAB SWITCH: Set to Flights (0)")
                            }) {
                                Text("GOTO FLIGHTS")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                selectedTab = 1
                                print("🚨 EMERGENCY TAB SWITCH: Set to Slack (1)")
                            }) {
                                Text("GOTO SLACK")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                }
            }
        }
        .environment(\.colorScheme, isDarkMode ? .dark : .light) // Set based on toggle
        .preferredColorScheme(isDarkMode ? .dark : .light)       // Also set preferred scheme
        .environment(\.themeColors, ThemeColors.colors(for: isDarkMode ? .dark : .light)) // Update theme colors
        .onChange(of: selectedTab) { oldValue, newValue in
            print("⭐️ Tab CHANGED to: \(newValue) - 0=Flights, 1=Slack")
            
            // Update pulse animation based on tab and unread count
            pulseToggleButton = slackViewModel.unreadCount > 0 && newValue == 0
            
            // Animate tab change with subtle flash
            withAnimation(.easeInOut(duration: 0.2)) {
                tabChangeAnimating = true
                
                // Turn off animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        tabChangeAnimating = false
                    }
                }
            }
        }
        .onAppear {
            // Check if there are unread messages to activate pulse animation
            pulseToggleButton = slackViewModel.unreadCount > 0 && selectedTab == 0
            
            // First, check if Titan One font is available for SwiftUI
            let fontName = "TitanOne"
            // Note: We're only checking if the font exists in the system, no need to store the result
            _ = Font.custom(fontName, size: 14)
            
            // Using UIFont to check if the font is available in the system
            if let _ = UIFont(name: fontName, size: 14) {
                print("✅ Titan One font is available at the UIKit level")
            } else {
                print("❌ Titan One font is NOT available at the UIKit level")
            }
            
            // Print all available font names to check if Titan One is registered
            for family in UIFont.familyNames.sorted() {
                let names = UIFont.fontNames(forFamilyName: family)
                if names.contains(fontName) {
                    print("✓ Found \(fontName) in family: \(family)")
                }
            }
            
            // Directly set tab bar appearance
            UITabBar.appearance().tintColor = UIColor(Color.debotOrange)
            UITabBar.appearance().unselectedItemTintColor = UIColor.darkGray
            
            // Try to load the font directly since we know the correct name
            let font = UIFont(name: fontName, size: 14)
            
            if font != nil {
                print("Successfully loaded Titan One font for tab bar: \(fontName)")
                
                // Normal state - ensure it's visible but not as prominent
                UITabBarItem.appearance().setTitleTextAttributes([
                    .font: font!,
                    .foregroundColor: UIColor.darkGray // Solid darkGray (no alpha)
                ], for: .normal)
                
                // Selected state - app accent color
                UITabBarItem.appearance().setTitleTextAttributes([
                    .font: font!,
                    .foregroundColor: UIColor(Color.debotOrange)
                ], for: .selected)
            } else {
                print("⚠️ Failed to load Titan One font for tab bar")
                
                // Attempt to use system font as fallback for tab bar
                let fallbackFont = UIFont.boldSystemFont(ofSize: 14)
                UITabBarItem.appearance().setTitleTextAttributes([
                    .font: fallbackFont,
                    .foregroundColor: UIColor.darkGray
                ], for: .normal)
                
                UITabBarItem.appearance().setTitleTextAttributes([
                    .font: fallbackFont,
                    .foregroundColor: UIColor(Color.debotOrange)
                ], for: .selected)
            }
            
            // Force Slack to use mock data if there's no token
            if !slackViewModel.isConnected && !slackViewModel.useMockData {
                slackViewModel.useMockData = true
                Task {
                    await slackViewModel.loadMessages()
                }
            }
            
            // Improve tab bar appearance for iOS 15+
            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                appearance.configureWithDefaultBackground()
                
                // Set background color based on theme
                appearance.backgroundColor = isDarkMode ? UIColor.systemGray6 : UIColor.white
                
                // If font is available, set it here too
                if let loadedFont = font {
                    // Normal state
                    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                        .font: loadedFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    
                    // Selected state
                    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                        .font: loadedFont,
                        .foregroundColor: UIColor(Color.debotOrange)
                    ]
                    
                    // Also set the icon color explicitly
                    appearance.stackedLayoutAppearance.normal.iconColor = UIColor.darkGray
                    appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.debotOrange)
                } else {
                    // Use system font as fallback
                    let fallbackFont = UIFont.boldSystemFont(ofSize: 14)
                    // Normal state
                    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                        .font: fallbackFont,
                        .foregroundColor: UIColor.darkGray
                    ]
                    
                    // Selected state
                    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                        .font: fallbackFont,
                        .foregroundColor: UIColor(Color.debotOrange)
                    ]
                }
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            
            // Force tab bar items to use correct tint
            DispatchQueue.main.async {
                // Color for both modes
                let accentColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0) // debotOrange
                
                // This extra async dispatch helps ensure the tab bar styling applies
                UITabBar.appearance().tintColor = accentColor
                UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
            }
            
            // Force update UI components with the current theme
            DispatchQueue.main.async {
                // Post notification to refresh theme colors
                NotificationCenter.default.post(name: Notification.Name.refreshThemeColors, object: nil)
                
                // Force update tab bar appearance for dark/light mode using system colors
                if #available(iOS 15.0, *) {
                    let appearance = UITabBarAppearance()
                    appearance.configureWithDefaultBackground()
                    
                    // Configure tab bar with system colors for consistency
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
        .onChange(of: slackViewModel.unreadCount) { oldValue, newValue in
            // Activate pulse effect if there are unread messages and user is on Flights tab
            pulseToggleButton = newValue > 0 && selectedTab == 0
        }
        .onChange(of: isDarkMode) { oldValue, newValue in
            // Force UI update when dark mode changes
            withAnimation {
                // Update theme colors environment value
                // This will trigger view refresh
            }

            // Force tab bar items to use correct tint
            DispatchQueue.main.async {
                // Color for both modes
                let accentColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0) // debotOrange
                
                // This extra async dispatch helps ensure the tab bar styling applies
                UITabBar.appearance().tintColor = accentColor
                UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel
            }
            
            // Force update UI components with the current theme
            DispatchQueue.main.async {
                // Post notification to refresh theme colors
                NotificationCenter.default.post(name: Notification.Name.refreshThemeColors, object: nil)
                
                // Force update tab bar appearance for dark/light mode using system colors
                if #available(iOS 15.0, *) {
                    let appearance = UITabBarAppearance()
                    appearance.configureWithDefaultBackground()
                    
                    // Configure tab bar with system colors for consistency
                    UITabBar.appearance().standardAppearance = appearance
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
        .sheet(isPresented: $showingFontDebug) {
            FontDebugView()
        }
        .sheet(isPresented: $showingTitanOneDebug) {
            TitanOneDebug()
        }
        .sheet(isPresented: $showingSlackSetup) {
            SlackSetupView(viewModel: slackViewModel)
        }
        .onLongPressGesture(minimumDuration: 2) {
            print("Long press detected - showing font debug")
            showingFontDebug = true
        }
        .simultaneousGesture(
            TapGesture(count: 3)
                .onEnded {
                    print("Triple tap detected - showing TitanOne debug")
                    showingTitanOneDebug = true
                }
        )
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)  // Increased minimum distance to avoid accidental triggers
                .simultaneously(with: TapGesture(count: 2))
                .onEnded { _ in
                    withAnimation {
                        showDebugControls.toggle()
                    }
                    print("Debug controls: \(showDebugControls ? "SHOWN" : "HIDDEN")")
                }
        )
    }
}

// Helper view to pass the viewModel to SlackMessagesView
struct SlackTabView: View {
    let viewModel: SlackViewModel
    let isSelected: Bool
    let selectedTab: Int  // Add this parameter to fix the scope error
    @State private var showingConfigSheet = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors
    
    var body: some View {
        VStack(spacing: 0) { // No spacing to maximize content area
            // Common styling for SlackMessagesView with improved dark mode support
            let messagesView = SlackMessagesView(viewModel: viewModel, showingFlights: selectedTab == 0)
                .padding(.horizontal, 6) // Minimal horizontal padding
                .padding(.vertical, 4)   // Minimal vertical padding
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.cardBackground)
                        .shadow(color: Color.black.opacity(0.1), 
                                radius: 2, x: 0, y: 1) // Reduced shadow
                )
                .padding(.horizontal, 4) // Minimal horizontal padding
                .environment(\.colorScheme, colorScheme) // Ensure colorScheme is properly passed down
            
            if viewModel.useMockData {
                messagesView
            } else {
                messagesView
            }
        }
        .frame(maxHeight: .infinity) // Expand to fill all available space
    }
}

// Simple setup view for Slack configuration
struct SlackSetupView: View {
    @ObservedObject var viewModel: SlackViewModel
    @State private var apiToken = ""
    @State private var isTestingConnection = false
    @State private var testResult: String?
    @State private var isTokenSaved = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.themeColors) private var colors // Add theme colors
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Slack API Configuration").headerStyle()) {
                    TextField("Slack Bot Token (xoxb-...)", text: $apiToken)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .inputFieldStyle()
                    
                    Button(action: {
                        saveToken()
                    }) {
                        Text("Save Token")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.PrimaryButtonStyle())
                    .disabled(apiToken.isEmpty || !apiToken.hasPrefix("xoxb-"))
                    .padding(.vertical, 8)
                    
                    if isTokenSaved {
                        Text("Token saved successfully!")
                            .foregroundColor(.green)
                            .font(.cooperSmall)
                            .padding(.vertical, 4)
                    }
                    
                    Divider()
                    
                    Button(action: {
                        isTestingConnection = true
                        Task {
                            testResult = await viewModel.testAPIConnection()
                            isTestingConnection = false
                            
                            // If the test was successful and using real data, reload messages
                            if testResult?.contains("Success") == true && !viewModel.useMockData {
                                await viewModel.loadMessages()
                            }
                        }
                    }) {
                        Text("Test Connection")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(Theme.SecondaryButtonStyle())
                    .disabled(isTestingConnection)
                    .padding(.vertical, 8)
                    
                    if isTestingConnection {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.vertical, 8)
                    }
                    
                    if let result = testResult {
                        Text(result)
                            .foregroundColor(result.contains("Success") ? .green : .red)
                            .font(.cooperSmall)
                            .padding(.vertical, 8)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section(header: Text("Mock Data").headerStyle()) {
                    Toggle("Use Mock Data", isOn: $viewModel.useMockData)
                        .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.debotOrange))
                        .onChange(of: viewModel.useMockData) { oldValue, newValue in
                            Task {
                                await viewModel.loadMessages()
                            }
                        }
                    
                    if viewModel.useMockData {
                        Text("Using mock data for demonstration. To use real Slack data, toggle this off and configure a valid token above.")
                            .font(.cooperSmall)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section(header: Text("Help").headerStyle()) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To use Slack integration:")
                            .font(.cooperSmall)
                            .foregroundColor(.secondary)
                        
                        Text("1. Create a Slack app at api.slack.com")
                            .font(.cooperSmall)
                        
                        Text("2. Add Bot Token Scopes: channels:read, channels:history, chat:write")
                            .font(.cooperSmall)
                        
                        Text("3. Install the app to your workspace")
                            .font(.cooperSmall)
                        
                        Text("4. Copy the Bot User OAuth Token starting with xoxb-")
                            .font(.cooperSmall)
                        
                        Text("5. Paste the token above and save")
                            .font(.cooperSmall)
                        
                        Text("6. Invite the bot to channels in your Slack workspace")
                            .font(.cooperSmall)
                            .padding(.bottom, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Slack Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Done")
                            .foregroundColor(Theme.Colors.debotOrange)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onAppear {
            // Try to load existing token if available
            let token = SlackAPI.shared.botToken
            if token != "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" && !token.isEmpty {
                // Only show first few chars for security
                if token.count > 10 {
                    let prefix = String(token.prefix(10))
                    apiToken = "\(prefix)..."
                } else {
                    apiToken = token
                }
            }
        }
    }
    
    private func saveToken() {
        guard !apiToken.isEmpty else { return }
        
        // Remove any "..." that might have been added for display purposes
        var cleanToken = apiToken
        if cleanToken.hasSuffix("...") {
            cleanToken = String(cleanToken.prefix(10))
        }
        
        // Try to save the token using the SlackTokenManager
        let tokenManager = SlackTokenManager.shared
        if tokenManager.saveToken(cleanToken) {
            isTokenSaved = true
            
            // Attempt to reload with new token
            Task {
                // Force non-mock mode after saving a token
                viewModel.useMockData = false
                await viewModel.loadMessages()
                
                // After a delay, hide the success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isTokenSaved = false
                }
            }
        } else {
            testResult = "Failed to save token. Please manually update SlackConfig.plist"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SlackViewModel())
        // Remove the light mode preference to test with system setting
}

// Font extension to safely use custom fonts with fallbacks
extension Font {
    static func titanOne(size: CGFloat) -> Font {
        let fontName = "TitanOne"
        guard UIFont(name: fontName, size: size) != nil else {
            print("⚠️ TitanOne font not available, using fallback")
            return .system(size: size, weight: .bold)
        }
        return .custom(fontName, size: size)
    }
}

// Add environment extension to force theme update
extension Notification.Name {
    static let refreshThemeColors = Notification.Name("RefreshThemeColors")
} 