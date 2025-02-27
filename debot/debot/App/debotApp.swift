//
//  debotApp.swift
//  debot
//
//  Created by Deter Brown on 2/24/25.
//

import SwiftUI

@main
struct debotApp: App {
    @StateObject private var slackViewModel = SlackViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light) // Use the light color scheme
                .accentColor(.blue) // Use blue accent color for the app
                .environment(\.themeColors, ThemeColors.colors(for: .light))
                .environmentObject(slackViewModel)
                .onChange(of: slackViewModel.unreadCount) { newValue in
                    // Set the badge for the app icon
                    SlackNotificationManager.updateBadge(count: newValue)
                }
        }
    }
}
