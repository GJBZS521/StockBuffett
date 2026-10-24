import Foundation

/// 聊天消息
struct ChatMessage: Codable, Identifiable, Hashable {
    let id: UUID
    let role: Role
    var content: String
    let createdAt: Date

    enum Role: String, Codable, Hashable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: Role,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}
