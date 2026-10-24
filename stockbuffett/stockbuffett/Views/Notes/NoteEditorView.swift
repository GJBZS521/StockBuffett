import SwiftUI

/// 心得编辑器(新建 / 编辑)
///
/// M2:
/// - 顶部:标题输入
/// - 中部:Markdown 内容编辑(TextEditor,等宽字体)
/// - 底部:保存 / 取消
/// - 用于新建和编辑两种场景(由 Mode 区分)
struct NoteEditorView: View {
    enum Mode {
        case create(topic: String)
        case edit(note: Note)
    }

    let mode: Mode
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var editingId: UUID = UUID()
    @State private var editingTopic: String = ""
    @State private var errorMessage: String?

    private var isCreate: Bool {
        if case .create = mode { return true } else { return false }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("心得标题", text: $title)
                        .submitLabel(.done)
                }

                Section {
                    TextEditor(text: $content)
                        .frame(minHeight: 300)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .background(Color(.secondarySystemGroupedBackground))
                } header: {
                    Text("内容(支持 Markdown)")
                } footer: {
                    Text("支持 # 标题、**粗体**、*斜体*、`代码`、- 列表 等语法")
                        .font(.caption2)
                }

                if !isCreate {
                    Section("元数据") {
                        LabeledContent("所属主题", value: editingTopic)
                        LabeledContent("ID") {
                            Text(editingId.uuidString)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            }
            .navigationTitle(isCreate ? "新建心得" : "编辑心得")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
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
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        switch mode {
        case .create(let topic):
            editingTopic = topic
            // 编辑器留空
        case .edit(let note):
            editingId = note.id
            editingTopic = note.topic
            title = note.title
            content = note.content
        }
    }

    private func save() {
        let now = Date()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let noteToSave: Note
        switch mode {
        case .create:
            noteToSave = Note(
                id: UUID(),
                topic: editingTopic,
                title: trimmedTitle,
                content: content,
                createdAt: now,
                updatedAt: now
            )
        case .edit(let original):
            noteToSave = Note(
                id: original.id,
                topic: original.topic,
                title: trimmedTitle,
                content: content,
                createdAt: original.createdAt,
                updatedAt: now
            )
        }

        do {
            try FileStore.shared.writeNote(noteToSave)
            onSaved()
            dismiss()
        } catch {
            errorMessage = "保存失败:\(error.localizedDescription)"
        }
    }
}

#Preview {
    NoteEditorView(mode: .create(topic: "交易纪律")) {}
}
