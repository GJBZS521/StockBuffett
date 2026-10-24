import SwiftUI

/// 炒股心得 - 主题列表(首页)
///
/// M2 真实实现:
/// - 从 FileStore 读取主题列表
/// - 创建 / 删除主题
/// - 点击主题 → push NotesListView
/// - 滑动删除(级联删除该主题所有笔记)
struct TopicsListView: View {
    let accentColor: Color

    @State private var topics: [String] = []
    @State private var noteCounts: [String: Int] = [:]
    @State private var showingNewTopic = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if topics.isEmpty {
                EmptyStateView(
                    systemImage: "book.closed",
                    title: "暂无主题",
                    message: "点击右上角 + 创建第一个主题\n开始记录你的交易心得",
                    accentColor: accentColor
                )
            } else {
                List {
                    ForEach(topics, id: \.self) { topic in
                        NavigationLink(value: topic) {
                            TopicRow(
                                topic: topic,
                                noteCount: noteCounts[topic] ?? 0,
                                accentColor: accentColor
                            )
                        }
                    }
                    .onDelete(perform: deleteTopics)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("心得")
        .navigationDestination(for: String.self) { topic in
            NotesListView(topic: topic, accentColor: accentColor)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !topics.isEmpty { EditButton() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewTopic = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewTopic) {
            NewTopicSheet { newName in
                do {
                    try FileStore.shared.createTopic(name: newName)
                    loadTopics()
                } catch {
                    errorMessage = error.localizedDescription
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
        .onAppear(perform: loadTopics)
    }

    private func loadTopics() {
        topics = FileStore.shared.listTopics()
        var counts: [String: Int] = [:]
        for topic in topics {
            counts[topic] = FileStore.shared.listNotes(in: topic).count
        }
        noteCounts = counts
    }

    private func deleteTopics(at offsets: IndexSet) {
        for i in offsets {
            let topic = topics[i]
            do {
                try FileStore.shared.deleteTopic(topic)
            } catch {
                errorMessage = "删除失败: \(error.localizedDescription)"
                break
            }
        }
        loadTopics()
    }
}

/// 主题列表行(文件夹图标 + 主题名 + 笔记数)
private struct TopicRow: View {
    let topic: String
    let noteCount: Int
    let accentColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.system(size: 28))
                .foregroundStyle(accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(topic)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text("\(noteCount) 篇心得")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        TopicsListView(accentColor: .blue)
    }
}
