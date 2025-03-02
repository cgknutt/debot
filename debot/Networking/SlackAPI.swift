import Foundation
// Remove explicit imports since we're already in the debot module
// import struct debot.SlackMessage
// import struct debot.SlackReaction

class SlackAPI {
    static let shared = SlackAPI()
    
    // MARK: - Token Management
    // Use a Bot Token (xoxb-) for Web API calls (instead of App Token)
    // You can get one from https://api.slack.com/apps > Your App > OAuth & Permissions
    var botToken: String? {
        // In a real app, you would load this from secure storage, keychain, or environment variable
        // For development, we'll use a configuration file that is not tracked by git
        let token = SlackTokenManager.shared.getToken()
        
        // Validate token format
        if token.isEmpty {
            print("⚠️ WARNING: Empty Slack token!")
            return nil
        } else if !token.hasPrefix("xoxb-") {
            print("⚠️ WARNING: Slack token doesn't have expected prefix 'xoxb-'")
            return nil  // Return nil for invalid tokens as well
        }
        
        return token
    }
    
    private init() {}
    
    // MARK: - API Requests
    
    func getChannels() async throws -> [SlackChannel] {
        guard let token = botToken else {
            throw SlackAPIError.noToken
        }
        
        let url = URL(string: "https://slack.com/api/conversations.list")!
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            URLQueryItem(name: "exclude_archived", value: "true"),
            URLQueryItem(name: "limit", value: "1000"),
            URLQueryItem(name: "types", value: "public_channel")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SlackAPIError.requestFailed
        }
        
        let result = try JSONDecoder().decode(ChannelListResponse.self, from: data)
        
        if let error = result.error {
            throw SlackAPIError.slackError(error)
        }
        
        guard let channels = result.channels else {
            return []
        }
        
        // Convert SlackChannelResponse to SlackChannel
        return channels.map { channelResponse in
            SlackChannel(
                id: channelResponse.id,
                name: channelResponse.name,
                isPrivate: !channelResponse.is_channel,
                description: nil,
                memberCount: nil,
                topic: nil,
                purpose: nil
            )
        }
    }
    
    func getMessages(channelId: String, cursor: String? = nil) async throws -> (messages: [SlackAPIMessage], nextCursor: String?, hasMore: Bool) {
        print("\n--- SLACK API: Fetching Messages for Channel \(channelId) ---")
        print("Note: Bot needs 'channels:history' scope and must be in the channel")
        
        var urlComponents = URLComponents(string: "https://slack.com/api/conversations.history")!
        var queryItems = [URLQueryItem(name: "channel", value: channelId)]
        
        // Add cursor for pagination if provided
        if let cursor = cursor, !cursor.isEmpty {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        urlComponents.queryItems = queryItems
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
        print("Fetching messages for channel ID: \(channelId)\(cursor != nil ? " with cursor: \(cursor!)" : "")")
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
        
        let nextCursor = decodedResponse.response_metadata?.next_cursor
        let hasMore = decodedResponse.has_more ?? false
        
        if let messages = decodedResponse.messages {
            print("SUCCESS: Parsed \(messages.count) messages from the response")
            if messages.isEmpty {
                print("NOTE: This channel exists but has no messages or the bot can't see them")
            }
            return (messages: messages, nextCursor: nextCursor, hasMore: hasMore)
        } else {
            print("WARNING: No messages array found in the response")
            return (messages: [], nextCursor: nil, hasMore: false)
        }
    }
    
    func getUserInfo(userId: String) async throws -> SlackAPIUser {
        var urlComponents = URLComponents(string: "https://slack.com/api/users.info")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user", value: userId)
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
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
        
        let urlComponents = URLComponents(string: "https://slack.com/api/conversations.join")!
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
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
        
        let urlComponents = URLComponents(string: "https://slack.com/api/chat.postMessage")!
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
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
    
    // Remove reaction from a message
    func removeReaction(name: String, channelId: String, timestamp: String) async throws -> Bool {
        print("\n--- SLACK API: Removing Reaction from Message ---")
        print("Note: Bot needs 'reactions:write' scope to remove reactions")
        
        let urlComponents = URLComponents(string: "https://slack.com/api/reactions.remove")!
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
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
            print("Remove Reaction API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Remove Reaction API Response: \(responseStr)")
        }
        
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let ok = jsonObject?["ok"] as? Bool, ok {
            print("Successfully removed reaction from message")
            return true
        } else if let error = jsonObject?["error"] as? String {
            print("Failed to remove reaction: \(error)")
            throw SlackError.apiError(error)
        } else {
            print("Unknown response when removing reaction")
            return false
        }
    }
    
    // Add reaction to a message
    func addReaction(name: String, channelId: String, timestamp: String) async throws -> Bool {
        print("\n--- SLACK API: Adding Reaction to Message ---")
        print("Note: Bot needs 'reactions:write' scope to add reactions")
        
        let urlComponents = URLComponents(string: "https://slack.com/api/reactions.add")!
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
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
        guard let token = botToken else {
            throw SlackAPIError.noToken
        }
        
        let url = URL(string: "https://slack.com/api/conversations.list")!
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [
            URLQueryItem(name: "exclude_archived", value: "true"),
            URLQueryItem(name: "limit", value: "1000"),
            URLQueryItem(name: "types", value: "im")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SlackAPIError.requestFailed
        }
        
        let result = try JSONDecoder().decode(ChannelListResponse.self, from: data)
        
        if let error = result.error {
            throw SlackAPIError.slackError(error)
        }
        
        guard let channels = result.channels else {
            return []
        }
        
        // Convert SlackChannelResponse to SlackChannel
        return channels.map { channelResponse in
            SlackChannel(
                id: channelResponse.id,
                name: channelResponse.name,
                isPrivate: true,
                description: nil,
                memberCount: nil,
                topic: nil,
                purpose: nil
            )
        }
    }
    
    // MARK: - User Management
    
    // Get the current user's ID
    func getCurrentUserId() async throws -> String {
        print("\n--- SLACK API: Fetching Current User ID ---")
        print("Note: Bot needs 'users:read' scope to get user info")
        
        var request = URLRequest(url: URL(string: "https://slack.com/api/auth.test")!)
        request.setValue("Bearer \(botToken ?? "")", forHTTPHeaderField: "Authorization")
        
        // Add timeout
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Debug response
        if let httpResponse = response as? HTTPURLResponse {
            print("Auth Test API Status Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                throw SlackError.httpError(httpResponse.statusCode)
            }
        }
        
        // Print full response for debugging
        if let responseStr = String(data: data, encoding: .utf8) {
            print("Auth Test API Response: \(responseStr)")
        }
        
        // Parse response
        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let userId = jsonObject?["user_id"] as? String {
            print("Current User ID: \(userId)")
            return userId
        } else if let error = jsonObject?["error"] as? String {
            throw SlackError.apiError(error)
        } else {
            throw SlackError.apiError("Could not get user ID")
        }
    }
    
    // MARK: - Models
    
    enum SlackAPIError: Error {
        case noToken
        case requestFailed
        case slackError(String)
    }
    
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
    struct ChannelListResponse: Decodable {
        let ok: Bool
        let channels: [SlackChannelResponse]?
        let error: String?
    }
    
    // Message Response
    struct MessagesResponse: Decodable {
        let ok: Bool
        let messages: [SlackAPIMessage]?
        let error: String?
        let has_more: Bool?
        let response_metadata: ResponseMetadata?
    }
    
    struct ResponseMetadata: Decodable {
        let next_cursor: String?
    }
    
    // User Response
    struct UserResponse: Decodable {
        let ok: Bool
        let user: SlackAPIUser
        let error: String?
    }
}

