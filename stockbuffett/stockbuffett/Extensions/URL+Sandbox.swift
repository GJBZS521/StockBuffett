import Foundation

/// App 沙盒内 buffett 数据目录的统一访问入口
///
/// 完整目录结构见 SPEC.md §4.1:
/// ```
/// {Documents}/buffett/
/// ├── notes/
/// │   └── {主题名}/          ← 主题 = 文件夹
/// │       └── {uuid}.md      ← 心得 = Markdown 文件
/// ├── holdings/
/// ├── chats/
/// └── settings/
/// ```
extension URL {
    /// buffett 数据根目录
    static var buffettRoot: URL {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        return documents.appendingPathComponent("buffett", isDirectory: true)
    }

    /// 心得数据目录(主题文件夹 + Markdown 文件)
    static var buffettNotes: URL {
        buffettRoot.appendingPathComponent("notes", isDirectory: true)
    }

    /// 持股数据目录(按日期 JSON 文件)
    static var buffettHoldings: URL {
        buffettRoot.appendingPathComponent("holdings", isDirectory: true)
    }

    /// 对话数据目录(按 session JSON 文件)
    static var buffettChats: URL {
        buffettRoot.appendingPathComponent("chats", isDirectory: true)
    }

    /// 设置数据目录(API Key 等敏感配置)
    /// **不在备份范围内**(见 SPEC.md §3.5)
    static var buffettSettings: URL {
        buffettRoot.appendingPathComponent("settings", isDirectory: true)
    }

    /// 某个主题的目录
    /// - Parameter topic: 主题名(文件夹名,调用前应已 .asFolderName 处理)
    static func buffettTopic(_ topic: String) -> URL {
        buffettNotes.appendingPathComponent(topic, isDirectory: true)
    }

    /// 某个心得的文件 URL
    /// - Parameter note: Note 对象
    static func buffettNoteFile(_ note: Note) -> URL {
        buffettTopic(note.topic).appendingPathComponent("\(note.filename).md")
    }
}
