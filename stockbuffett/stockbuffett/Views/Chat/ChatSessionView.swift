import SwiftUI

/// 单个对话会话页
///
/// M4:
/// - 顶部:标题(可编辑)
/// - 中部:消息列表(用户/AI 区分样式,Markdown 渲染)
/// - 底部:输入框 + 发送按钮
/// - 发送时:取最新上下文拼 system prompt → 调 LLM → 加消息 → 保存
struct ChatSessionView: View {
    let session: ChatSession
    let accentColor: Color
    let onUpdated: () -> Void

    @State private var currentSession: ChatSession
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var editingTitle = false
    @State private var titleDraft: String = ""

    init(session: ChatSession, accentColor: Color, onUpdated: @escaping () -> Void) {
        self.session = session
        self.accentColor = accentColor
        self.onUpdated = onUpdated
        self._currentSession = State(initialValue: session)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if currentSession.messages.isEmpty {
                            EmptyStateView(
                                systemImage: "bubble.left",
                                title: "开始对话",
                                message: "向 AI 提问关于你的持仓或心得\n会自动引用你的真实数据",
                                accentColor: accentColor
                            )
                            .padding(.top, 80)
                        } else {
                            ForEach(currentSession.messages) { msg in
                                MessageBubble(
                                    message: msg,
                                    accentColor: accentColor
                                )
                                .id(msg.id)
                            }
                        }

                        if isLoading {
                            HStack {
                                Spacer(minLength: 40)
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("思考中...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                Spacer(minLength: 40)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: currentSession.messages.count) { _, _ in
                    if let last = currentSession.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    } else {
                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                    }
                }
            }

            // 输入栏
            HStack(alignment: .bottom, spacing: 8) {
                TextField(
                    "问我关于持仓或心得的问题...",
                    text: $inputText,
                    axis: .vertical
                )
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSend ? accentColor : .gray)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle(currentSession.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    titleDraft = currentSession.title
                    editingTitle = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .alert("重命名对话", isPresented: $editingTitle) {
            TextField("标题", text: $titleDraft)
            Button("取消", role: .cancel) {}
            Button("保存") {
                currentSession.title = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if currentSession.title.isEmpty {
                    currentSession.title = "新对话"
                }
                save()
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
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    private func sendMessage() {
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }

        // 1. 加用户消息
        let userMsg = ChatMessage(role: .user, content: userText)
        currentSession.messages.append(userMsg)
        // 如果标题还是默认,改成首条消息预览
        if currentSession.title == "新对话" {
            currentSession.title = String(userText.prefix(20))
        }
        inputText = ""
        isLoading = true
        save()

        // 2. 调 LLM
        Task {
            do {
                guard let apiKey = KeychainStore.shared.getAPIKey() else {
                    throw LLMClient.LLMError.noApiKey
                }
                let client = LLMClient(apiKey: apiKey)
                let system = PromptBuilder.buildSystemPrompt()
                let reply = try await client.sendMessage(
                    system: system,
                    messages: currentSession.messages
                )
                let assistantMsg = ChatMessage(role: .assistant, content: reply)
                currentSession.messages.append(assistantMsg)
                save()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func save() {
        currentSession.updatedAt = Date()
        do {
            try FileStore.shared.writeChatSession(currentSession)
            onUpdated()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}
