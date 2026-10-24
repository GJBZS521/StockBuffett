import Foundation

/// 文件系统安全的字符串处理
extension String {
    /// 将字符串转为文件系统安全的文件夹名
    ///
    /// 处理规则:
    /// - 移除路径分隔符(`/` `\`)
    /// - 替换其他非法字符(`?`, `*`, `<`, `>`, `|`, `"`, `:`, `\0`)为下划线
    /// - 首尾空白裁剪
    /// - 限制长度为 1-50 字符
    /// - 空字符串返回 nil
    var asFolderName: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let invalidChars = CharacterSet(charactersIn: "/\\?*<>\"|:\0")
        let safe = trimmed.unicodeScalars.map { invalidChars.contains($0) ? "_" : String($0) }.joined()

        let limited = String(safe.prefix(50))
        return limited.isEmpty ? nil : limited
    }

    /// 用于文件名(类似 asFolderName,但额外处理 .md 扩展名保护)
    var asFilename: String {
        let invalidChars = CharacterSet(charactersIn: "/\\?*<>\"|:\0")
        let safe = self.unicodeScalars.map { invalidChars.contains($0) ? "_" : String($0) }.joined()
        return String(safe.prefix(50))
    }
}
