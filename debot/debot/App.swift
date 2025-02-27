import SwiftUI
import UserNotifications

// Helper for Slack notification badges
struct SlackNotificationManager {
    static func updateBadge(count: Int) {
        #if os(iOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = count
                }
            }
        }
        #endif
    }
} 