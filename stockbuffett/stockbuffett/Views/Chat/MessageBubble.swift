import SwiftUI

/// 单条消息气泡(用户 vs AI 不同样式)
struct MessageBubble: View {
    let message: ChatMessage
    let accentColor: Color

    private var isUser: Bool { message.role == .user }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // 角色标签
                Text(isUser ? "我" : "AI")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)

                // 消息内容(支持 Markdown)
                if let attributed = try? AttributedString(markdown: message.content) {
                    Text(attributed)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    Text(message.content)
                        .font(.body)
                        .textSelection(.enabled)
                }

                // 时间戳
                Text(Self.timeFormatter.string(from: message.createdAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUser
                          ? accentColor.opacity(0.15)
                          : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isUser ? Color.clear : Color.gray.opacity(0.15),
                        lineWidth: 0.5
                    )
            )

            if !isUser { Spacer(minLength: 40) }
        }
    }
}
