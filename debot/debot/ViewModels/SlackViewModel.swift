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
    @Published var error: Error? = nil  // Changed from String? to Error?
    @Published var unreadCount: Int = 0
    @Published var selectedChannel: String? = nil
    @Published var isConnected: Bool = false
    @Published var currentUserId: String? = nil  // Current user ID for tracking reactions
    
    // Storage for user defaults
    private var storage = UserDefaults.standard
    
    // Mock data flag - this would connect to real Slack API when false
    @Published var useMockData: Bool = true {
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
    
    init() {
        // Set useMockData from UserDefaults if available
        self.useMockData = storage.bool(forKey: "slackUseMockData")
        
        // Initial load of messages
        Task {
            await loadMessages()
        }
        
        // Setup timer to refresh data periodically (every minute)
        setupRefreshTimer()
    }
    
    private func setupRefreshTimer() {
        // In a real app, this would be done with WebSockets or push notifications
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.loadMessages()
            }
        }
    }
    
    func loadMessages() async {
        isLoading = true
        error = nil
        
        do {
            if useMockData {
                // Use mock data
                let newMessages = generateMockMessages()
                
                // Set current user ID for mock data
                currentUserId = "U123456" // Mock user ID
                
                // Update UI on main thread
                await MainActor.run {
                    self.messages = newMessages
                    self.unreadCount = newMessages.filter { !$0.isRead }.count
                    self.isLoading = false
                    self.isConnected = true
                    
                    // Save data for offline use if needed
                    saveMessageCache(messages: newMessages)
                }
            } else {
                // Use the existing loadRealMessages function for real API data
                try await loadRealMessages()
                
                // Set current user ID from Slack API
                currentUserId = try await SlackAPI.shared.getCurrentUserId()
                
                // Update connection status
                isLoading = false
                isConnected = true
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
    
    private func loadRealMessages() async throws {
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
        
        // Get messages for each channel
        for channel in channels where channel.is_member {
            print("Attempting to get messages for channel: \(channel.name) (\(channel.id))")
            
            do {
                let apiMessages = try await SlackAPI.shared.getMessages(channelId: channel.id)
                
                if apiMessages.isEmpty {
                    print("No messages found in channel \(channel.name) - bot might not have access")
                    
                    // Try joining the channel if we have no messages
                    print("Attempting to join channel \(channel.name)")
                    if try await SlackAPI.shared.joinChannel(channelId: channel.id) {
                        // Try getting messages again after joining
                        let messagesAfterJoin = try await SlackAPI.shared.getMessages(channelId: channel.id)
                        if !messagesAfterJoin.isEmpty {
                            joinedChannels = true
                            processMessages(messagesAfterJoin, channel: channel, allMessages: &allMessages)
                        }
                    }
                } else {
                    processMessages(apiMessages, channel: channel, allMessages: &allMessages)
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
                    processMessages(messagesAfterJoin, channel: channel, allMessages: &allMessages)
                }
            }
        }
        
        // Sort messages by timestamp (newest first)
        messages = allMessages.sorted(by: { $0.timestamp > $1.timestamp })
        
        if messages.isEmpty {
            print("⚠️ WARNING: No messages were retrieved from any channel!")
            print("1. Check if the bot is a member of any channels")
            print("2. Verify the bot has channels:history and channels:read scopes")
            print("3. Consider inviting the bot to a channel manually")
        }
    }
    
    // Helper to process messages to avoid code duplication
    private func processMessages(_ apiMessages: [SlackAPIMessage], channel: SlackChannel, allMessages: inout [SlackMessage]) {
        for apiMessage in apiMessages {
            // Skip system messages
            if apiMessage.type != "message" || apiMessage.user == nil {
                continue
            }
            
            // Get user info (or use cached version)
            let userId = apiMessage.user ?? "unknown"
            
            // Convert API message to app message model with placeholder user info initially
            let initialMessage = apiMessage.toSlackMessage(
                channelId: channel.id,
                channelName: channel.name,
                userName: "Loading User...",
                userAvatar: nil
            )
            
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
                            // Create updated message with proper user info
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
                attachments: message.attachments
            )
            messages[index] = updatedMessage
            updateUnreadCount()
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
                attachments: message.attachments
            )
        }
        updateUnreadCount()
    }
    
    private func updateUnreadCount() {
        unreadCount = messages.filter { !$0.isRead }.count
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
    
    var channels: [ChannelInfo] {
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
            if SlackAPI.shared.botToken.isEmpty || SlackAPI.shared.botToken == "REPLACE_WITH_YOUR_SLACK_BOT_TOKEN" {
                return "Error: No valid Slack token found in SlackConfig.plist"
            }
            
            print("Testing Slack API connection with token: \(SlackAPI.shared.botToken.prefix(10))...")
            
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
    
    private func generateMockMessages() -> [SlackMessage] {
        let now = Date()
        let calendar = Calendar.current
        
        // Create an array of mock messages
        var mockMessages: [SlackMessage] = []
        
        // General channel messages
        mockMessages.append(
            SlackMessage(
                id: "msg1",
                userId: "U123",
                userName: "John Doe",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "Hi team! I just pushed the latest updates to the repo.",
                timestamp: calendar.date(byAdding: .minute, value: -45, to: now) ?? now,
                isRead: false
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "msg2",
                userId: "U456",
                userName: "Jane Smith",
                userAvatar: nil,
                channelId: "C001",
                channelName: "general",
                text: "Great job! The new features look awesome.",
                timestamp: calendar.date(byAdding: .minute, value: -30, to: now) ?? now,
                isRead: true
            )
        )
        
        // Dev channel messages
        mockMessages.append(
            SlackMessage(
                id: "msg3",
                userId: "U789",
                userName: "Alex Johnson",
                userAvatar: nil,
                channelId: "C002",
                channelName: "dev",
                text: "Anyone facing issues with the latest API?",
                timestamp: calendar.date(byAdding: .minute, value: -20, to: now) ?? now,
                isRead: false,
                attachments: [
                    SlackAttachment(
                        id: "att1",
                        title: "API Error",
                        text: "Error 500 when calling /users endpoint",
                        color: "FF0000"
                    )
                ]
            )
        )
        
        mockMessages.append(
            SlackMessage(
                id: "msg4",
                userId: "U123",
                userName: "John Doe",
                userAvatar: nil,
                channelId: "C002",
                channelName: "dev",
                text: "I'll look into it. Can you provide more details?",
                timestamp: calendar.date(byAdding: .minute, value: -15, to: now) ?? now,
                isRead: false
            )
        )
        
        // Random channel messages
        mockMessages.append(
            SlackMessage(
                id: "msg5",
                userId: "U111",
                userName: "Sarah Wilson",
                userAvatar: nil,
                channelId: "C003",
                channelName: "random",
                text: "Check out this cool article about Swift!",
                timestamp: calendar.date(byAdding: .minute, value: -60, to: now) ?? now,
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
                id: "msg6",
                userId: "U222",
                userName: "Michael Brown",
                userAvatar: nil,
                channelId: "C004",
                channelName: "design",
                text: "New app icon options - what do you think?",
                timestamp: calendar.date(byAdding: .minute, value: -100, to: now) ?? now,
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
    func sendThreadMessage(text: String, parentId: String) {
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
} 