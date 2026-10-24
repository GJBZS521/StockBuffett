import Foundation

/// 聊天会话
///
/// 一次完整对话 = 一个 ChatSession,包含多轮 messages。
/// 存储位置: `~/Documents/buffett/chats/{session-id}.json`
struct ChatSession: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "新对话",
        messages: [ChatMessage] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 第一条用户消息的预览(用作默认标题)
    var firstUserMessage: String? {
        messages.first(where: { $0.role == .user })?.content
    }
}
