import SwiftUI

// This is a standalone SwiftUI app entry point 
// to show the FontDebugView for testing
// You can run this file directly to see the font debug view

@main
struct FontDebugApp: App {
    var body: some Scene {
        WindowGroup {
            FontDebugView()
        }
    }
}

// Add this code to a new file named `show_font_debug.swift`
// and run it directly to see the font debug view without 
// modifying your main app 