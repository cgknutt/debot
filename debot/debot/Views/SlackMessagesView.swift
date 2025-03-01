import SwiftUI
import Foundation
import Combine // Added for publishers

// These types are part of the same module and don't need explicit imports
// import struct debot.SlackMessage
// import struct debot.SlackAttachment
// import struct debot.SlackReaction
// import class debot.SlackViewModel
// import struct debot.ThemeColors

// Professional color scheme with light/dark mode support
extension Color {
    // Hex color initializer with unique name to avoid conflicts
    init(uiHex: String) {
        let hex = uiHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Base colors - with dark/light variants using system colors
    static func bgPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.systemBackground) : Color(UIColor.systemBackground)
    }
    
    static func bgSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.secondarySystemBackground)
    }
    
    static func bgTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.tertiarySystemBackground) : Color(UIColor.tertiarySystemBackground)
    }
    
    // Base colors - legacy support
    static let bgPrimary = Color(UIColor.systemBackground)
    static let bgSecondary = Color(UIColor.secondarySystemBackground)
    static let bgTertiary = Color(UIColor.tertiarySystemBackground)
    
    // Accent colors
    static let accentPrimary = Theme.Colors.debotOrange // Use our brand color from Theme
    static let accentSecondary = Theme.Colors.debotOrange.opacity(0.85)
    static let accentTertiary = Theme.Colors.debotOrange.opacity(0.7)
    
    // Text colors - with dark/light variants
    static func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.label) : Color(UIColor.label)
    }
    
    static func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.secondaryLabel) : Color(UIColor.secondaryLabel)
    }
    
    static func textTertiary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(UIColor.tertiaryLabel) : Color(UIColor.tertiaryLabel)
    }
    
    // Text colors - legacy support
    static let textPrimary = Color(UIColor.label)
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let textTertiary = Color(UIColor.tertiaryLabel)
    
    // Status colors
    static let statusSuccess = Color(UIColor.systemGreen).opacity(0.9)
    static let statusWarning = Color(UIColor.systemOrange).opacity(0.9)
    static let statusInfo = Theme.Colors.debotOrange.opacity(0.9)
    static let statusError = Color(UIColor.systemRed).opacity(0.9)
    
    // Divider colors with dark/light mode support
    static func dividerColor(for scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.1)
    }
    
    // For legacy support
    static let dividerColor = Color.gray.opacity(0.2)
}

// MARK: - Theme Colors Environment Key
// Using the implementation from SharedModels.swift instead of duplicating here

// Animation constants for consistent animations throughout the app
struct AppAnimation {
    static let standard = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let quick = Animation.spring(response: 0.2, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    
    static func easeTransition(_ view: some View) -> some View {
        view.animation(.easeInOut(duration: 0.2), value: UUID())
    }
}

// Improved transition effect for view changes
struct SlideTransition: ViewModifier {
    let isActive: Bool
    let direction: Edge
    
    func body(content: Content) -> some View {
        content
            .transition(
                .asymmetric(
                    insertion: .move(edge: direction).combined(with: .opacity),
                    removal: .move(edge: direction.opposite).combined(with: .opacity)
                )
            )
    }
}

extension Edge {
    var opposite: Edge {
        switch self {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }
}

// Accessibility labels helper function
func accessibilityLabel(for text: String, context: String? = nil) -> String {
    if let context = context {
        return "\(text), \(context)"
    }
    return text
}

// MARK: - Accessibility Traits Extension
extension View {
    func accessibilityAction(named label: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: Text(label), action)
    }
    
    func improvedSemantics(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        var modifiedView = self
            .accessibilityLabel(Text(label))
            .accessibilityAddTraits(traits)
        
        if let hint = hint {
            modifiedView = modifiedView.accessibilityHint(Text(hint))
        }
        
        return modifiedView
    }
}

// Capsule button style for small actions
struct CapsuleButtonStyle: ButtonStyle {
    var isActive: Bool = false
    var hasBadge: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isActive ? Color.accentPrimary.opacity(0.9) : Color.bgTertiary.opacity(0.8))
            )
            .foregroundColor(isActive ? .white : .textSecondary)
            .overlay(
                Capsule()
                    .strokeBorder(
                        isActive ? Color.accentPrimary : Color.textTertiary.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// App header style with color scheme support
struct AppHeaderStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Color.textPrimary(for: colorScheme))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.bgPrimary(for: colorScheme)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.1 : 0.05), radius: 2, x: 0, y: 1)
            )
    }
}

// Badge modifier
struct BadgeModifier: ViewModifier {
    var count: Int
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if count > 0 {
                        Circle()
                            .fill(Color.statusError)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text("\(min(count, 99))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 14, y: -8)
                            .accessibilityLabel(Text("\(count) new messages"))
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
            )
    }
}

// ViewModel extension for search capability
extension SlackViewModel {
    func searchMessages(query: String) -> [SlackMessage] {
        guard !query.isEmpty else { return messages }
        
        return messages.filter { message in
            message.text.localizedCaseInsensitiveContains(query) ||
            message.userName.localizedCaseInsensitiveContains(query)
        }
    }
}

