import SwiftUI

/// 操作建议 - 对话列表(首页)
///
/// M4 真实实现:
/// - 从 FileStore 读取所有对话会话(按更新时间倒序)
/// - 右上 `+` → 新建空对话 → 跳到 ChatSessionView
/// - 点击会话 → 进 ChatSessionView
/// - 滑动删除会话
struct ChatListView: View {
    let accentColor: Color
    @Binding var navigationPath: NavigationPath

    @State private var sessions: [ChatSession] = []
    @State private var errorMessage: String?

    private var hasAPIKey: Bool {
        KeychainStore.shared.hasAPIKey
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    var body: some View {
        Group {
            if sessions.isEmpty {
                EmptyStateView(
                    systemImage: "bubble.left.and.bubble.right",
                    title: "暂无对话",
                    message: hasAPIKey
                        ? "点击右上角 + 开始第一次对话\n会自动带上你的心得和持仓上下文"
                        : "请先在「设置」里配置 MiniMax API Key\n再点击右上 + 开始对话",
                    accentColor: accentColor
                )
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink(value: session) {
                            ChatSessionRow(
                                session: session,
                                dateFormatter: Self.dateFormatter
                            )
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("操作建议")
        .navigationDestination(for: ChatSession.self) { session in
            ChatSessionView(
                session: session,
                accentColor: accentColor,
                onUpdated: loadSessions
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !sessions.isEmpty { EditButton() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newSession()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .alert("提示", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear(perform: loadSessions)
    }

    private func loadSessions() {
        sessions = FileStore.shared.listChatSessions()
    }

    private func newSession() {
        let session = ChatSession()
        do {
            try FileStore.shared.writeChatSession(session)
            loadSessions()
            navigationPath.append(session)
        } catch {
            errorMessage = "创建失败: \(error.localizedDescription)"
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for i in offsets {
            do {
                try FileStore.shared.deleteChatSession(id: sessions[i].id)
            } catch {
                errorMessage = "删除失败: \(error.localizedDescription)"
                break
            }
        }
        loadSessions()
    }
}

/// 对话列表行
private struct ChatSessionRow: View {
    let session: ChatSession
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 24))
                .foregroundStyle(session.messages.isEmpty ? Color.secondary : Color.accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(dateFormatter.string(from: session.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    private var preview: String {
        if let msg = session.firstUserMessage {
            return msg
        }
        return session.messages.isEmpty ? "新对话,等待提问..." : "\(session.messages.count) 条消息"
    }
}
