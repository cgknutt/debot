//
//  debotApp.swift
//  debot
//
//  Created by Deter Brown on 2/24/25.
//

import SwiftUI
import UserNotifications
import ObjectiveC  // Add this import for method swizzling

// Helper for Slack notification badges
struct SlackNotificationManager {
    static func updateBadge(count: Int) {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UNUserNotificationCenter.current().setBadgeCount(count) { error in
                        if let error = error {
                            print("Error setting badge count: \(error)")
                        }
                    }
                }
            }
        }
        #endif
    }
}

@main
struct debotApp: App {
    @StateObject private var slackViewModel = SlackViewModel()
    
    init() {
        // Log available fonts to help debug font loading issues
        Font.debugPrintAvailableFonts()
        
        // Configure default font appearance 
        configureGlobalFonts()
        
        // Configure tab bar appearance at app startup
        setupAppearance()
    }
    
    private func setupAppearance() {
        // Directly set tab bar appearance globally
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Use system colors for a consistent look in light and dark mode
            let accentColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0) // debotOrange
            
            // Set up colors for normal and selected states
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel // Use system gray
            appearance.stackedLayoutAppearance.selected.iconColor = accentColor
            
            // Set the appearances for the tab bar
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Set tint colors for tab bar items
        let accentColor = UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0) // debotOrange
        UITabBar.appearance().tintColor = accentColor
        UITabBar.appearance().unselectedItemTintColor = UIColor.secondaryLabel // Use system gray
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Use the light color scheme
                .accentColor(.blue) // Use blue accent color for the app
                .environment(\.themeColors, ThemeColors.colors(for: .light))
                .environmentObject(slackViewModel)
                .withCooperBlackStyle() // Apply Titan One font to all text (function name kept for compatibility)
                .onChange(of: slackViewModel.unreadCount) { oldValue, newValue in
                    // Set the badge for the app icon
                    SlackNotificationManager.updateBadge(count: newValue)
                }
        }
    }
    
    // Configure global font appearance settings
    private func configureGlobalFonts() {
        // Set the default system font globally to Titan One
        let fontName = "TitanOne-Regular"
        let alternativeFontNames = ["TitanOne", "Titan One", "Titan-One"]
        var titanOneFont: UIFont?
        
        // Try to load Titan One font with different possible PostScript names
        if let font = UIFont(name: fontName, size: 17) {
            titanOneFont = font
            print("✅ Successfully loaded Titan One font in UIKit with name: \(fontName)")
        } else {
            // Try alternative font names
            for altName in alternativeFontNames {
                if let font = UIFont(name: altName, size: 17) {
                    titanOneFont = font
                    print("✅ Successfully loaded Titan One font in UIKit with name: \(altName)")
                    break
                }
            }
        }
        
        // If we still don't have the font, log a warning and exit
        guard let font = titanOneFont else {
            print("⚠️ WARNING: Titan One font not available in UIKit")
            return // Don't apply fonts that don't exist
        }
        
        let fontDescriptor = font.fontDescriptor
        
        // Apply to common UIKit components
        UINavigationBar.appearance().titleTextAttributes = [.font: UIFont(descriptor: fontDescriptor, size: 20)]
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: UIFont(descriptor: fontDescriptor, size: 34)]
        
        // Apply to tab bar with increased size for better readability
        UITabBarItem.appearance().setTitleTextAttributes([.font: UIFont(descriptor: fontDescriptor, size: 14)], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: UIFont(descriptor: fontDescriptor, size: 14)], for: .selected)
        
        // Apply to other common UI elements
        UILabel.appearance().font = UIFont(descriptor: fontDescriptor, size: 17)
        UITextField.appearance().font = UIFont(descriptor: fontDescriptor, size: 17)
        UITextView.appearance().font = UIFont(descriptor: fontDescriptor, size: 17)
        
        // Set modal presentation style for view controllers
        UIViewController.swizzleViewDidLoad()
    }
}

// Extend UIViewController to inject our font settings when each view controller loads
extension UIViewController {
    static func swizzleViewDidLoad() {
        guard self == UIViewController.self else { return }
        
        let originalSelector = #selector(UIViewController.viewDidLoad)
        let swizzledSelector = #selector(UIViewController.swizzled_viewDidLoad)
        
        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else { return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc private func swizzled_viewDidLoad() {
        // Call original implementation
        self.swizzled_viewDidLoad()
        
        // Configure any UIKit text elements in this view controller to use Titan One
        let fontName = "TitanOne-Regular"
        
        // Don't proceed if font doesn't exist
        guard let font = UIFont(name: fontName, size: 17) else {
            return
        }
        
        let fontDescriptor = font.fontDescriptor
        
        for view in self.view.subviews {
            if let label = view as? UILabel {
                label.font = UIFont(descriptor: fontDescriptor, size: label.font.pointSize)
            } else if let textField = view as? UITextField {
                textField.font = UIFont(descriptor: fontDescriptor, size: textField.font?.pointSize ?? 17)
            } else if let textView = view as? UITextView {
                textView.font = UIFont(descriptor: fontDescriptor, size: textView.font?.pointSize ?? 17)
            } else if let button = view as? UIButton {
                button.titleLabel?.font = UIFont(descriptor: fontDescriptor, size: button.titleLabel?.font.pointSize ?? 17)
            }
        }
    }
}
