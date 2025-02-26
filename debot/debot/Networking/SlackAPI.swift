import Foundation

class SlackAPI {
    static let shared = SlackAPI()
    
    // MARK: - Token Management
    // Use a Bot Token (xoxb-) for Web API calls (instead of App Token)
    // You can get one from https://api.slack.com/apps > Your App > OAuth & Permissions
    private var botToken: String {
        // In a real app, you would load this from secure storage, keychain, or environment variable
        // For development, we'll use a configuration file that is not tracked by git
        return SlackTokenManager.shared.getToken()
    }
    
    private init() {}
    
    // MARK: - API Requests
    
    func getChannels() async throws -> [SlackChannel] {
        print("\n--- SLACK API: Fetching Channels ---")
        print("Note: Bot needs 'channels:read' scope to list channels")
        
        var request = URLRequest(url: URL(string: "https://slack.com/api/conversations.list")!)
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("Channels API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Channels API Response: \(responseStr)")
        }
        
        let decodedResponse = try JSONDecoder().decode(ChannelsResponse.self, from: data)
        
        if !decodedResponse.ok {
            let errorMsg = decodedResponse.error ?? "Unknown API error"
            print("Slack API Error: \(errorMsg)")
            print("DETAILED ERROR: This could mean the token doesn't have the required scopes. Required: channels:read")
            throw SlackError.apiError(errorMsg)
        }
        
