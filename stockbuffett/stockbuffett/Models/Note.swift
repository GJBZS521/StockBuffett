import Foundation

/// 心得模型
///
/// 持久化:每个 Note 对应一个 .md 文件,Frontmatter 存元数据,正文为 Markdown。
/// 主题归属:通过所在文件夹的路径推断 topic(即文件名 = 主题名)。
///
/// 示例 .md 文件结构:
/// ```
/// ---
/// id: 7F3A9C2E-1B4D-4E8F-9A0C-3D5E6F7A8B9C
/// title: 止损纪律
/// topic: 交易纪律
/// created_at: 2026-10-17T15:00:00Z
/// updated_at: 2026-10-17T15:00:00Z
/// ---
///
/// # 正文
/// - 单只股票亏损超过 10% 无条件止损
/// - ...
/// ```
struct Note: Identifiable, Codable, Hashable {
    /// 全局唯一 ID,也是文件名({id}.md)
    let id: UUID

    /// 所属主题(文件夹名)
    var topic: String

    /// 标题
    var title: String

    /// Markdown 正文
    var content: String

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        topic: String,
        title: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.topic = topic
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 文件名(不含扩展名)
    var filename: String { id.uuidString }
}

/// Note 持久化辅助:Frontmatter 编解码
extension Note {
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// 序列化为 .md 文件内容(Frontmatter + 正文)
    func toMarkdown() -> String {
        let fm: [String: String] = [
            "id": id.uuidString,
            "title": title,
            "topic": topic,
            "created_at": Note.isoFormatter.string(from: createdAt),
            "updated_at": Note.isoFormatter.string(from: updatedAt)
        ]
        let yaml = fm.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        return "---\n\(yaml)\n---\n\n\(content)"
    }

    /// 从 .md 文件内容解析为 Note
    /// - 解析失败时抛出详细错误
    static func fromMarkdown(_ raw: String, fallbackTopic: String) throws -> Note {
        // 1. 分离 Frontmatter 和正文
        let parts = raw.components(separatedBy: "\n---\n")
        guard parts.count >= 2 else {
            throw NoteError.invalidFormat("缺少 Frontmatter 分隔符")
        }
        let yaml = parts[0].replacingOccurrences(of: "---\n", with: "")
        let body = parts.dropFirst().joined(separator: "\n---\n")

        // 2. 解析 YAML(简单的 key: value 行格式)
        var fields: [String: String] = [:]
        for line in yaml.split(separator: "\n") {
            let lineStr = String(line)
            if let colonIdx = lineStr.firstIndex(of: ":") {
                let key = lineStr[..<colonIdx].trimmingCharacters(in: .whitespaces)
                let value = lineStr[lineStr.index(after: colonIdx)...].trimmingCharacters(in: .whitespaces)
                fields[key] = value
            }
        }

        // 3. 提取必填字段
        guard let idStr = fields["id"], let id = UUID(uuidString: idStr) else {
            throw NoteError.invalidFormat("id 缺失或格式错误")
        }
        guard let title = fields["title"], !title.isEmpty else {
            throw NoteError.invalidFormat("title 缺失")
        }
        let topic = fields["topic"] ?? fallbackTopic

        // 4. 解析日期
        let createdAt = fields["created_at"].flatMap { Note.isoFormatter.date(from: $0) } ?? Date()
        let updatedAt = fields["updated_at"].flatMap { Note.isoFormatter.date(from: $0) } ?? Date()

        return Note(
            id: id,
            topic: topic,
            title: title,
            content: body,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum NoteError: LocalizedError {
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let reason): return "笔记格式错误:\(reason)"
        }
    }
}
