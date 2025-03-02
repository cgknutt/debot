import Foundation

struct SlackChannel: Identifiable, Hashable {
    let id: String
    let name: String
    let isPrivate: Bool
    var description: String?
    var memberCount: Int?
    var topic: String?
    var purpose: String?
    var is_member: Bool = false
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: SlackChannel, rhs: SlackChannel) -> Bool {
        return lhs.id == rhs.id
    }
} 