// Size preferences for compact mode
enum SizePreference: String, CaseIterable, Identifiable {
    case compact = "Compact"
    case regular = "Regular"
    
    var id: String { self.rawValue }
    
    // Scaling factors for UI elements
    var fontScale: CGFloat {
        switch self {
        case .compact: return 0.85
        case .regular: return 1.0
        }
    }
    
    var paddingScale: CGFloat {
        switch self {
        case .compact: return 0.8
        case .regular: return 1.0
        }
    }
    
    var iconScale: CGFloat {
        switch self {
        case .compact: return 0.85
        case .regular: return 1.0
        }
    }
}

// Keyboard Shortcut Handling for iOS
struct KeyboardShortcutHandler: ViewModifier {
    let toggleMessages: () -> Void
    let toggleFlights: () -> Void
    let toggleSearch: () -> Void
    let toggleCompactMode: () -> Void
    let refreshData: () -> Void
    
    func body(content: Content) -> some View {
        content
            // Use KeyEquivalent for keyboard shortcuts
            .keyboardShortcut(KeyEquivalent("1"), modifiers: [.command])
            .keyboardShortcut(KeyEquivalent("2"), modifiers: [.command])
            .keyboardShortcut(KeyEquivalent("f"), modifiers: [.command])
            .keyboardShortcut(KeyEquivalent("0"), modifiers: [.command])
            .keyboardShortcut(KeyEquivalent("r"), modifiers: [.command])
    }
}

// Hover Effect Modifier for iOS (simplified version)
struct HoverEffectModifier: ViewModifier {
    @State private var isPressed: Bool = false
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            // Use onLongPressGesture instead of onHover for iOS
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 10, pressing: { pressing in
                isPressed = pressing
            }, perform: { })
    }
}

// Subtle Parallax Effect for Cards
struct ParallaxMotionModifier: ViewModifier {
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    let amount: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    xOffset = amount
                    yOffset = amount
                }
            }
    }
}

// MARK: - Environment and Device Handling

// Device size detection for layout adaptation
enum DeviceSize {
    case small, medium, large
    
    static var current: DeviceSize {
        let screenWidth = UIScreen.main.bounds.width
        switch screenWidth {
        case 0..<375: return .small
        case 375..<414: return .medium
        default: return .large
        }
    }
}

// Environment keys for safe area insets
struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

// Time zone aware formatter
class TimeZoneAwareFormatter {
    static let shared = TimeZoneAwareFormatter()
    
    private let dateFormatter: DateFormatter
    private let relativeDateFormatter: RelativeDateTimeFormatter
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .none
        
        relativeDateFormatter = RelativeDateTimeFormatter()
        relativeDateFormatter.unitsStyle = .abbreviated
        relativeDateFormatter.dateTimeStyle = .named
    }
    
    func formatTime(_ date: Date, inUserTimeZone: Bool = true) -> String {
        if inUserTimeZone {
            dateFormatter.timeZone = TimeZone.current
        }
        return dateFormatter.string(from: date)
    }
    
    func formatRelativeTime(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return minutes <= 1 ? "Just now" : "\(minutes)m ago"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h ago"
        } else if let days = components.day, days < 7 {
            return "\(days)d ago"
        } else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            let result = dateFormatter.string(from: date)
            dateFormatter.dateStyle = .none
            dateFormatter.timeStyle = .short
            return result
        }
    }
    
    func accessibleDateFormat(_ date: Date) -> String {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let result = dateFormatter.string(from: date)
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return result
    }
}

// MARK: - Error handling and retry
class ErrorManager {
    static let shared = ErrorManager()
    
    private var retryCount: [String: Int] = [:]
    private let maxRetries = 3
    
    func shouldRetry(forOperation operation: String) -> Bool {
        let currentCount = retryCount[operation] ?? 0
        if currentCount < maxRetries {
            retryCount[operation] = currentCount + 1
            return true
        }
        return false
    }
    
    func resetRetry(forOperation operation: String) {
        retryCount[operation] = 0
    }
    
    func getRetryDelay(forOperation operation: String) -> TimeInterval {
        let currentCount = retryCount[operation] ?? 0
        // Exponential backoff: 1s, 2s, 4s
        return pow(2.0, Double(currentCount - 1))
    }
    
    func hasExceededRetries(forOperation operation: String) -> Bool {
        let currentCount = retryCount[operation] ?? 0
        return currentCount >= maxRetries
    }
}

