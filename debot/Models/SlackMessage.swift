import Foundation
import SwiftUI

struct SlackMessage: Identifiable, Equatable, Hashable {
    let id: String
    let channelId: String
    let channelName: String?
    let userId: String
    let userName: String
    let userAvatar: URL?
    let text: String
    let timestamp: String
    let reactions: [SlackReaction]
    let threadReplies: Int
    let isThreadParent: Bool
    let threadTs: String?
    let attachments: [SlackAttachment]
    var isRead: Bool = false
    
    var formattedTime: String {
        guard let timeInterval = Double(timestamp) else { return "" }
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Add a computed property for timestamp as Double for sorting
    var timestampDouble: Double {
        return Double(timestamp) ?? 0
    }
    
    static func == (lhs: SlackMessage, rhs: SlackMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(
        id: String,
        userId: String,
        userName: String,
        userAvatar: URL? = nil,
        channelId: String,
        channelName: String?,
        text: String,
        timestamp: String,
        isRead: Bool = false,
        attachments: [SlackAttachment] = [],
        threadParentId: String? = nil,
        replyCount: Int? = nil,
        isThreadParent: Bool = false,
        reactions: [SlackReaction] = []
    ) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.channelId = channelId
        self.channelName = channelName
        self.text = text
        self.timestamp = timestamp
        self.attachments = attachments
        self.threadTs = threadParentId
        self.threadReplies = replyCount ?? 0
        self.isThreadParent = isThreadParent
        self.reactions = reactions
        self.isRead = isRead
    }
}

struct SlackReaction: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let count: Int
    let users: [String]
}

struct SlackAttachment: Identifiable, Hashable {
    let id = UUID()
    let title: String?
    let text: String?
    let color: Color?
    let imageUrl: URL?
    let thumbUrl: URL?
    
    init(title: String? = nil, text: String? = nil, colorHex: String? = nil, imageUrl: URL? = nil, thumbUrl: URL? = nil) {
        self.title = title
        self.text = text
        self.imageUrl = imageUrl
        self.thumbUrl = thumbUrl
        
        if let colorHex = colorHex {
            self.color = Color(hex: colorHex)
        } else {
            self.color = nil
        }
    }
}

struct SlackUser: Identifiable, Hashable {
    let id: String
    let name: String
    let realName: String?
    let avatarUrl: URL?
    let isBot: Bool
}

// Extension to support hex color initialization
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