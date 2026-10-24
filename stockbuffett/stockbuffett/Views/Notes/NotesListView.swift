import SwiftUI

/// 某个主题下的心得列表
///
/// M2:
/// - 显示该主题下所有 Note(按 updatedAt 倒序)
/// - 点击 Note → push NoteDetailView
/// - 右上角 + 新建心得 → 弹 NoteEditorView
/// - 滑动删除
struct NotesListView: View {
    let topic: String
    let accentColor: Color

    @State private var notes: [Note] = []
    @State private var showingNewNote = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    var body: some View {
        Group {
            if notes.isEmpty {
                EmptyStateView(
                    systemImage: "doc.text",
                    title: "暂无心得",
                    message: "点击右上角写第一篇心得\n主题:\(topic)",
                    accentColor: accentColor
                )
            } else {
                List {
                    ForEach(notes) { note in
                        NavigationLink(value: note) {
                            NoteRow(
                                note: note,
                                accentColor: accentColor,
                                dateFormatter: Self.dateFormatter
                            )
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(topic)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Note.self) { note in
            NoteDetailView(note: note, accentColor: accentColor)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !notes.isEmpty { EditButton() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewNote = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NoteEditorView(mode: .create(topic: topic)) {
                loadNotes()
            }
        }
        .onAppear(perform: loadNotes)
    }

    private func loadNotes() {
        notes = FileStore.shared.listNotes(in: topic)
    }

    private func deleteNotes(at offsets: IndexSet) {
        for i in offsets {
            let note = notes[i]
            do {
                try FileStore.shared.deleteNote(note)
            } catch {
                print("[NotesListView] delete failed: \(error)")
            }
        }
        loadNotes()
    }
}

/// 心得列表行(左侧色条 + 标题 + 摘要 + 日期)
private struct NoteRow: View {
    let note: Note
    let accentColor: Color
    let dateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 0) {
            // 左侧色条(accent color)
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.7))
                .frame(width: 3)
                .padding(.vertical, 4)
                .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(note.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(note.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(dateFormatter.string(from: note.updatedAt))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        NotesListView(topic: "交易纪律", accentColor: .blue)
    }
}