// Message row component
struct MessageRow: View {
    let message: SlackMessage
    let viewModel: SlackViewModel
    let showReactionPicker: () -> Void
    let showThreadView: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.themeColors) var themeColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Message header
            HStack(alignment: .center, spacing: 8) {
                // User avatar (placeholder or real)
                if let avatarUrl = message.userAvatar, !avatarUrl.isEmpty {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    // Default avatar
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.debotOrange.opacity(0.2))
                        
                        Text(String(message.userName.prefix(1).uppercased()))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.Colors.debotOrange)
                    }
                    .frame(width: 36, height: 36)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    // Username
                    Text(message.userName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.textPrimary(for: colorScheme))
                    
                    // Channel and time
                    HStack(spacing: 4) {
                        Text("#\(message.channelName)")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.Colors.debotOrange)
                        
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                        
                        Text(message.timestamp.timeAgoDisplay())
                            .font(.system(size: 13))
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                    }
                }
                
                Spacer()
                
                // Message actions
                HStack(spacing: 12) {
                    // Reply button for thread parent messages
                    if message.isThreadParent || message.replyCount ?? 0 > 0 {
                        Button(action: showThreadView) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 12))
                                
                                if let replyCount = message.replyCount, replyCount > 0 {
                                    Text("\(replyCount)")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.bgSecondary(for: colorScheme))
                            )
                        }
                    }
                    
                    // Reaction button
                    Button(action: showReactionPicker) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary(for: colorScheme))
                            .padding(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.bgSecondary(for: colorScheme))
                            )
                    }
                }
            }
            
            // Message text
            Text(message.text)
                .font(.system(size: 15))
                .foregroundColor(Color.textPrimary(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            // Attachments if any
            if !message.attachments.isEmpty {
                ForEach(message.attachments) { attachment in
                    SlackAttachmentView(attachment: attachment)
                }
            }
            
            // Reactions if any
            if let reactions = message.reactions, !reactions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(reactions) { reaction in
                        Button(action: {
                            viewModel.toggleReaction(emoji: reaction.name, messageId: message.id)
                        }) {
                            HStack(spacing: 4) {
                                Text(":\(reaction.name):")
                                    .font(.system(size: 14))
                                Text("\(reaction.count)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(reaction.userHasReacted(currentUserId: viewModel.currentUserId) ? 
                                        Theme.Colors.debotOrange.opacity(0.15) : 
                                        Color.bgSecondary(for: colorScheme))
                            )
                            .foregroundColor(reaction.userHasReacted(currentUserId: viewModel.currentUserId) ? 
                                Theme.Colors.debotOrange : 
                                Color.textPrimary(for: colorScheme))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.bgSecondary(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.dividerColor(for: colorScheme), lineWidth: 0.5)
        )
    }
}

// MARK: - SlackAttachmentView
struct SlackAttachmentView: View {
    let attachment: SlackAttachment
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = attachment.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.textPrimary(for: colorScheme))
            }
            
            if let text = attachment.text, !text.isEmpty {
                Text(text)
                    .font(.system(size: 13))
                    .foregroundColor(Color.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let imageUrl = attachment.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/1, contentMode: .fit)
                }
                .cornerRadius(8)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.bgTertiary(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    attachment.color != nil ? 
                        attachment.color! : 
                        Color.dividerColor(for: colorScheme),
                    lineWidth: 2
                )
                .padding(0.5)
        )
    }
}

