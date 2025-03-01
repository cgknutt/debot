import Foundation
import SwiftUI

/// Represents a message from Slack
public struct SlackMessage: Identifiable, Hashable {
    public let id: String
    public let userId: String
    public let userName: String
    public let userAvatar: String?
    public let channelId: String
    public let channelName: String
    public let text: String
    public let timestamp: Date
    public let isRead: Bool
    public let attachments: [SlackAttachment]
    
    // Thread support
    public let threadParentId: String?      // If this message is part of a thread, this is the parent message ID
    public let replyCount: Int?             // Number of replies in thread
    public let isThreadParent: Bool         // True if this message has replies
    
    // Reactions
    public let reactions: [SlackReaction]?  // Emoji reactions to this message
    
    public init(
        id: String,
        userId: String,
        userName: String,
        userAvatar: String? = nil,
        channelId: String,
        channelName: String,
        text: String,
        timestamp: Date,
        isRead: Bool = false,
        attachments: [SlackAttachment] = [],
        threadParentId: String? = nil,
        replyCount: Int? = nil,
        isThreadParent: Bool = false,
        reactions: [SlackReaction]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.channelId = channelId
        self.channelName = channelName
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
        self.attachments = attachments
        self.threadParentId = threadParentId
        self.replyCount = replyCount
        self.isThreadParent = isThreadParent
        self.reactions = reactions
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SlackMessage, rhs: SlackMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Represents an attachment in a Slack message
public struct SlackAttachment: Identifiable, Hashable {
    public let id: String
    public let title: String?
    public let text: String?
    public let imageUrl: String?
    public let color: Color?
    
    public init(
        id: String,
        title: String? = nil,
        text: String? = nil,
        imageUrl: String? = nil,
        color: String? = nil
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.imageUrl = imageUrl
        
        if let colorHex = color {
            self.color = Color(hex: colorHex)
        } else {
            self.color = nil
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SlackAttachment, rhs: SlackAttachment) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Represents a reaction to a Slack message
public struct SlackReaction: Identifiable, Hashable {
    public var id: String { name } // Added for Identifiable conformance
    public let name: String       // Emoji name (e.g., "thumbsup")
    public let count: Int         // Number of users who reacted with this emoji
    public let userIds: [String]  // IDs of users who reacted
    
    // Computed property to convert the name to an emoji for display
    public var emoji: String {
        return SlackReaction.emojiFromName(name)
    }
    
    // Static method to convert emoji name to emoji
    public static func emojiFromName(_ name: String) -> String {
        // Map common reaction names to emoji
        let emojiMap: [String: String] = [
            "thumbsup": "👍",
            "thumbsdown": "👎",
            "heart": "❤️",
            "joy": "😂",
            "smile": "😀",
            "tada": "🎉",
            "clap": "👏",
            "fire": "🔥",
            "eyes": "👀",
            "thinking_face": "🤔",
            "pray": "🙏",
            "100": "💯",
            "rocket": "🚀",
            "raised_hands": "🙌",
            "ok_hand": "👌"
        ]
        
        return emojiMap[name] ?? "👍" // Default to thumbs up if not found
    }
    
    // Computed property to check if the current user has reacted
    public var userHasReacted: Bool {
        // This would need to be modified to check against the current user ID
        return false
    }
    
    // Initializer
    public init(name: String, count: Int, userIds: [String]) {
        self.name = name
        self.count = count
        self.userIds = userIds
    }
    
    // Equatable conformance
    public static func == (lhs: SlackReaction, rhs: SlackReaction) -> Bool {
        return lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 