        if let channels = decodedResponse.channels {
            print("SUCCESS: Parsed \(channels.count) channels from the response")
            return channels
        } else {
            print("WARNING: No channels array found in the response")
            return []
        }
    }
    
    func getMessages(channelId: String) async throws -> [SlackAPIMessage] {
        print("\n--- SLACK API: Fetching Messages for Channel \(channelId) ---")
        print("Note: Bot needs 'channels:history' scope and must be in the channel")
        
        var components = URLComponents(string: "https://slack.com/api/conversations.history")!
        components.queryItems = [
            URLQueryItem(name: "channel", value: channelId)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        print("Fetching messages for channel ID: \(channelId)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("Messages API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Messages API Response: \(responseStr)")
        }
        
        let decodedResponse = try JSONDecoder().decode(MessagesResponse.self, from: data)
        
        if !decodedResponse.ok {
            let errorMsg = decodedResponse.error ?? "Unknown API error"
            print("Slack API Error: \(errorMsg)")
            print("DETAILED ERROR: This could mean lacking required scopes (channels:history) or the bot isn't in the channel")
            throw SlackError.apiError(errorMsg)
        }
        
        if let messages = decodedResponse.messages {
            print("SUCCESS: Parsed \(messages.count) messages from the response")
            if messages.isEmpty {
                print("NOTE: This channel exists but has no messages or the bot can't see them")
            }
            return messages
        } else {
            print("WARNING: No messages array found in the response")
            return []
        }
    }
    
    func getUserInfo(userId: String) async throws -> SlackUser {
        var components = URLComponents(string: "https://slack.com/api/users.info")!
        components.queryItems = [
            URLQueryItem(name: "user", value: userId)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("User API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("User API Response: \(responseStr)")
        }
        
        let decodedResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        
        if !decodedResponse.ok {
            let errorMsg = decodedResponse.error ?? "Unknown API error"
            print("Slack API Error: \(errorMsg)")
            throw SlackError.apiError(errorMsg)
        }
        
        return decodedResponse.user
    }
    
    // Add a new method to try joining a channel
    func joinChannel(channelId: String) async throws -> Bool {
        print("\n--- SLACK API: Attempting to Join Channel \(channelId) ---")
        print("Note: Bot needs 'channels:join' scope to join channels")
        
        var components = URLComponents(string: "https://slack.com/api/conversations.join")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        let body = "channel=\(channelId)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("Join Channel API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Join Channel API Response: \(responseStr)")
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let ok = jsonObject?["ok"] as? Bool, ok {
            print("Successfully joined channel \(channelId)")
            return true
        } else if let error = jsonObject?["error"] as? String {
            print("Failed to join channel: \(error)")
            return false
        } else {
            print("Unknown response when joining channel")
            return false
        }
    }
    
    // Send a message to a channel or DM
    func sendMessage(text: String, channelId: String, threadTs: String? = nil) async throws -> String {
        print("\n--- SLACK API: Sending Message to Channel \(channelId) ---")
        print("Note: Bot needs 'chat:write' scope to send messages")
        
        var components = URLComponents(string: "https://slack.com/api/chat.postMessage")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        // Create the request body
        var bodyObject: [String: Any] = [
            "channel": channelId,
            "text": text
        ]
        
        // Add thread_ts if replying to a thread
        if let threadTs = threadTs {
            bodyObject["thread_ts"] = threadTs
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("Send Message API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Send Message API Response: \(responseStr)")
        }
        
        struct SendMessageResponse: Decodable {
            let ok: Bool
            let ts: String?
            let error: String?
        }
        
        let decodedResponse = try JSONDecoder().decode(SendMessageResponse.self, from: data)
        
        if !decodedResponse.ok {
            let errorMsg = decodedResponse.error ?? "Unknown API error"
            print("Slack API Error: \(errorMsg)")
            throw SlackError.apiError(errorMsg)
        }
        
        guard let ts = decodedResponse.ts else {
            throw SlackError.apiError("No timestamp returned for message")
        }
        
        print("Successfully sent message with timestamp: \(ts)")
        return ts
    }
    
    // Add reaction to a message
    func addReaction(name: String, channelId: String, timestamp: String) async throws -> Bool {
        print("\n--- SLACK API: Adding Reaction to Message ---")
        print("Note: Bot needs 'reactions:write' scope to add reactions")
        
        var components = URLComponents(string: "https://slack.com/api/reactions.add")!
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        // Create the request body
        let bodyObject: [String: Any] = [
            "channel": channelId,
            "timestamp": timestamp,
            "name": name  // emoji name without colons (e.g. "thumbsup")
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: bodyObject)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("Add Reaction API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Add Reaction API Response: \(responseStr)")
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let ok = jsonObject?["ok"] as? Bool, ok {
            print("Successfully added reaction to message")
            return true
        } else if let error = jsonObject?["error"] as? String {
            print("Failed to add reaction: \(error)")
            throw SlackError.apiError(error)
        } else {
            print("Unknown response when adding reaction")
            return false
        }
    }
    
    // Get direct message channels
    func getDirectMessageChannels() async throws -> [SlackChannel] {
        print("\n--- SLACK API: Fetching Direct Message Channels ---")
        print("Note: Bot needs 'im:read' scope to list DMs")
        
        var components = URLComponents(string: "https://slack.com/api/conversations.list")!
        components.queryItems = [
            URLQueryItem(name: "types", value: "im")
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(botToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("DM Channels API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("DM Channels API Response: \(responseStr)")
        }
        
        let decodedResponse = try JSONDecoder().decode(ChannelsResponse.self, from: data)
        
        if !decodedResponse.ok {
            let errorMsg = decodedResponse.error ?? "Unknown API error"
            print("Slack API Error: \(errorMsg)")
            throw SlackError.apiError(errorMsg)
        }
        
        if let channels = decodedResponse.channels {
            print("SUCCESS: Parsed \(channels.count) DM channels from the response")
            return channels
        } else {
            print("WARNING: No DM channels array found in the response")
            return []
        }
    }
    
    // MARK: - Models
    
    enum SlackError: Error, LocalizedError {
        case notAuthenticated
        case apiError(String)
        case httpError(Int)
        
        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Not authenticated with Slack"
            case .apiError(let message):
                return "Slack API error: \(message)"
            case .httpError(let code):
                return "HTTP error: \(code)"
            }
        }
    }
    
    // Channel Response
    struct ChannelsResponse: Decodable {
        let ok: Bool
        let channels: [SlackChannel]?
        let error: String?
    }
    
    // Message Response
    struct MessagesResponse: Decodable {
        let ok: Bool
        let messages: [SlackAPIMessage]?
        let error: String?
    }
    
    // User Response
    struct UserResponse: Decodable {
        let ok: Bool
        let user: SlackUser
        let error: String?
    }
}

// Channel Model for API
struct SlackChannel: Decodable, Identifiable {
    let id: String
    let name: String
    let is_channel: Bool
    let is_member: Bool
    // Other fields can be added as needed
}

// User Model for API
struct SlackUser: Decodable {
    let id: String
    let name: String
    let real_name: String?
    let profile: SlackUserProfile
    
    struct SlackUserProfile: Decodable {
        let image_72: String?  // Avatar URL
        let display_name: String
    }
}

// Message Model for API
struct SlackAPIMessage: Decodable {
    let type: String
    let user: String?
    let text: String
    let ts: String
    
    // Thread-related fields
    let thread_ts: String?
    let reply_count: Int?
    let replies: [SlackAPIReply]?
    
    // Reactions
    let reactions: [SlackAPIReaction]?
    
    // Add CodingKeys to handle missing fields gracefully
    enum CodingKeys: String, CodingKey {
        case type, user, text, ts, thread_ts, reply_count, replies, reactions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        type = try container.decode(String.self, forKey: .type)
        ts = try container.decode(String.self, forKey: .ts)
        
        // Optional fields with defaults or nil
        user = try container.decodeIfPresent(String.self, forKey: .user)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        thread_ts = try container.decodeIfPresent(String.self, forKey: .thread_ts)
        reply_count = try container.decodeIfPresent(Int.self, forKey: .reply_count)
        replies = try container.decodeIfPresent([SlackAPIReply].self, forKey: .replies)
        reactions = try container.decodeIfPresent([SlackAPIReaction].self, forKey: .reactions)
    }
    
    // Convert to our app's SlackMessage format
    func toSlackMessage(channelId: String, channelName: String, userName: String, userAvatar: String?) -> SlackMessage {
        let timestamp = Double(ts) ?? 0
        
        // Convert API reactions to app model reactions if present
        var messageReactions: [SlackReaction]?
        if let apiReactions = reactions, !apiReactions.isEmpty {
            messageReactions = apiReactions.map { apiReaction in
                SlackReaction(
                    name: apiReaction.name,
                    count: apiReaction.count,
                    userIds: apiReaction.users
                )
            }
        }
        
        return SlackMessage(
            id: ts,
            userId: user ?? "unknown",
            userName: userName,
            userAvatar: userAvatar,
            channelId: channelId,
            channelName: channelName,
            text: text,
            timestamp: Date(timeIntervalSince1970: timestamp),
            isRead: false,
            attachments: [],
            threadParentId: thread_ts,
            replyCount: reply_count,
            isThreadParent: reply_count != nil && reply_count! > 0,
            reactions: messageReactions
        )
    }
}

// Thread Reply Model
struct SlackAPIReply: Decodable {
    let user: String?
    let ts: String
}

// Reaction Model
struct SlackAPIReaction: Decodable {
    let name: String
    let count: Int
    let users: [String]
} 