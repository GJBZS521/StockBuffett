import SwiftUI
import Combine

/// 主题管理器
///
/// - 单例全局访问
/// - @Published 当前主题,SwiftUI 视图自动响应变化
/// - 持久化到 UserDefaults(主题不是敏感数据,无需 Keychain)
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Keys.theme)
        }
    }

    private enum Keys {
        static let theme = "stockbuffett.theme"
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Keys.theme) ?? AppTheme.minimalistGold.rawValue
        self.currentTheme = AppTheme(rawValue: saved) ?? .minimalistGold
    }

    /// 当前主题的色板
    /// 每次访问创建新实例,避免色值被意外 retain
    var colors: ThemeColors {
        currentTheme.makeColors()
    }

    /// 切换主题
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
}
