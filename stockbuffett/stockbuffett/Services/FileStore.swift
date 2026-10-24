import Foundation

/// 文件存储服务 - 管理 App 沙盒内的所有数据文件
///
/// 设计原则:
/// - **简单**:直接用 Foundation FileManager,无数据库依赖
/// - **可读**:数据文件可在 Finder 中直接浏览和编辑
/// - **安全**:文件路径使用 URL,避免字符串拼接错误
/// - **可调试**:支持列出目录内容,方便排查问题
///
/// 目录结构见 SPEC.md §4.1。
final class FileStore {
    static let shared = FileStore()

    private let fileManager = FileManager.default

    private init() {
        ensureDirectories()
    }

    // MARK: - 目录管理

    /// 确保所有数据子目录存在(幂等)
    private func ensureDirectories() {
        let directories = [
            URL.buffettRoot,
            URL.buffettNotes,
            URL.buffettHoldings,
            URL.buffettChats,
            URL.buffettSettings
        ]
        for dir in directories {
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(
                    at: dir,
                    withIntermediateDirectories: true
                )
            }
        }
    }

    // MARK: - 通用查询

    /// 列出指定目录下的所有条目名(不递归)
    func listContents(of directory: URL) -> [String] {
        guard let items = try? fileManager.contentsOfDirectory(atPath: directory.path) else {
            return []
        }
        return items.sorted()
    }

    /// 检查指定路径是否存在(文件或目录)
    func exists(at path: URL) -> Bool {
        fileManager.fileExists(atPath: path.path)
    }

    /// 删除指定路径
    @discardableResult
    func remove(at path: URL) -> Bool {
        guard fileManager.fileExists(atPath: path.path) else { return false }
        do {
            try fileManager.removeItem(at: path)
            return true
        } catch {
            print("[FileStore] remove failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Notes 模块(主题 + 心得)

    /// 列出所有主题名(按字典序排序)
    /// - Returns: 主题文件夹名列表
    func listTopics() -> [String] {
        guard let items = try? fileManager.contentsOfDirectory(
            at: URL.buffettNotes,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return items
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
            .map { $0.lastPathComponent }
            .sorted()
    }

    /// 列出某主题下的所有 Note(轻量版,只读 Frontmatter)
    /// - Parameter topic: 主题名
    /// - Returns: 该主题下所有 .md 文件对应的 Note
    func listNotes(in topic: String) -> [Note] {
        let topicDir = URL.buffettTopic(topic)
        guard let files = try? fileManager.contentsOfDirectory(
            at: topicDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        let mdFiles = files.filter { $0.pathExtension == "md" }
        let notes: [Note] = mdFiles.compactMap { url in
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return try? Note.fromMarkdown(content, fallbackTopic: topic)
        }
        // 按 updatedAt 倒序
        return notes.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// 读取某 Note 的完整内容(已解析,直接可用)
    func readNote(_ note: Note) throws -> Note {
        let url = URL.buffettNoteFile(note)
        let raw = try String(contentsOf: url, encoding: .utf8)
        return try Note.fromMarkdown(raw, fallbackTopic: note.topic)
    }

    /// 写入 Note(新建或更新)
    func writeNote(_ note: Note) throws {
        // 确保主题目录存在
        let topicDir = URL.buffettTopic(note.topic)
        if !fileManager.fileExists(atPath: topicDir.path) {
            try fileManager.createDirectory(at: topicDir, withIntermediateDirectories: true)
        }
        let url = URL.buffettNoteFile(note)
        let content = note.toMarkdown()
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    /// 删除 Note
    func deleteNote(_ note: Note) throws {
        let url = URL.buffettNoteFile(note)
        try fileManager.removeItem(at: url)
    }

    /// 删除主题(含级联删除所有 Note)
    func deleteTopic(_ topic: String) throws {
        let topicDir = URL.buffettTopic(topic)
        try fileManager.removeItem(at: topicDir)
    }

    /// 重命名主题(级联:文件夹重命名,所有 .md 的 topic 字段也更新)
    func renameTopic(from oldName: String, to newName: String) throws {
        let oldDir = URL.buffettTopic(oldName)
        let newDir = URL.buffettTopic(newName)

        // 1. 文件夹重命名
        try fileManager.moveItem(at: oldDir, to: newDir)

        // 2. 更新所有 .md 文件的 topic 字段
        let notes = listNotes(in: newName)
        for var note in notes {
            note.topic = newName
            note.updatedAt = Date()
            try writeNote(note)
        }
    }

    /// 创建新主题(空文件夹)
    /// - Parameter name: 主题名(调用前应已 .asFolderName 处理)
    /// - Throws: `FileStoreError.alreadyExists` 如果同名主题已存在
    func createTopic(name: String) throws {
        let url = URL.buffettTopic(name)
        guard !fileManager.fileExists(atPath: url.path) else {
            throw FileStoreError.alreadyExists(name)
        }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: false)
    }

    // MARK: - Holdings / 每日快照

    private var holdingsRootURL: URL {
        URL.buffettHoldings
    }

    private static let snapshotDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Asia/Shanghai")
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// 列出所有快照(按日期倒序)
    func listSnapshots() -> [DailySnapshot] {
        if !fileManager.fileExists(atPath: holdingsRootURL.path) {
            try? fileManager.createDirectory(at: holdingsRootURL, withIntermediateDirectories: true)
        }
        let urls = (try? fileManager.contentsOfDirectory(at: holdingsRootURL, includingPropertiesForKeys: nil)) ?? []
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> DailySnapshot? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(DailySnapshot.self, from: data)
            }
            .sorted { $0.date > $1.date }
    }

    /// 读快照(按日期精确匹配)
    func readSnapshot(date: Date) -> DailySnapshot? {
        let url = holdingsRootURL.appendingPathComponent("\(Self.snapshotDayFormatter.string(from: date)).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DailySnapshot.self, from: data)
    }

    /// 写快照(覆盖式,同一天会替换)
    func writeSnapshot(_ snapshot: DailySnapshot) throws {
        if !fileManager.fileExists(atPath: holdingsRootURL.path) {
            try fileManager.createDirectory(at: holdingsRootURL, withIntermediateDirectories: true)
        }
        let url = holdingsRootURL.appendingPathComponent("\(Self.snapshotDayFormatter.string(from: snapshot.date)).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: .atomic)
    }

    /// 删快照
    func deleteSnapshot(_ snapshot: DailySnapshot) throws {
        let url = holdingsRootURL.appendingPathComponent("\(Self.snapshotDayFormatter.string(from: snapshot.date)).json")
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    // MARK: - Chats / 对话

    private var chatsRootURL: URL {
        URL.buffettChats
    }

    /// 列出所有对话会话(按更新时间倒序)
    func listChatSessions() -> [ChatSession] {
        if !fileManager.fileExists(atPath: chatsRootURL.path) {
            try? fileManager.createDirectory(at: chatsRootURL, withIntermediateDirectories: true)
        }
        let urls = (try? fileManager.contentsOfDirectory(at: chatsRootURL, includingPropertiesForKeys: nil)) ?? []
        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> ChatSession? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(ChatSession.self, from: data)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    /// 读单个会话
    func readChatSession(id: UUID) -> ChatSession? {
        let url = chatsRootURL.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ChatSession.self, from: data)
    }

    /// 写会话(覆盖式)
    func writeChatSession(_ session: ChatSession) throws {
        if !fileManager.fileExists(atPath: chatsRootURL.path) {
            try fileManager.createDirectory(at: chatsRootURL, withIntermediateDirectories: true)
        }
        let url = chatsRootURL.appendingPathComponent("\(session.id.uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(session)
        try data.write(to: url, options: .atomic)
    }

    /// 删会话
    func deleteChatSession(id: UUID) throws {
        let url = chatsRootURL.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
}

/// FileStore 操作错误
enum FileStoreError: LocalizedError {
    case alreadyExists(String)

    var errorDescription: String? {
        switch self {
        case .alreadyExists(let name): return "主题 \"\(name)\" 已存在"
        }
    }
}