struct SlackMessagesView: View {
    @ObservedObject var viewModel: SlackViewModel
    @Environment(\.themeColors) var themeColors
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.safeAreaInsets) var safeAreaInsets
    
    // Screen reader settings
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // Device adaptations
    @State private var deviceSize = DeviceSize.current
    @State private var orientation = UIDevice.current.orientation
    
    @State private var selectedChannelId: String? = nil
    @State private var searchText: String = ""
    @State private var messageText: String = ""
    @State private var showingReactionPicker: Bool = false
    @State private var reactionTargetMessage: String? = nil
    @State private var showingThreadView: Bool = false
    @State private var threadParentId: String? = nil
    @State private var threadMessage: String = ""
    @State private var isComposing: Bool = false
    @State private var viewMode: ViewMode = .weekly
    @State private var isSearchActive: Bool = false
    @State private var sizePreference: SizePreference = .regular
    
    // Use this to prevent multiple simultaneous animations
    @State private var isAnimating: Bool = false
    
    // Enhanced transitions
    @Namespace private var animation
    @State private var activeTab: String = "Messages"
    
    // Animation states for micro-interactions
    @State private var messageInputFieldFocused = false
    @State private var refreshButtonPressed = false
    @State private var lastRefreshTime: Date = Date()
    
    // Keyboard handling for text fields
    @State private var keyboardHeight: CGFloat = 0
    private let keyboardPublisher = Publishers.Merge(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            },
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }
    ).eraseToAnyPublisher()
    
    // View mode for segmented control
    enum ViewMode {
        case weekly, monthly
    }
    
    // External state for showing flights or messages
    var showingFlights: Bool = false
    
    @State private var showSlackSetup = false // Added state for setup sheet
    @State private var isPressed = false // For button animation
    
    // Add this after the other @State variables
    @State private var visibleMessageIds: [String] = []
    
    init(viewModel: SlackViewModel, showingFlights: Bool = false) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.showingFlights = showingFlights
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.bgPrimary(for: colorScheme).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content with safe area handling
                    if showingFlights {
                        flightsView
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .animation(reduceMotion ? .default : .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1), value: showingFlights)
                    } else {
                        messagesView
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                            .animation(reduceMotion ? .default : .spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.1), value: showingFlights)
                    }
                    
                    // No bottom navigation - it's handled by ContentView
                }
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 10, x: 0, y: 5)
                .padding(.bottom, keyboardHeight > 0 ? keyboardHeight - safeAreaInsets.bottom : 0)
                .animation(.easeOut(duration: 0.25), value: keyboardHeight)
            }
            .onReceive(keyboardPublisher) { height in
                self.keyboardHeight = height
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                self.orientation = UIDevice.current.orientation
                self.deviceSize = DeviceSize.current
            }
            .onAppear {
                refreshMessages()
                
                // Initialize voice over optimizations
                if voiceOverEnabled {
                    // Note: We don't need to set these manually, SwiftUI handles this automatically
                    // based on the user's device settings. The @Environment values above
                    // give us access to the current state.
                }
            }
        }
        .sheet(isPresented: $showSlackSetup) {
            SlackSetupView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingReactionPicker) {
            reactionPickerView
        }
        .sheet(isPresented: $showingThreadView) {
            threadView
        }
    }
    
    // Messages view with accessibility improvements
    private var messagesView: some View {
        VStack(spacing: 0) {
            // Header with accessibility
            HStack {
                Text("Messages")
                    .font(.system(size: 17 * sizePreference.fontScale, weight: .semibold))
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                // Search button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isSearchActive.toggle()
                        if !isSearchActive {
                            searchText = ""
                        }
                    }
                }) {
                    Image(systemName: isSearchActive ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8 * sizePreference.paddingScale)
                }
                .buttonStyle(Theme.IconButtonStyle(
                    size: 44 * sizePreference.iconScale,
                    bgColor: Theme.Colors.debotOrange
                ))
                .improvedSemantics(
                    label: isSearchActive ? "Clear Search" : "Search Messages",
                    hint: isSearchActive ? "Clear search query" : "Search for messages"
                )
                
                // Setup button
                Button(action: {
                    showSlackSetup = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8 * sizePreference.paddingScale)
                }
                .buttonStyle(Theme.IconButtonStyle(
                    size: 44 * sizePreference.iconScale,
                    bgColor: Theme.Colors.debotGold
                ))
                .improvedSemantics(
                    label: "Slack Setup",
                    hint: "Configure Slack settings"
                )
            }
            .padding(.top, safeAreaInsets.top > 0 ? safeAreaInsets.top : 0)
            .padding(.horizontal, 16 * sizePreference.paddingScale)
            .padding(.vertical, 8 * sizePreference.paddingScale)
            .background(Color.bgPrimary(for: colorScheme))
            
            // Search bar
            if isSearchActive {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14 * sizePreference.iconScale))
                        .foregroundColor(.textTertiary)
                    
                    TextField("Search messages...", text: $searchText)
                        .font(.system(size: 14 * sizePreference.fontScale))
                        .foregroundColor(.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14 * sizePreference.iconScale))
                                .foregroundColor(.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12 * sizePreference.paddingScale)
                .padding(.vertical, 8 * sizePreference.paddingScale)
                .background(Color.bgTertiary(for: colorScheme).opacity(0.6))
                .cornerRadius(8)
                .padding(.horizontal, 16 * sizePreference.paddingScale)
                .padding(.vertical, 6 * sizePreference.paddingScale)
                .background(Color.bgSecondary(for: colorScheme))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Channel selector
            HStack(spacing: 12 * sizePreference.paddingScale) {
                Menu {
                    Button("All Channels", action: {
                        selectedChannelId = nil
                    })
                    
                    ForEach(viewModel.channels) { channel in
                        Button(action: {
                            selectedChannelId = channel.id
                        }) {
                            Text(channel.name)
                        }
                    }
                } label: {
                    HStack(spacing: 5 * sizePreference.paddingScale) {
                        Image(systemName: "number")
                            .font(.system(size: 12 * sizePreference.iconScale, weight: .medium))
                            .foregroundColor(.accentPrimary)
                        
                        Text(selectedChannelName)
                            .font(.system(size: 13 * sizePreference.fontScale, weight: .medium))
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9 * sizePreference.iconScale, weight: .semibold))
                    }
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 12 * sizePreference.paddingScale)
                    .padding(.vertical, 6 * sizePreference.paddingScale)
                    .background(Color.bgTertiary(for: colorScheme))
                    .cornerRadius(8)
                }
                
                Spacer()
            
                Button(action: {
                    refreshMessages()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12 * sizePreference.iconScale))
                        .foregroundColor(.textSecondary)
                        .padding(6 * sizePreference.paddingScale)
                        .background(Color.bgTertiary(for: colorScheme))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16 * sizePreference.paddingScale)
            .padding(.vertical, 6 * sizePreference.paddingScale)
            .background(Color.bgSecondary(for: colorScheme))
            
            // Messages list - expanded to fill more space
            if viewModel.isLoading {
                Spacer()
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentPrimary))
                        .scaleEffect(0.8 * sizePreference.iconScale)
                    
                    Text("Loading messages...")
                        .font(.system(size: 12 * sizePreference.fontScale))
                        .foregroundColor(.textSecondary)
                        .accessibilityLabel("Loading messages")
                }
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 8 * sizePreference.paddingScale) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 24 * sizePreference.iconScale))
                        .foregroundColor(.statusWarning)
                    
                    Text("Error loading messages")
                        .font(.system(size: 14 * sizePreference.fontScale, weight: .medium))
                        .foregroundColor(.textSecondary)
                    
                    if ErrorManager.shared.shouldRetry(forOperation: "loadMessages") {
                        Text("Retrying in \(Int(ErrorManager.shared.getRetryDelay(forOperation: "loadMessages"))) seconds...")
                            .font(.system(size: 12 * sizePreference.fontScale))
                            .foregroundColor(.textTertiary)
                    } else {
                        Button("Retry") {
                            ErrorManager.shared.resetRetry(forOperation: "loadMessages")
                            refreshMessages()
                        }
                        .font(.system(size: 14 * sizePreference.fontScale, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 16 * sizePreference.paddingScale)
                        .padding(.vertical, 8 * sizePreference.paddingScale)
                        .background(Color.bgTertiary(for: colorScheme))
                        .cornerRadius(8)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error loading messages. Tap to retry.")
                Spacer()
            } else if displayedMessages.isEmpty {
                Spacer()
                VStack(spacing: 8 * sizePreference.paddingScale) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 24 * sizePreference.iconScale))
                        .foregroundColor(.textTertiary)
                    
                    if !searchText.isEmpty {
                        Text("No messages match your search")
                            .font(.system(size: 14 * sizePreference.fontScale, weight: .medium))
                            .foregroundColor(.textSecondary)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 14 * sizePreference.fontScale, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
            } else {
                messageList
            }
            
            // Message input
            if let channelId = selectedChannelId {
                HStack(spacing: 8 * sizePreference.paddingScale) {
                    HStack {
                        TextField("Message", text: $messageText)
                            .font(.system(size: 14 * sizePreference.fontScale))
                            .foregroundColor(.textPrimary)
                            .padding(.leading, 12 * sizePreference.paddingScale)
                        
                        Spacer()
                    }
                    .frame(height: 36 * sizePreference.iconScale)
                    .background(Color.bgTertiary(for: colorScheme))
                    .cornerRadius(18 * sizePreference.iconScale)
                
                Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24 * sizePreference.iconScale))
                            .foregroundColor(messageText.isEmpty ? .textTertiary : .accentPrimary)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding(.horizontal, 16 * sizePreference.paddingScale)
                .padding(.vertical, 8 * sizePreference.paddingScale)
                .background(Color.bgSecondary(for: colorScheme))
            }
        }
    }
    
    // Flights view with accessibility improvements
    private var flightsView: some View {
        VStack(spacing: 0) {
            // Header with accessibility
            HStack {
                Text("Flights")
                    .font(.system(size: 17 * sizePreference.fontScale, weight: .semibold))
                    .foregroundColor(Color.textPrimary(for: colorScheme))
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button(action: {
                    // Refresh flight data (placeholder)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14 * sizePreference.iconScale))
                        .foregroundColor(.accentPrimary)
                }
            }
            .padding(.top, safeAreaInsets.top > 0 ? safeAreaInsets.top : 0)
            .padding(.horizontal, 16 * sizePreference.paddingScale)
            .padding(.vertical, 12 * sizePreference.paddingScale)
            .background(Color.bgPrimary(for: colorScheme))
            
            // Flight list
            ScrollView {
                LazyVStack(spacing: 12 * sizePreference.paddingScale) {
                    ForEach(["SFO", "JFK", "LHR", "NRT"], id: \.self) { code in
                        flightCard(
                            code: code,
                            destination: destinationName(for: code),
                            time: flightTime(for: code),
                            status: flightStatus(for: code),
                            gate: "Gate \(["A4", "B12", "C7", "D3"].randomElement()!)"
                        )
                        .id(code) // Use ID for better list diffing
                    }
                }
                .padding(.horizontal, 16 * sizePreference.paddingScale)
                .padding(.vertical, 16 * sizePreference.paddingScale)
            }
        }
    }
    
    // Message row with improved screen reader support
    private func messageRow(message: SlackMessage) -> some View {
        VStack(alignment: .leading, spacing: 6 * sizePreference.paddingScale) {
            HStack(spacing: 8 * sizePreference.paddingScale) {
                // User avatar
                ZStack {
                    Circle()
                        .fill(userColor(message.userName))
                        .frame(width: 32 * sizePreference.iconScale, height: 32 * sizePreference.iconScale)
                    
                    Text(String(message.userName.prefix(1)).uppercased())
                        .font(.system(size: 14 * sizePreference.fontScale, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2 * sizePreference.paddingScale) {
                    HStack {
                        Text(message.userName)
                            .font(.system(size: 13 * sizePreference.fontScale, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        Text(formatTime(message.timestamp))
                            .font(.system(size: 11 * sizePreference.fontScale))
                            .foregroundColor(.textTertiary)
                    }
                    
                    Text(message.text)
                        .font(.system(size: 14 * sizePreference.fontScale))
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Display reactions if any
                    if let reactions = message.reactions, !reactions.isEmpty {
                        HStack(spacing: 4 * sizePreference.paddingScale) {
                            ForEach(reactions) { reaction in
                                HStack(spacing: 2) {
                                    Text(reaction.emoji)
                                        .font(.system(size: 12 * sizePreference.fontScale))
                                    Text("\(reaction.count)")
                                        .font(.system(size: 10 * sizePreference.fontScale))
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.horizontal, 6 * sizePreference.paddingScale)
                                .padding(.vertical, 2 * sizePreference.paddingScale)
                                .background(
                                    Capsule()
                                        .fill(Color.bgTertiary(for: colorScheme).opacity(0.6))
                                )
                                .onTapGesture {
                                    viewModel.toggleReaction(emoji: reaction.name, messageId: message.id)
                                }
                            }
                        }
                        .padding(.top, 4 * sizePreference.paddingScale)
                    }
                }
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                // Add reaction button
                Button(action: {
                    showReactionPicker(for: message.id)
                }) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 12 * sizePreference.iconScale))
                        .foregroundColor(.textTertiary)
                }
                .buttonStyle(Theme.IconButtonStyle(
                    size: 28 * sizePreference.iconScale,
                    bgColor: Color.bgTertiary(for: colorScheme).opacity(0.6)
                ))
                .improvedSemantics(
                    label: "Add Reaction",
                    hint: "Add emoji reaction to this message"
                )
                
                // Reply button (if it's a thread parent or has a thread parent)
                if message.isThreadParent || message.threadParentId != nil {
                    Button(action: {
                        // Show thread view
                        threadParentId = message.isThreadParent ? message.id : message.threadParentId
                        withAnimation {
                            showingThreadView = true
                        }
                    }) {
                        HStack(spacing: 4 * sizePreference.paddingScale) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 12 * sizePreference.iconScale))
                            
                            if let replyCount = message.replyCount, replyCount > 0 {
                                Text("\(replyCount)")
                                    .font(.system(size: 12 * sizePreference.fontScale))
                            }
                        }
                        .foregroundColor(.textTertiary)
                    }
                    .buttonStyle(Theme.IconButtonStyle(
                        size: 28 * sizePreference.iconScale,
                        bgColor: Color.bgTertiary(for: colorScheme).opacity(0.6)
                    ))
                    .improvedSemantics(
                        label: "View Thread",
                        hint: "View message thread with replies"
                    )
                }
            }
            .padding(.top, 4 * sizePreference.paddingScale)
        }
        .padding(12 * sizePreference.paddingScale)
        .background(Color.bgSecondary(for: colorScheme))
        .cornerRadius(12)
        .modifier(HoverEffectModifier(scale: reduceMotion ? 1.0 : 1.01))
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: UUID())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Message from \(message.userName)")
        .accessibilityValue(message.text)
        .accessibilityHint("Sent \(TimeZoneAwareFormatter.shared.accessibleDateFormat(message.timestamp))")
        .accessibilityAction(named: "Reply") {
            // Future functionality for replying
        }
        .contentShape(Rectangle()) // Make the entire area tappable
        .onTapGesture {
            // Visual feedback when tapped
            if !reduceMotion {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
            }
            
            // Future functionality for message details
        }
    }
    
    // Show reaction picker for a message
    private func showReactionPicker(for messageId: String) {
        reactionTargetMessage = messageId
        withAnimation {
            showingReactionPicker = true
        }
    }
    
    // Flight card with improved accessibility
    private func flightCard(code: String, destination: String, time: String, status: String, gate: String) -> some View {
        VStack(alignment: .leading, spacing: 12 * sizePreference.paddingScale) {
            // Header row
            HStack {
                Text(code)
                    .font(.system(size: 18 * sizePreference.fontScale, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                statusBadge(status)
            }
            
            Divider()
                .background(Color.textTertiary(for: colorScheme).opacity(0.3))
            
            // Info row
            HStack(spacing: 16 * sizePreference.paddingScale) {
                VStack(alignment: .leading, spacing: 4 * sizePreference.paddingScale) {
                    Text("Destination")
                        .font(.system(size: 12 * sizePreference.fontScale))
                        .foregroundColor(.textTertiary)
                    
                    Text(destination)
                        .font(.system(size: 14 * sizePreference.fontScale, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4 * sizePreference.paddingScale) {
                    Text("Departure")
                        .font(.system(size: 12 * sizePreference.fontScale))
                        .foregroundColor(.textTertiary)
                    
                    Text(time)
                        .font(.system(size: 14 * sizePreference.fontScale, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Gate info
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 14 * sizePreference.iconScale))
                    .foregroundColor(.accentPrimary)
                
                Text(gate)
                    .font(.system(size: 13 * sizePreference.fontScale, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Details")
                        .font(.system(size: 12 * sizePreference.fontScale, weight: .medium))
                        .foregroundColor(.accentPrimary)
                        .padding(.horizontal, 12 * sizePreference.paddingScale)
                        .padding(.vertical, 4 * sizePreference.paddingScale)
                        .background(Color.accentPrimary.opacity(0.15))
                        .cornerRadius(12)
                }
            }
        }
        .padding(16 * sizePreference.paddingScale)
        .background(Color.bgSecondary(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .modifier(HoverEffectModifier(scale: reduceMotion ? 1.0 : 1.02))
        .modifier(ParallaxMotionModifier(amount: reduceMotion ? 0 : 0.5))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flight to \(destination)")
        .accessibilityValue("\(status), departing at \(time) from \(gate)")
        .accessibilityAddTraits([.isButton])
        .accessibilityHint("Tap for flight details")
        .contentShape(Rectangle())
        .onTapGesture {
            // Visual feedback when tapped
            if !reduceMotion {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // Status badge with compact mode support
    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(.system(size: 12 * sizePreference.fontScale, weight: .semibold))
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 12 * sizePreference.paddingScale)
            .padding(.vertical, 4 * sizePreference.paddingScale)
            .background(statusColor(status).opacity(0.15))
            .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    
    // Get displayed messages (filtered by search if active)
    private var displayedMessages: [SlackMessage] {
        if !searchText.isEmpty {
            return viewModel.searchMessages(query: searchText)
        }
        return filteredMessages
    }
    
    // Dynamic color based on username
    private func userColor(_ username: String) -> Color {
        let colors: [Color] = [
            .accentPrimary,
            Color(uiHex: "F76F5F"),  // Red
            Color(uiHex: "5FD38B"),  // Green
            Color(uiHex: "DA7AF5"),  // Purple
            Color(uiHex: "F5D45F")   // Yellow
        ]
        
        // Use consistent color for same username
        let index = abs(username.hashValue) % colors.count
        return colors[index]
    }
    
    // Status color based on status string
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "On Time": return .statusSuccess
        case "Boarding": return .statusInfo
        case "Delayed": return .statusWarning
        case "Cancelled": return .statusError
        default: return .textTertiary
        }
    }
    
    // Format time with time zone awareness
    private func formatTime(_ date: Date) -> String {
        return TimeZoneAwareFormatter.shared.formatRelativeTime(date)
    }
    
    // Accessibility-friendly date formatter
    private func accessibleDateFormat(_ date: Date) -> String {
        return TimeZoneAwareFormatter.shared.accessibleDateFormat(date)
    }
    
    // Last refresh time formatted
    private var lastRefreshTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Last updated: \(formatter.string(from: lastRefreshTime))"
    }
    
    // Get destination name from airport code
    private func destinationName(for code: String) -> String {
        switch code {
        case "SFO": return "San Francisco"
        case "JFK": return "New York"
        case "LHR": return "London"
        case "NRT": return "Tokyo"
        default: return "Unknown"
        }
    }
    
    // Get flight time based on airport code
    private func flightTime(for code: String) -> String {
        switch code {
        case "SFO": return "10:30 AM"
        case "JFK": return "2:45 PM"
        case "LHR": return "8:00 PM"
        case "NRT": return "11:15 PM"
        default: return "00:00"
        }
    }
    
    // Get flight status based on airport code
    private func flightStatus(for code: String) -> String {
        switch code {
        case "SFO": return "On Time"
        case "JFK": return "Delayed"
        case "LHR": return "Boarding"
        case "NRT": return "On Time"
        default: return "Unknown"
        }
    }
    
    // Get selected channel name
    private var selectedChannelName: String {
        if let channelId = selectedChannelId,
           let channel = viewModel.channels.first(where: { $0.id == channelId }) {
            return channel.name
        }
        return "All Channels"
    }
    
    // Get filtered messages
    private var filteredMessages: [SlackMessage] {
        var messages = viewModel.messages
        
        if let channelId = selectedChannelId {
            messages = messages.filter { $0.channelId == channelId }
        }
        
        return messages.sorted { $0.timestamp > $1.timestamp }
    }
    
    // Add this method to handle manual refresh
    private func refreshMessages() {
        // Visual feedback for refresh button
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            refreshButtonPressed = true
        }
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.refreshButtonPressed = false
        }
        
        // Perform an actual refresh
        Task {
            await viewModel.forceRefreshMessages()
            lastRefreshTime = Date()
        }
    }
    
    // Add this method to handle marking messages as read
    private func updateVisibleMessages(messageIds: [String]) {
        // Store visible message IDs
        visibleMessageIds = messageIds
        
        // Mark visible messages as read
        viewModel.markVisibleMessagesAsRead(messagesIds: messageIds)
    }
    
    // Send message
    private func sendMessage() {
        if !messageText.isEmpty, let channelId = selectedChannelId {
            Task {
                _ = await viewModel.sendMessage(text: messageText, channelId: channelId)
            }
            messageText = ""
        }
    }
    
    // Reaction picker view
    private var reactionPickerView: some View {
        NavigationView {
            VStack {
                Text("Choose a reaction")
                    .font(.headline)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                    ForEach(commonEmojis, id: \.self) { emoji in
                        Button(action: {
                            if let messageId = reactionTargetMessage {
                                viewModel.toggleReaction(emoji: emoji.name, messageId: messageId)
                                showingReactionPicker = false
                            }
                        }) {
                            VStack {
                                Text(emoji.emoji)
                                    .font(.system(size: 24))
                                Text(emoji.name)
                                    .font(.system(size: 10))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding()
                            .background(Color.bgSecondary(for: colorScheme))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitle("Add Reaction", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showingReactionPicker = false
            })
        }
    }
    
    // Thread view
    private var threadView: some View {
        NavigationView {
            VStack {
                if let parentId = threadParentId {
                    let threadMessages = viewModel.getThreadMessages(parentId: parentId)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(threadMessages) { message in
                                MessageRow(message: message, viewModel: viewModel, showReactionPicker: {
                                    self.reactionTargetMessage = message.id
                                    self.showingReactionPicker = true
                                }, showThreadView: {
                                    self.threadParentId = message.id
                                    self.showingThreadView = true
                                })
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Message input for thread
                    HStack {
                        TextField("Reply in thread...", text: $threadMessage)
                            .padding()
                            .background(Color.bgTertiary(for: colorScheme))
                            .cornerRadius(20)
                        
                        Button(action: {
                            if !threadMessage.isEmpty, let parentId = threadParentId {
                                viewModel.sendThreadMessage(text: threadMessage, parentId: parentId)
                                threadMessage = ""
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(threadMessage.isEmpty ? .textTertiary : .accentPrimary)
                        }
                        .disabled(threadMessage.isEmpty)
                    }
                    .padding()
                } else {
                    Text("No thread selected")
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationBarTitle("Thread", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                showingThreadView = false
            })
        }
    }
    
    // Common emoji reactions
    private var commonEmojis: [SlackReaction] {
        return [
            SlackReaction(name: "thumbsup", count: 0, userIds: []),
            SlackReaction(name: "thumbsdown", count: 0, userIds: []),
            SlackReaction(name: "heart", count: 0, userIds: []),
            SlackReaction(name: "joy", count: 0, userIds: []),
            SlackReaction(name: "clap", count: 0, userIds: []),
            SlackReaction(name: "fire", count: 0, userIds: []),
            SlackReaction(name: "eyes", count: 0, userIds: []),
            SlackReaction(name: "thinking_face", count: 0, userIds: []),
            SlackReaction(name: "pray", count: 0, userIds: []),
            SlackReaction(name: "100", count: 0, userIds: []),
            SlackReaction(name: "rocket", count: 0, userIds: []),
            SlackReaction(name: "raised_hands", count: 0, userIds: [])
        ]
    }
    
    // Find the section where messages are displayed in a ScrollView and update it
    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Get displayed messages based on filters
                let displayedMessages = filteredMessages
                
                if displayedMessages.isEmpty && !viewModel.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(Color.textTertiary(for: colorScheme))
                        
                        if !searchText.isEmpty {
                            Text("No messages match your search")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                        } else if let channelId = selectedChannelId {
                            let channelName = selectedChannelName
                            Text("No messages in \(channelName)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                messageText = ""
                                isComposing = true
                            }) {
                                Text("Start the conversation")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Theme.Colors.debotOrange)
                                    .cornerRadius(8)
                            }
                        } else {
                            Text("No messages")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.textSecondary(for: colorScheme))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                } else {
                    ForEach(displayedMessages) { message in
                        MessageRow(message: message, viewModel: viewModel, showReactionPicker: {
                            self.reactionTargetMessage = message.id
                            self.showingReactionPicker = true
                        }, showThreadView: {
                            self.threadParentId = message.id
                            self.showingThreadView = true
                        })
                        .id(message.id)
                        .onAppear {
                            // When a message appears, add it to visible messages
                            if !visibleMessageIds.contains(message.id) {
                                visibleMessageIds.append(message.id)
                                // Mark this message as read
                                viewModel.markAsRead(messageId: message.id)
                            }
                        }
                        .onDisappear {
                            // When a message disappears, remove it from visible messages
                            if let index = visibleMessageIds.firstIndex(of: message.id) {
                                visibleMessageIds.remove(at: index)
                            }
                        }
                    }
                    
                    // Load all visible message IDs after view appears
                    .onAppear {
                        // On initial appearance, mark all visible messages as read
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.markVisibleMessagesAsRead(messagesIds: visibleMessageIds)
                        }
                    }
                }
            }
            .padding(.horizontal)
            // Add a pull-to-refresh mechanism
            .refreshable {
                // This uses the native pull-to-refresh gesture
                await viewModel.forceRefreshMessages()
                lastRefreshTime = Date()
            }
        }
        .frame(maxHeight: .infinity) // Allow the ScrollView to expand to fill available space
    }
}

// Container view that safely creates the ViewModel
struct SlackMessagesViewContainer: View {
    @State private var viewModel: SlackViewModel?
    var showingFlights: Bool = false
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                SlackMessagesView(viewModel: viewModel, showingFlights: showingFlights)
            } else {
                ZStack {
                    Color(uiHex: "18191D").ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiHex: "5F8FF7")))
                        .scaleEffect(1.2)
                }
                    .onAppear {
                        Task {
                            // Create the view model on the MainActor
                            let newViewModel = await MainActor.run {
                                return SlackViewModel()
                            }
                            
                            // Set the view model
                            await MainActor.run {
                                self.viewModel = newViewModel
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SlackMessagesViewContainer(showingFlights: false)
        .preferredColorScheme(.dark)
}

// MARK: - Date Extension for Time Ago
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let timeInterval = self.timeIntervalSinceNow
        
        // For very recent messages (less than a minute ago)
        if timeInterval > -60 {
            return "just now"
        }
        
        // For older messages, use the relative formatter
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 