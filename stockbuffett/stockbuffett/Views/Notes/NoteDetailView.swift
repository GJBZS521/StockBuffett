import SwiftUI

/// 心得详情页(查看模式)
///
/// M2:
/// - 顶部:标题 + 主题 + 更新时间
/// - 正文:Markdown 渲染(`AttributedString(markdown:)`)
/// - 右上角编辑按钮 → 弹 NoteEditorView
struct NoteDetailView: View {
    let note: Note
    let accentColor: Color

    @State private var loadedNote: Note?
    @State private var showingEditor = false
    @State private var loadError: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let n = loadedNote {
                    // 标题
                    Text(n.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    // 元数据行(主题 + 时间)
                    HStack(spacing: 12) {
                        Label(n.topic, systemImage: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label(Self.dateFormatter.string(from: n.updatedAt), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    // Markdown 正文
                    if let attributed = try? AttributedString(markdown: n.content) {
                        Text(attributed)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Markdown 解析失败时的兜底
                        Text(n.content)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if let err = loadError {
                    // 加载失败
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange)
                        Text("加载失败")
                            .font(.headline)
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(40)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(loadedNote == nil)
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let n = loadedNote {
                NoteEditorView(mode: .edit(note: n)) {
                    // 编辑后重新读取
                    do {
                        loadedNote = try FileStore.shared.readNote(n)
                    } catch {
                        loadError = error.localizedDescription
                    }
                }
            }
        }
        .onAppear(perform: loadInitial)
    }

    private func loadInitial() {
        do {
            loadedNote = try FileStore.shared.readNote(note)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    let sample = Note(
        topic: "交易纪律",
        title: "止损纪律",
        content: """
# 核心原则

- 单只股票亏损超过 **10%** 无条件止损
- 不在开盘前 30 分钟做决策
- 情绪失控时停止交易

> 保住本金,才有翻盘机会。
"""
    )
    return NavigationStack {
        NoteDetailView(note: sample, accentColor: .blue)
    }
}
