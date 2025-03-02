import Foundation
import SwiftUI
import Combine

// Custom Error type
enum SlackViewModelError: Error, LocalizedError {
    case general(String)
    
    var errorDescription: String? {
        switch self {
        case .general(let message):
            return message
        }
    }
}

@MainActor
class SlackViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var messages: [SlackMessage] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreMessages: Bool = false
    @Published var error: Error? = nil  // Changed from String? to Error?
    @Published var unreadCount: Int = 0
    @Published var selectedChannel: String? = nil
    @Published var isConnected: Bool = false
    @Published var currentUserId: String? = nil  // Current user ID for tracking reactions
    @Published var selectedMessage: SlackMessage? = nil
    
    // Notification settings
    @Published var enableNotifications: Bool = false {
        didSet {
            if enableNotifications != oldValue {
                storage.set(enableNotifications, forKey: "slackEnableNotifications")
                
                if enableNotifications {
                    // Request notification permissions if enabled
                    NotificationService.shared.requestNotificationPermissions { granted in
                        // If permissions not granted, disable the setting
                        if !granted {
                            self.enableNotifications = false
                        }
                    }
                }
            }
        }
    }
    
    // Storage for user defaults
    private var storage = UserDefaults.standard
    
    // Mock data flag - this would connect to real Slack API when false
    @Published var useMockData: Bool = false {
        didSet {
            if useMockData != oldValue {
                Task {
                    await loadMessages()
                }
            }
        }
    }
    
    private var channelMap: [String: String] = [:] // channelId -> channelName
    private var userCache: [String: SlackUser] = [:] // userId -> SlackUser
    
    // Add properties to track pagination
    private var channelCursors: [String: String] = [:]
    
    // Channel list for message composition
    @Published var channels: [SlackChannel] = []
    @Published var showingComposeSheet = false
    
    init() {
        // Set useMockData from UserDefaults if available
        self.useMockData = storage.bool(forKey: "slackUseMockData")
        
        // Set notification preference from UserDefaults
        self.enableNotifications = storage.bool(forKey: "slackEnableNotifications")
        
        // Initial load of messages
        Task {
            await loadMessages()
        }
        
        // Setup timer to refresh data periodically (every minute)
        setupRefreshTimer()
        
        // Setup notification observer
        setupNotificationObserver()
    }
    
    private func setupRefreshTimer() {
        // In a real app, this would be done with WebSockets or push notifications
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.loadMessages()
            }
        }
    }
    
    // Setup observer for notification taps
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSlackMessage(_:)),
            name: Notification.Name("OpenSlackMessage"),
            object: nil
        )
    }
    
    // Handle notification tap
    @objc private func handleOpenSlackMessage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let messageId = userInfo["messageId"] as? String else {
            return
        }
        
        // Find message in the cache
        if let message = messages.first(where: { $0.id == messageId }) {
            // Set as selected message to navigate to it
            selectedMessage = message
            
            // Mark as read
            Task {
                await toggleMessageReadStatus(messageId: messageId)
            }
        }
    }
    
    // Process new messages for notifications
    private func processNewMessagesForNotifications(newMessages: [SlackMessage], oldMessages: [SlackMessage]) {
        // Only proceed if notifications are enabled
        guard enableNotifications else { return }
        
        // Get IDs of existing messages
        let existingMessageIds = Set(oldMessages.map { $0.id })
        
        // Find messages that weren't in the previous set
        let newlyAddedMessages = newMessages.filter { !existingMessageIds.contains($0.id) }
        
        // Show notifications for new messages
        for message in newlyAddedMessages {
            // Don't notify for your own messages
            if message.userId != currentUserId {
                NotificationService.shared.scheduleSlackMessageNotification(message: message)
            }
        }
    }
    
    func loadMessages() async {
        isLoading = true
        error = nil
        
        // Store current messages for comparison
        let oldMessages = messages
        
        // Clear pagination data when starting a fresh load
        channelCursors.removeAll()
        hasMoreMessages = false
        
        do {
            // Load saved read status map from UserDefaults
            let savedReadStatusMap = loadReadStatus()
            
            // Save current read status map before loading new messages
            let currentReadStatusMap = Dictionary(uniqueKeysWithValues: 
                messages.map { ($0.id, $0.isRead) }
            )
            
            // Merge current and saved read status maps, giving preference to current
            var readStatusMap = savedReadStatusMap
            for (key, value) in currentReadStatusMap {
                readStatusMap[key] = value
            }
            
            print("Previous read status map: \(readStatusMap)")
            
            if useMockData {
                // Use mock data
                var newMessages = generateMockMessages()
                
                // Set current user ID for mock data
                currentUserId = "U123456" // Mock user ID
                
                // Preserve read status for existing messages
                newMessages = newMessages.map { message in
                    if let isRead = readStatusMap[message.id], isRead {
                        print("Preserving READ status for message: \(message.id)")
                        return SlackMessage(
                            id: message.id,
                            userId: message.userId,
                            userName: message.userName,
                            userAvatar: message.userAvatar,
                            channelId: message.channelId,
                            channelName: message.channelName,
                            text: message.text,
                            timestamp: message.timestamp,
                            isRead: true,
                            attachments: message.attachments,
                            threadParentId: message.threadParentId,
                            replyCount: message.replyCount,
                            isThreadParent: message.isThreadParent,
                            reactions: message.reactions
                        )
                    } else {
                        if readStatusMap[message.id] == false {
                            print("Preserving UNREAD status for message: \(message.id)")
                        } else {
                            print("New message with UNREAD status: \(message.id)")
                        }
                        return message
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.messages = newMessages
                    self.updateUnreadCount()
                    self.isLoading = false
                    self.isConnected = true
                    
                    // Save data for offline use if needed
                    saveMessageCache(messages: newMessages)
                }
                
                // Check for new messages and send notifications
                processNewMessagesForNotifications(newMessages: messages, oldMessages: oldMessages)
            } else {
                // Use the existing loadRealMessages function for real API data
                try await loadRealMessages(readStatusMap: readStatusMap)
                
                // Set current user ID from Slack API
                currentUserId = try await SlackAPI.shared.getCurrentUserId()
                
                // Update connection status
                isLoading = false
                isConnected = true
                
                // Check for new messages and send notifications
                processNewMessagesForNotifications(newMessages: messages, oldMessages: oldMessages)
            }
        } catch {
            await MainActor.run {
                self.error = error  // Now this is fine since error is Error? type
                self.isLoading = false
                self.isConnected = false
                print("Error loading messages: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadRealMessages(readStatusMap: [String: Bool] = [:], forceRefresh: Bool = false) async throws {
        // Get channels from Slack API
        let channels = try await SlackAPI.shared.getChannels()
        
        // Store channels in channel map
        for channel in channels {
            if channel.is_member {
                channelMap[channel.id] = channel.name
            }
        }
        
        var allMessages: [SlackMessage] = []
        var joinedChannels = false
        var hasMore = false
        
        // Get messages for each channel
        for channel in channels where channel.is_member {
            print("Attempting to get messages for channel: \(channel.name) (\(channel.id))")
            
            do {
                let result = try await SlackAPI.shared.getMessages(channelId: channel.id)
                let apiMessages = result.messages
                
                // Store cursor for this channel if there are more messages
                if let nextCursor = result.nextCursor, result.hasMore {
                    channelCursors[channel.id] = nextCursor
                    hasMore = true
                }
                
                if apiMessages.isEmpty {
                    print("No messages found in channel \(channel.name) - bot might not have access")
                    
                    // Try joining the channel if we have no messages
                    print("Attempting to join channel \(channel.name)")
                    if try await SlackAPI.shared.joinChannel(channelId: channel.id) {
                        // Try getting messages again after joining
                        let messagesAfterJoin = try await SlackAPI.shared.getMessages(channelId: channel.id)
                        if !messagesAfterJoin.messages.isEmpty {
                            joinedChannels = true
                            processMessages(messagesAfterJoin.messages, channel: channel, allMessages: &allMessages, readStatusMap: readStatusMap)
                            
                            // Store cursor for this channel if there are more messages
                            if let nextCursor = messagesAfterJoin.nextCursor, messagesAfterJoin.hasMore {
                                channelCursors[channel.id] = nextCursor
                                hasMore = true
                            }
                        }
                    }
                } else {
                    processMessages(apiMessages, channel: channel, allMessages: &allMessages, readStatusMap: readStatusMap)
                }
            } catch {
                print("Error getting messages for channel \(channel.name): \(error.localizedDescription)")
                // Continue with other channels even if one fails
            }
        }
        
        if allMessages.isEmpty && !joinedChannels {
            // Try channels where we're not a member yet
            for channel in channels where !channel.is_member {
                print("Not a member of channel \(channel.name) - attempting to join")
                
                if try await SlackAPI.shared.joinChannel(channelId: channel.id) {
                    channelMap[channel.id] = channel.name
                    
                    // Get messages after joining
                    let messagesAfterJoin = try await SlackAPI.shared.getMessages(channelId: channel.id)
                    processMessages(messagesAfterJoin.messages, channel: channel, allMessages: &allMessages, readStatusMap: readStatusMap)
                    
                    // Store cursor for this channel if there are more messages
                    if let nextCursor = messagesAfterJoin.nextCursor, messagesAfterJoin.hasMore {
                        channelCursors[channel.id] = nextCursor
                        hasMore = true
                    }
                }
            }
        }
        
        // Sort messages by timestamp (newest first)
        messages = allMessages.sorted(by: { $0.timestamp > $1.timestamp })
        
        // Update hasMoreMessages flag
        hasMoreMessages = hasMore
        
        // Update unread count
        updateUnreadCount()
        
        if messages.isEmpty {
            print("⚠️ WARNING: No messages were retrieved from any channel!")
            print("1. Check if the bot is a member of any channels")
            print("2. Verify the bot has channels:history and channels:read scopes")
            print("3. Consider inviting the bot to a channel manually")
        }
    }
    
    // Helper to process messages to avoid code duplication
    private func processMessages(_ apiMessages: [SlackAPIMessage], channel: SlackChannel, allMessages: inout [SlackMessage], readStatusMap: [String: Bool] = [:]) {
        for apiMessage in apiMessages {
            // Skip system messages
            if apiMessage.type != "message" || apiMessage.user == nil {
                continue
            }
            
            // Get user info (or use cached version)
            let userId = apiMessage.user ?? "unknown"
            
            // Convert API message to app message model with placeholder user info initially
            var initialMessage = apiMessage.toSlackMessage(
                channelId: channel.id,
                channelName: channel.name,
                userName: "Loading User...",
                userAvatar: nil
            )
            
            // Preserve read status for existing messages
            if let isRead = readStatusMap[initialMessage.id], isRead {
                initialMessage = SlackMessage(
                    id: initialMessage.id,
                    userId: initialMessage.userId,
                    userName: initialMessage.userName,
                    userAvatar: initialMessage.userAvatar,
                    channelId: initialMessage.channelId,
                    channelName: initialMessage.channelName,
                    text: initialMessage.text,
                    timestamp: initialMessage.timestamp,
                    isRead: true,
                    attachments: initialMessage.attachments,
                    threadParentId: initialMessage.threadParentId,
                    replyCount: initialMessage.replyCount,
                    isThreadParent: initialMessage.isThreadParent,
                    reactions: initialMessage.reactions
                )
            }
            
            // Add message to collection immediately with placeholder info
            allMessages.append(initialMessage)
            
            // Then start a background task to fetch and update user info
            Task { [weak self, userId, messageId = initialMessage.id, channelId = channel.id, channelName = channel.name] in
                guard let self = self else { return }
                
                do {
                    let user: SlackUser
                    
                    if let cachedUser = self.userCache[userId] {
                        user = cachedUser
                    } else {
                        // Fetch user information
                        user = try await SlackAPI.shared.getUserInfo(userId: userId)
                        self.userCache[userId] = user
                    }
                    
                    await MainActor.run {
                        // Find the message in the current messages array and update it
                        if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                            // Create updated message with proper user info and preserving all other properties
                            let updatedMessage = SlackMessage(
                                id: messageId,
                                userId: userId,
                                userName: user.profile.display_name.isEmpty ? user.name : user.profile.display_name,
                                userAvatar: user.profile.image_72,
                                channelId: channelId,
                                channelName: channelName,
                                text: self.messages[index].text,
                                timestamp: self.messages[index].timestamp,
                                isRead: self.messages[index].isRead,
                                attachments: self.messages[index].attachments,
                                threadParentId: self.messages[index].threadParentId,
                                replyCount: self.messages[index].replyCount,
                                isThreadParent: self.messages[index].isThreadParent,
                                reactions: self.messages[index].reactions
                            )
                            
                            // Update message in array
                            self.messages[index] = updatedMessage
                        }
                    }
                } catch {
                    print("Error fetching user info for \(userId): \(error)")
                    // User info will remain as placeholder "Loading User..."
                }
            }
        }
        
        // Sort messages by timestamp (newest first)
        self.messages = allMessages.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    func markAsRead(messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            let message = messages[index]
            let updatedMessage = SlackMessage(
                id: message.id,
                userId: message.userId,
                userName: message.userName,
                userAvatar: message.userAvatar,
                channelId: message.channelId,
                channelName: message.channelName,
                text: message.text,
                timestamp: message.timestamp,
                isRead: true,
                attachments: message.attachments,
                threadParentId: message.threadParentId,
                replyCount: message.replyCount,
                isThreadParent: message.isThreadParent,
                reactions: message.reactions
            )
            messages[index] = updatedMessage
            updateUnreadCount()
            
            // Persist the read status in UserDefaults
            saveReadStatus()
        }
    }
    
    func toggleReadStatus(messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            let message = messages[index]
            let updatedMessage = SlackMessage(
                id: message.id,
                userId: message.userId,
                userName: message.userName,
                userAvatar: message.userAvatar,
                channelId: message.channelId,
                channelName: message.channelName,
                text: message.text,
                timestamp: message.timestamp,
                isRead: !message.isRead, // Toggle the read status
                attachments: message.attachments,
                threadParentId: message.threadParentId,
                replyCount: message.replyCount,
                isThreadParent: message.isThreadParent,
                reactions: message.reactions
            )
            messages[index] = updatedMessage
            updateUnreadCount()
            
            // Persist the read status in UserDefaults
            saveReadStatus()
        }
    }
    
    func markAllAsRead() {
        messages = messages.map { message in
            SlackMessage(
                id: message.id,
                userId: message.userId,
                userName: message.userName,
                userAvatar: message.userAvatar,
                channelId: message.channelId,
                channelName: message.channelName,
                text: message.text,
                timestamp: message.timestamp,
                isRead: true,
                attachments: message.attachments,
                threadParentId: message.threadParentId,
                replyCount: message.replyCount,
                isThreadParent: message.isThreadParent,
                reactions: message.reactions
            )
        }
        updateUnreadCount()
    }
    
    private func updateUnreadCount() {
        let oldCount = unreadCount
        unreadCount = messages.filter { !$0.isRead }.count
        print("Unread count updated: \(oldCount) -> \(unreadCount)")
        
        if oldCount != unreadCount {
            print("Messages read status:")
            for message in messages {
                print("Message \(message.id) - \(message.isRead ? "READ" : "UNREAD")")
            }
        }
    }
    
    private func updateChannelMap() {
        if useMockData {
            var map: [String: String] = [:]
            for message in messages {
                map[message.channelId] = message.channelName
            }
            channelMap = map
        }
        // For real data, channelMap is already populated in loadRealMessages
    }
    
    // MARK: - Channel Methods
    
    // Old dictionary-based channels property
    // var channels: [String: String] {
    //     channelMap
    // }
    
    // New channels property that returns an array of identifiable objects
    struct ChannelInfo: Identifiable {
        let id: String
        let name: String
    }
    
    var channelInfoList: [ChannelInfo] {
        channelMap.map { ChannelInfo(id: $0.key, name: $0.value) }
    }
    
    func filterMessagesByChannel(_ channelId: String?) -> [SlackMessage] {
        guard let channelId = channelId else {
            return messages
        }
        
        return messages.filter { $0.channelId == channelId }
    }
    
    // MARK: - Toggle Mock Data
    
    func toggleMockData() {
        useMockData.toggle()
        // Save preference
        storage.set(useMockData, forKey: "slackUseMockData")
    }
    
    // MARK: - Test API Connection
    
    @MainActor
    func testAPIConnection() async -> String {
        do {
            if useMockData {
                return "Using mock data - no actual API connection needed"
            }
            
            // Test the token first
            if SlackAPI.shared.botToken?.isEmpty ?? true || SlackAPI.shared.botToken == "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" {
                return "Error: No valid Slack token found in SlackConfig.plist"
            }
            
            print("Testing Slack API connection with token: \(SlackAPI.shared.botToken?.prefix(10) ?? "")...")
            
            // Try to get channels as a basic test
            let channels = try await SlackAPI.shared.getChannels()
            
            if channels.isEmpty {
                return "Connected to Slack, but no channels found. Make sure your bot is invited to at least one channel."
            } else {
                let channelNames = channels.map { $0.name }.joined(separator: ", ")
                return "Success! Connected to Slack. Found \(channels.count) channels: \(channelNames)"
            }
        } catch let error as SlackAPI.SlackError {
            switch error {
            case .apiError(let message):
                return "API Error: \(message)"
            case .httpError(let code):
                return "HTTP Error \(code). Check your internet connection and token."
            case .notAuthenticated:
                return "Not authenticated with Slack. Please check your token."
            }
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockMessages(older: Bool = false) -> [SlackMessage] {
        let now = Date()
        let calendar = Calendar.current
        
        // Create an array of mock messages
        var mockMessages: [SlackMessage] = []
        
        // Determine the time range for messages
        let startDate: Date
        let idPrefix: String
        
        if older {
            // For older messages, start from 2 weeks ago and go back another week
            // Also check if we have existing messages to determine the oldest timestamp
            if let oldestMessage = messages.last {
                // Start one day older than the oldest message we have
                startDate = calendar.date(byAdding: .day, value: -1, to: oldestMessage.timestamp) ?? 
                            calendar.date(byAdding: .day, value: -14, to: now)!
            } else {
                startDate = calendar.date(byAdding: .day, value: -14, to: now)!
            }
            idPrefix = "older_"
        } else {
            // For regular messages, start from now and go back 7 days
            startDate = now
            idPrefix = "msg"
        }
        
        // General channel messages
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)1",
                userId: "U123",
                userName: "John Doe",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "Hi team! I just pushed the latest updates to the repo.",
                timestamp: calendar.date(byAdding: .minute, value: -45, to: startDate) ?? startDate,
                isRead: false
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)2",
                userId: "U456",
                userName: "Jane Smith",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "Great job! The new features look awesome.",
                timestamp: calendar.date(byAdding: .minute, value: -30, to: startDate) ?? startDate,
                isRead: true
            )
        )
        
        // Dev channel messages
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)3",
                userId: "U789",
                userName: "Alex Johnson",
                userAvatar: nil,
                channelId: "C002",
                channelName: "dev",
                text: "Anyone facing issues with the latest API?",
                timestamp: calendar.date(byAdding: .minute, value: -20, to: startDate) ?? startDate,
                isRead: false,
                attachments: [
                    SlackAttachment(
                        id: "att1",
                        title: "App Icon Options",
                        imageUrl: "https://picsum.photos/300/200",
                        fileType: "image"
                    )
                ]
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)4",
                userId: "U123",
                userName: "John Doe",
                userAvatar: nil,
                channelId: "C002",
                channelName: "dev",
                text: "I'll look into it. Can you provide more details?",
                timestamp: calendar.date(byAdding: .minute, value: -15, to: startDate) ?? startDate,
                isRead: false
            )
        )
        
        // Random channel messages
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)5",
                userId: "U111",
                userName: "Sarah Wilson",
                userAvatar: nil,
                channelId: "C003",
                channelName: "random",
                text: "Check out this cool article about Swift!",
                timestamp: calendar.date(byAdding: .minute, value: -60, to: startDate) ?? startDate,
                isRead: true,
                attachments: [
                    SlackAttachment(
                        id: "att2",
                        title: "Swift Tips & Tricks",
                        text: "Learn how to optimize your Swift code",
                        imageUrl: "https://picsum.photos/200",
                        color: "36C5F0"
                    )
                ]
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)6",
                userId: "U222",
                userName: "Michael Brown",
                userAvatar: nil,
                channelId: "C004",
                channelName: "design",
                text: "New app icon options - what do you think?",
                timestamp: calendar.date(byAdding: .minute, value: -100, to: startDate) ?? startDate,
                isRead: true,
                attachments: [
                    SlackAttachment(
                        id: "att3",
                        title: "Icon Option 1",
                        imageUrl: "https://picsum.photos/200/200",
                        color: "2EB67D"
                    ),
                    SlackAttachment(
                        id: "att4",
                        title: "Icon Option 2",
                        imageUrl: "https://picsum.photos/201/200",
                        color: "E01E5A"
                    )
                ]
            )
        )
        
        // Thread parent message
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)7",
                userId: "U333",
                userName: "Emily Davis",
                userAvatar: "https://randomuser.me/api/portraits/women/3.jpg",
                channelId: "C003",
                channelName: "general",
                text: "When is our next team meeting?",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: startDate) ?? startDate,
                isRead: false,
                replyCount: 2,
                isThreadParent: true
            )
        )
        
        // Thread replies
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)8",
                userId: "U123",
                userName: "John Doe",
                userAvatar: "https://randomuser.me/api/portraits/men/1.jpg",
                channelId: "C003",
                channelName: "general",
                text: "Tomorrow at 10 AM",
                timestamp: calendar.date(byAdding: .hour, value: -2, to: startDate) ?? startDate,
                isRead: true,
                threadParentId: "\(idPrefix)7"
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)9",
                userId: "U333",
                userName: "Emily Davis",
                userAvatar: "https://randomuser.me/api/portraits/women/3.jpg",
                channelId: "C003",
                channelName: "general",
                text: "Thanks! I'll be there.",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: startDate) ?? startDate,
                isRead: true,
                threadParentId: "\(idPrefix)7"
            )
        )
        
        // Message with reactions
        mockMessages.append(
            SlackMessage(
                id: "\(idPrefix)10",
                userId: "U456",
                userName: "Jane Smith",
                userAvatar: "https://randomuser.me/api/portraits/women/2.jpg",
                channelId: "C001",
                channelName: "general",
                text: "Our new feature is now live! 🎉",
                timestamp: calendar.date(byAdding: .day, value: -1, to: startDate) ?? startDate,
                isRead: true,
                reactions: [
                    SlackReaction(name: "thumbsup", count: 3, userIds: ["U123", "U789", "U111"]),
                    SlackReaction(name: "heart", count: 2, userIds: ["U222", "U333"])
                ]
            )
        )
        
        return mockMessages
    }
    
    // MARK: - Message Sending
    
    func sendMessage(text: String, channelId: String, threadTs: String? = nil) async -> Result<String, Error> {
        do {
            isLoading = true
            let timestamp = try await SlackAPI.shared.sendMessage(text: text, channelId: channelId, threadTs: threadTs)
            
            // Reload messages to show the new message
            await loadMessages()
            
            isLoading = false
            return .success(timestamp)
        } catch {
            isLoading = false
            self.error = error  // Now this is fine since error is Error? type
            print("Error sending message: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    // MARK: - Reactions
    
    func addReaction(name: String, messageId: String, channelId: String) async -> Bool {
        do {
            let success = try await SlackAPI.shared.addReaction(name: name, channelId: channelId, timestamp: messageId)
            
            if success {
                // Reload messages to show the reaction
                await loadMessages()
            }
            
            return success
        } catch {
            self.error = error  // Now this is fine since error is Error? type
            print("Error adding reaction: \(error.localizedDescription)")
            return false
        }
    }
    
    // Toggle a reaction on a message (add or remove)
    func toggleReaction(emoji: String, messageId: String) {
        // Find the message
        guard let message = messages.first(where: { $0.id == messageId }) else {
            print("Message not found for reaction toggle")
            return
        }
        
        // Check if the current user has already reacted with this emoji
        let userHasReacted = message.reactions?.contains(where: { 
            $0.name == emoji && $0.userHasReacted(currentUserId: self.currentUserId)
        }) ?? false
        
        // Perform the appropriate action based on whether the user has already reacted
        Task {
            if userHasReacted {
                // Remove the reaction
                do {
                    let success = try await SlackAPI.shared.removeReaction(name: emoji, channelId: message.channelId, timestamp: messageId)
                    if success {
                        // Reload messages to update the UI
                        await loadMessages()
                    } else {
                        print("Failed to remove reaction")
                    }
                } catch {
                    self.error = error
                    print("Error removing reaction: \(error.localizedDescription)")
                }
            } else {
                // Add the reaction
                let success = await addReaction(name: emoji, messageId: messageId, channelId: message.channelId)
                if !success {
                    print("Failed to add reaction")
                }
            }
        }
    }
    
    // MARK: - Thread Management
    
    // Get parent message ID for thread (message ID is same as timestamp)
    func getThreadParentId(messageId: String) -> String? {
        // If message has thread_ts, it's part of a thread
        return messages.first(where: { $0.id == messageId })?.threadParentId
    }
    
    // Get all messages in a thread
    func getThreadMessages(parentId: String) -> [SlackMessage] {
        // Get the parent message and all replies
        let parent = messages.first(where: { $0.id == parentId })
        let replies = messages.filter({ $0.threadParentId == parentId })
        
        if let parent = parent {
            var threadMessages = [parent]
            threadMessages.append(contentsOf: replies)
            return threadMessages.sorted(by: { $0.timestamp < $1.timestamp })
        } else {
            return replies.sorted(by: { $0.timestamp < $1.timestamp })
        }
    }
    
    // Save messages to cache for offline use
    private func saveMessageCache(messages: [SlackMessage]) {
        // In a real app, you would save to Core Data, Realm, or a file
        // For this example, we'll just track the latest data in memory
        print("Saving \(messages.count) messages to cache")
        // Actual implementation would depend on your persistence strategy
    }
    
    // Method to get a specific message by ID
    func getMessage(id: String) -> SlackMessage? {
        return messages.first(where: { $0.id == id })
    }
    
    // Method to send a thread message
    func sendThreadMessage(text: String, parentId: String) async {
        // In a real app, this would send the message to the Slack API
        // For now, we'll just add it to our local data
        
        guard let parentMessage = getMessage(id: parentId) else {
            print("Error: Parent message not found")
            return
        }
        
        let newMessageId = "msg_\(UUID().uuidString)"
        let timestamp = Date()
        
        let threadMessage = SlackMessage(
            id: newMessageId,
            userId: currentUserId ?? "U123456", // Use current user or default
            userName: "You",
            userAvatar: nil,
            channelId: parentMessage.channelId,
            channelName: parentMessage.channelName,
            text: text,
            timestamp: timestamp,
            isRead: true,
            threadParentId: parentId,
            isThreadParent: false
        )
        
        // Add to messages array
        messages.append(threadMessage)
        
        // In a real app, we would also update the parent message's reply count
        // and potentially trigger a refresh
    }
    
    // MARK: - Mark visible messages as read
    
    /// Call this method when messages are displayed to the user
    /// to automatically mark them as read
    func markVisibleMessagesAsRead(messagesIds: [String]) {
        var didMarkAnyAsRead = false
        
        for messageId in messagesIds {
            if let index = messages.firstIndex(where: { $0.id == messageId && !$0.isRead }) {
                let message = messages[index]
                let updatedMessage = SlackMessage(
                    id: message.id,
                    userId: message.userId,
                    userName: message.userName,
                    userAvatar: message.userAvatar,
                    channelId: message.channelId,
                    channelName: message.channelName,
                    text: message.text,
                    timestamp: message.timestamp,
                    isRead: true,
                    attachments: message.attachments,
                    threadParentId: message.threadParentId,
                    replyCount: message.replyCount,
                    isThreadParent: message.isThreadParent,
                    reactions: message.reactions
                )
                messages[index] = updatedMessage
                didMarkAnyAsRead = true
            }
        }
        
        if didMarkAnyAsRead {
            updateUnreadCount()
            // Persist the read status in UserDefaults
            saveReadStatus()
        }
    }
    
    // MARK: - Force refresh messages
    
    /// Force a complete refresh of messages, ignoring cache
    func forceRefreshMessages() async {
        isLoading = true
        error = nil
        
        // Load saved read status map from UserDefaults
        let savedReadStatusMap = loadReadStatus()
        
        // Save current read status map
        let currentReadStatusMap = Dictionary(uniqueKeysWithValues: 
            messages.map { ($0.id, $0.isRead) }
        )
        
        // Merge current and saved read status maps, giving preference to current
        var readStatusMap = savedReadStatusMap
        for (key, value) in currentReadStatusMap {
            readStatusMap[key] = value
        }
        
        print("Forcing complete refresh of messages")
        
        do {
            if useMockData {
                // In mock mode, generate new messages with current timestamp
                let newMockMessages = generateFreshMockMessages()
                
                // Preserve read status
                let finalMessages = newMockMessages.map { message in
                    if let isRead = readStatusMap[message.id], isRead {
                        return SlackMessage(
                            id: message.id,
                            userId: message.userId,
                            userName: message.userName,
                            userAvatar: message.userAvatar,
                            channelId: message.channelId,
                            channelName: message.channelName,
                            text: message.text,
                            timestamp: message.timestamp,
                            isRead: true,
                            attachments: message.attachments,
                            threadParentId: message.threadParentId,
                            replyCount: message.replyCount,
                            isThreadParent: message.isThreadParent,
                            reactions: message.reactions
                        )
                    } else {
                        return message
                    }
                }
                
                await MainActor.run {
                    // Include any existing messages and add the new ones
                    let oldMessages = self.messages
                    
                    // Create a combined array of messages
                    var combinedMessages = finalMessages
                    
                    // Add any old messages that aren't in the new set
                    for oldMessage in oldMessages {
                        if !combinedMessages.contains(where: { $0.id == oldMessage.id }) {
                            combinedMessages.append(oldMessage)
                        }
                    }
                    
                    // Sort messages by timestamp (newest first)
                    self.messages = combinedMessages.sorted(by: { $0.timestamp > $1.timestamp })
                    self.updateUnreadCount()
                    self.isLoading = false
                    // Save the updated read status
                    self.saveReadStatus()
                }
            } else {
                // For real API, clear the cache and force reload
                userCache.removeAll()
                
                // Reset flags to ensure we re-join channels if needed
                try await loadRealMessages(readStatusMap: [:], forceRefresh: true)
                currentUserId = try await SlackAPI.shared.getCurrentUserId()
                
                // Update UI state
                isLoading = false
                isConnected = true
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
                self.isConnected = false
                print("Error refreshing messages: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Fetch only the latest messages
    
    /// Fetch only the most recent messages to update the view
    func fetchLatestMessages() async {
        if isLoading { return } // Prevent multiple simultaneous refreshes
        
        print("Fetching latest messages...")
        
        do {
            if useMockData {
                // Generate new bot messages
                let newBotMessage = SlackMessage(
                    id: "msg_bot_new_\(Int(Date().timeIntervalSince1970))",
                    userId: "U222",
                    userName: "Bot Test User",
                    userAvatar: nil,
                    channelId: "C001",
                    channelName: "general",
                    text: "This is a new test message from the bot! Timestamp: \(Date().timeIntervalSince1970)",
                    timestamp: Date(),
                    isRead: false
                )
                
                await MainActor.run {
                    // Add the new message to the existing message array
                    self.messages.insert(newBotMessage, at: 0)
                    self.updateUnreadCount()
                }
            } else {
                // For real API, fetch only the latest messages without clearing the cache
                try await fetchLatestRealMessages()
                
                // Update UI state
                isConnected = true
            }
        } catch {
            print("Error fetching latest messages: \(error.localizedDescription)")
        }
    }
    
    /// Fetch only the latest real messages from Slack API
    private func fetchLatestRealMessages() async throws {
        // Get channels from Slack API
        let channels = try await SlackAPI.shared.getChannels()
        
        // Store channels in channel map
        for channel in channels {
            if channel.is_member {
                channelMap[channel.id] = channel.name
            }
        }
        
        var newMessages: [SlackMessage] = []
        
        // Get messages for each channel
        for channel in channels where channel.is_member {
            print("Fetching latest messages for channel: \(channel.name) (\(channel.id))")
            
            do {
                let apiMessagesResult = try await SlackAPI.shared.getMessages(channelId: channel.id)
                
                if !apiMessagesResult.messages.isEmpty {
                    // Process only the messages
                    var channelMessages: [SlackMessage] = []
                    processMessages(apiMessagesResult.messages, channel: channel, allMessages: &channelMessages, readStatusMap: [:])
                    
                    // Find the newest message timestamp we have
                    var latestTimestamp: Date? = nil
                    if let existingChannelMessages = messages.filter({ $0.channelId == channel.id }).first {
                        latestTimestamp = existingChannelMessages.timestamp
                    }
                    
                    // Filter to only include messages newer than what we have
                    let newChannelMessages = channelMessages.filter { message in
                        if let latestTimestamp = latestTimestamp {
                            return message.timestamp > latestTimestamp
                        }
                        return true
                    }
                    
                    newMessages.append(contentsOf: newChannelMessages)
                }
            } catch {
                print("Error getting latest messages for channel \(channel.name): \(error.localizedDescription)")
                // Continue with other channels even if one fails
            }
        }
        
        // Update messages on the main thread
        await MainActor.run {
            if !newMessages.isEmpty {
                // Combine existing and new messages
                var combinedMessages = self.messages
                
                // Add new messages
                for newMessage in newMessages {
                    // Don't add duplicates
                    if !combinedMessages.contains(where: { $0.id == newMessage.id }) {
                        combinedMessages.append(newMessage)
                    }
                }
                
                // Sort messages by timestamp (newest first)
                self.messages = combinedMessages.sorted(by: { $0.timestamp > $1.timestamp })
                self.updateUnreadCount()
            }
        }
    }
    
    // Generate fresh mock messages with current timestamp
    private func generateFreshMockMessages() -> [SlackMessage] {
        let now = Date()
        let calendar = Calendar.current
        
        // Create an array of mock messages
        var mockMessages: [SlackMessage] = []
        
        // General channel messages (with recent timestamps)
        mockMessages.append(
            SlackMessage(
                id: "msg1",  // Use fixed IDs instead of timestamp-based ones
                userId: "U123",
                userName: "John Doe",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "Hi team! I just pushed the latest updates to the repo.",
                timestamp: calendar.date(byAdding: .minute, value: -2, to: now) ?? now,
                isRead: false
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "msg2",  // Use fixed IDs instead of timestamp-based ones
                userId: "U456",
                userName: "Jane Smith",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "Great job! The new features look awesome.",
                timestamp: calendar.date(byAdding: .minute, value: -1, to: now) ?? now,
                isRead: false
            )
        )
        
        // Add a very recent message to simulate new content
        mockMessages.append(
            SlackMessage(
                id: "msg_bot",  // Use fixed IDs instead of timestamp-based ones
                userId: "U222",
                userName: "Bot Test User",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "This is a new test message sent to the bot!",
                timestamp: now,
                isRead: false
            )
        )
        
        return mockMessages
    }
    
    // Save message read status to UserDefaults
    private func saveReadStatus() {
        let readStatusMap = Dictionary(uniqueKeysWithValues: 
            messages.map { ($0.id, $0.isRead) }
        )
        if let data = try? JSONEncoder().encode(readStatusMap) {
            storage.set(data, forKey: "slackReadStatusMap")
        }
    }
    
    // Load message read status from UserDefaults
    private func loadReadStatus() -> [String: Bool] {
        if let data = storage.data(forKey: "slackReadStatusMap"),
           let readStatusMap = try? JSONDecoder().decode([String: Bool].self, from: data) {
            return readStatusMap
        }
        return [:]
    }
    
    // Get a username for a user ID (used for formatting mentions)
    func getUsernameForId(_ userId: String) -> String? {
        // Check our user cache first
        if let user = userCache[userId] {
            return user.profile.display_name.isEmpty ? user.name : user.profile.display_name
        }
        
        // For mock data, provide some mappings
        if useMockData {
            let mockUsers = [
                "U123": "john.doe",
                "U456": "jane.smith",
                "U789": "alex.johnson",
                "U111": "sarah.wilson",
                "U222": "bot.user",
                "U05SGQX1F52": "deter.brown",
                "U08FL5DNEUR": "debot"
            ]
            
            return mockUsers[userId] ?? "user"
        }
        
        // For real API, we should make an API call to get user info
        // But for now, just return a placeholder
        return "user"
    }
    
    // MARK: - Quick Methods
    
    // Simple refresh method for pull-to-refresh functionality
    func refreshMessagesAsync() async {
        await loadMessages()
    }
    
    // Load more messages (older messages) using pagination
    func loadMoreMessages() async {
        guard !isLoadingMore, hasMoreMessages else { return }
        
        await MainActor.run {
            isLoadingMore = true
        }
        
        // Get current messages to preserve them
        var newMessages: [SlackMessage] = []
        var hasMore = false
        
        // Load saved read status map from UserDefaults
        let savedReadStatusMap = loadReadStatus()
        
        // Save current read status map before loading new messages
        let currentReadStatusMap = Dictionary(uniqueKeysWithValues: 
            messages.map { ($0.id, $0.isRead) }
        )
        
        // Merge current and saved read status maps, giving preference to current
        var readStatusMap = savedReadStatusMap
        for (key, value) in currentReadStatusMap {
            readStatusMap[key] = value
        }
        
        if useMockData {
            // For mock data, just add more mock messages
            await MainActor.run {
                let additionalMockMessages = generateMockMessages(older: true)
                messages.append(contentsOf: additionalMockMessages)
                messages.sort(by: { $0.timestamp > $1.timestamp })
                isLoadingMore = false
                hasMoreMessages = true // Always allow loading more in mock mode
            }
        } else {
            // For each channel with a cursor, load more messages
            for (channelId, cursor) in channelCursors {
                guard let channelName = channelMap[channelId] else { continue }
                
                do {
                    let result = try await SlackAPI.shared.getMessages(channelId: channelId, cursor: cursor)
                    
                    // Update cursor for this channel if there are more messages
                    if let nextCursor = result.nextCursor, result.hasMore {
                        channelCursors[channelId] = nextCursor
                        hasMore = true
                    } else {
                        // Remove cursor if no more messages
                        channelCursors.removeValue(forKey: channelId)
                    }
                    
                    // Create a channel object for processing
                    let channel = SlackChannel(
                        id: channelId,
                        name: channelName,
                        isPrivate: false,
                        description: nil,
                        memberCount: nil,
                        topic: nil,
                        purpose: nil
                    )
                    
                    // Process the new messages
                    processMessages(result.messages, channel: channel, allMessages: &newMessages, readStatusMap: readStatusMap)
                } catch {
                    print("Error loading more messages for channel \(channelName): \(error.localizedDescription)")
                }
            }
            
            // Update UI on main thread
            await MainActor.run {
                // Add new messages to existing messages
                messages.append(contentsOf: newMessages)
                
                // Sort all messages by timestamp (newest first)
                messages.sort(by: { $0.timestamp > $1.timestamp })
                
                // Update flags
                isLoadingMore = false
                hasMoreMessages = hasMore
                
                // Update unread count
                updateUnreadCount()
            }
        }
    }
    
    // Toggle message read status
    func toggleMessageReadStatus(messageId: String) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        // Toggle the read status
        messages[index].isRead.toggle()
        
        // Update unread count
        updateUnreadCount()
        
        // In a real app, you would also update this on the server
    }
} 