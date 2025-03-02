import Foundation
import UserNotifications
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    // Flag to check if notifications are enabled
    @Published var notificationsEnabled = false
    
    private init() {
        // Check notification settings on launch
        checkNotificationSettings()
    }
    
    // Check current notification settings
    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // Request notification permissions
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                completion(granted)
                
                if granted {
                    // Register for remote notifications if permission granted
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // Schedule a local notification for a new Slack message
    func scheduleSlackMessageNotification(message: SlackMessage) {
        // Don't show notifications if disabled
        guard notificationsEnabled else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "New message from \(message.userName)"
        content.body = message.text.count > 100 ? message.text.prefix(100) + "..." : message.text
        content.sound = .default
        content.userInfo = ["messageId": message.id, "channelId": message.channelId]
        
        // Add channel name to subtitle
        content.subtitle = "in #\(message.channelName)"
        
        // Create a time-based trigger (show immediately)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request with a unique identifier
        let request = UNNotificationRequest(
            identifier: "slack-message-\(message.id)",
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Handle notification response (when user taps notification)
    func handleNotificationResponse(_ response: UNNotificationResponse, completion: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract message and channel IDs
        guard let messageId = userInfo["messageId"] as? String,
              let channelId = userInfo["channelId"] as? String else {
            completion()
            return
        }
        
        // Post a notification to be picked up by the app to navigate to the message
        NotificationCenter.default.post(
            name: Notification.Name("OpenSlackMessage"),
            object: nil,
            userInfo: ["messageId": messageId, "channelId": channelId]
        )
        
        completion()
    }
    
    // Function to setup background notification fetch
    func setupBackgroundFetch() {
        // The setMinimumBackgroundFetchInterval method is deprecated in iOS 13.0
        // Use BGAppRefreshTask in the BackgroundTasks framework instead
        // This is a placeholder - actual implementation would require more setup
        if #available(iOS 13.0, *) {
            // For now, we'll keep this as a comment to indicate what should be done
            // TODO: Implement using BackgroundTasks framework
            // UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        } else {
            // For older iOS versions, use the deprecated API
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
    }
    
    // Clear all pending notifications
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Update badge count using UNUserNotificationCenter instead of deprecated applicationIconBadgeNumber
        if #available(iOS 17.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Error setting badge count: \(error)")
                }
            }
        } else {
            // For older iOS versions, use the deprecated API
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    // Clear notifications for a specific channel
    func clearNotificationsForChannel(channelId: String) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications.compactMap { notification -> String? in
                if let notificationChannelId = notification.request.content.userInfo["channelId"] as? String,
                   notificationChannelId == channelId {
                    return notification.request.identifier
                }
                return nil
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
        }
    }
} 