// Channel Model for API
struct SlackChannelResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let is_channel: Bool
    let is_member: Bool
    // Other fields can be added as needed
}

// User Model for API
struct SlackAPIUser: Decodable {
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
    
    // Attachments
    let attachments: [SlackAPIAttachment]?
    
    // Add CodingKeys to handle missing fields gracefully
    enum CodingKeys: String, CodingKey {
        case type, user, text, ts, thread_ts, reply_count, replies, reactions, attachments
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
        attachments = try container.decodeIfPresent([SlackAPIAttachment].self, forKey: .attachments)
    }
    
    // Convert to our app's SlackMessage format
    func toSlackMessage(channelId: String, channelName: String, userName: String, userAvatar: String?, isRead: Bool = false) -> SlackMessage {
        let timestamp = Double(ts) ?? 0
        
        // Convert API reactions to app model reactions if present
        var messageReactions: [SlackReaction]?
        if let apiReactions = reactions, !apiReactions.isEmpty {
            messageReactions = apiReactions.map { apiReaction in
                // Use fully qualified name to avoid ambiguity
                SlackReaction(
                    name: apiReaction.name,
                    count: apiReaction.count,
                    userIds: apiReaction.users
                )
            }
        }
        
        // Convert API attachments to app model attachments if present
        var messageAttachments: [SlackAttachment] = []
        if let apiAttachments = attachments, !apiAttachments.isEmpty {
            for (index, attachment) in apiAttachments.enumerated() {
                let attachmentId = "att_\(ts)_\(index)"
                
                // Determine the type of media in the attachment
                var imageUrl: String? = nil
                var videoUrl: String? = nil
                var audioUrl: String? = nil
                var documentUrl: String? = nil
                var fileType: String? = nil
                
                if let url = attachment.image_url ?? attachment.thumb_url {
                    // Unused variable - assigning to _ to avoid warning
                    _ = url.lowercased()
                    
                    // Check for video files and services
                    if isVideoURL(url) {
                        videoUrl = url
                        fileType = "video"
                    }
                    // Check for audio files
                    else if isAudioURL(url) {
                        audioUrl = url
                        fileType = "audio"
                    }
                    // Check for document files
                    else if isDocumentURL(url) {
                        documentUrl = url
                        fileType = getDocumentType(url)
                    }
                    // Default to image if not a special type
                    else {
                        imageUrl = url
                        fileType = "image"
                    }
                }
                
                messageAttachments.append(SlackAttachment(
                    id: attachmentId,
                    title: attachment.title,
                    text: attachment.text,
                    imageUrl: imageUrl,
                    videoUrl: videoUrl,
                    audioUrl: audioUrl,
                    documentUrl: documentUrl,
                    fileType: fileType,
                    color: attachment.color
                ))
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
            timestamp: String(timestamp),
            isRead: isRead,
            attachments: messageAttachments,
            threadParentId: thread_ts,
            replyCount: reply_count,
            isThreadParent: reply_count != nil && reply_count! > 0,
            reactions: messageReactions
        )
    }
    
    // Helper to determine if a URL is for a video
    private func isVideoURL(_ urlString: String) -> Bool {
        let videoExtensions = [".mp4", ".mov", ".avi", ".webm"]
        let videoServices = ["youtube.com", "youtu.be", "vimeo.com", "tiktok.com"]
        let lowercasedUrl = urlString.lowercased()
        
        return videoExtensions.contains { lowercasedUrl.hasSuffix($0) } ||
               videoServices.contains { lowercasedUrl.contains($0) }
    }
    
    // Helper to determine if a URL is for an audio file
    private func isAudioURL(_ urlString: String) -> Bool {
        let audioExtensions = [".mp3", ".wav", ".ogg", ".aac", ".flac", ".m4a"]
        let audioServices = ["spotify.com", "apple.music", "soundcloud.com", "bandcamp.com"]
        let lowercasedUrl = urlString.lowercased()
        
        return audioExtensions.contains { lowercasedUrl.hasSuffix($0) } ||
               audioServices.contains { lowercasedUrl.contains($0) }
    }
    
    // Helper to determine if a URL is for a document
    private func isDocumentURL(_ urlString: String) -> Bool {
        let documentExtensions = [
            ".pdf", ".doc", ".docx", ".xls", ".xlsx", 
            ".ppt", ".pptx", ".txt", ".rtf", ".csv",
            ".zip", ".rar", ".7z"
        ]
        let documentServices = [
            "docs.google.com", "sheets.google.com", "slides.google.com",
            "drive.google.com", "dropbox.com", "onedrive", "box.com"
        ]
        let lowercasedUrl = urlString.lowercased()
        
        return documentExtensions.contains { lowercasedUrl.hasSuffix($0) } ||
               documentServices.contains { lowercasedUrl.contains($0) }
    }
    
    // Helper to determine document type
    private func getDocumentType(_ urlString: String) -> String {
        let lowercasedUrl = urlString.lowercased()
        
        // Check for services first
        if lowercasedUrl.contains("docs.google.com") { return "gdoc" }
        if lowercasedUrl.contains("sheets.google.com") { return "gsheet" }
        if lowercasedUrl.contains("slides.google.com") { return "gslide" }
        if lowercasedUrl.contains("drive.google.com") { return "gdrive" }
        if lowercasedUrl.contains("dropbox.com") { return "dropbox" }
        if lowercasedUrl.contains("onedrive") { return "onedrive" }
        if lowercasedUrl.contains("box.com") { return "box" }
        
        // Check for file extensions
        if lowercasedUrl.hasSuffix(".pdf") { return "pdf" }
        if lowercasedUrl.hasSuffix(".doc") || lowercasedUrl.hasSuffix(".docx") { return "word" }
        if lowercasedUrl.hasSuffix(".xls") || lowercasedUrl.hasSuffix(".xlsx") { return "excel" }
        if lowercasedUrl.hasSuffix(".ppt") || lowercasedUrl.hasSuffix(".pptx") { return "powerpoint" }
        if lowercasedUrl.hasSuffix(".txt") { return "text" }
        if lowercasedUrl.hasSuffix(".rtf") { return "rtf" }
        if lowercasedUrl.hasSuffix(".csv") { return "csv" }
        if lowercasedUrl.hasSuffix(".zip") || lowercasedUrl.hasSuffix(".rar") || lowercasedUrl.hasSuffix(".7z") { return "archive" }
        
        return "document" // Default
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

// Attachment Model for API
struct SlackAPIAttachment: Decodable {
    let title: String?
    let text: String?
    let image_url: String?
    let thumb_url: String?
    let color: String?
} 