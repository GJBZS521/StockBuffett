import SwiftUI

/// Theme 色板协议
///
/// 每个 Theme 实现以下 12+ 个色值,保证所有 UI 元素
/// 都从 ThemeManager 取色,不直接 hard-code 颜色。
///
/// 设计纪律:
/// - 所有视图必须从 ThemeManager.colors 取色,不允许 hard-code
/// - 改主题时改一处,全 App 生效
protocol ThemeColors {
    /// 全局 tint(Tab 选中态、Button 高亮)
    var tint: Color { get }

    /// 4 个 Tab 的 Accent 色(EmptyStateView 等用)
    var accentNotes: Color { get }       // 心得
    var accentHoldings: Color { get }    // 持股
    var accentChat: Color { get }        // 建议
    var accentSettings: Color { get }    // 设置

    /// 品牌主色
    var brandPrimary: Color { get }

    /// 状态色(用于盈亏、警示等)
    var profit: Color { get }
    var loss: Color { get }
    var warning: Color { get }

    /// 背景层
    var pageBackground: Color { get }
    var cardBackground: Color { get }

    /// 文本
    var primaryText: Color { get }
    var secondaryText: Color { get }
}
