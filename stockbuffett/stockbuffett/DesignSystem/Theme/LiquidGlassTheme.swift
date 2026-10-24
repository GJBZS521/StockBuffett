import SwiftUI
import UIKit

/// 主题 D · Liquid Glass 跟随系统
///
/// iOS 26+ 用户享受真实 `.glassEffect()` 效果
/// iOS 17-25 自动降级到 `.regularMaterial`(也很现代)
///
/// 风格:最贴近 iOS 26 系统原生 App(Apple Music / App Store)
struct LiquidGlassTheme: ThemeColors {
    var tint: Color { Color.accentColor } // 系统蓝

    var accentNotes: Color { Color.accentColor }
    var accentHoldings: Color { Color.green }
    var accentChat: Color { Color.purple }
    var accentSettings: Color { Color.gray }

    var brandPrimary: Color { Color.accentColor }

    var profit: Color { Color.green }
    var loss: Color { Color.red }
    var warning: Color { Color.orange }

    // Liquid Glass 主题的关键:背景尽量透明,让玻璃效果透出系统背景
    // iOS 26+: 使用 .glassEffect() 修饰符(由 EmptyStateView 等视图应用)
    // iOS 17-25: 用 .regularMaterial 模拟
    var pageBackground: Color {
        if #available(iOS 26.0, *) {
            return Color.clear
        } else {
            return Color(uiColor: .systemGroupedBackground)
        }
    }

    var cardBackground: Color {
        if #available(iOS 26.0, *) {
            return Color.clear
        } else {
            return Color(uiColor: .secondarySystemGroupedBackground)
        }
    }

    var primaryText: Color { Color.primary }
    var secondaryText: Color { Color.secondary }
}
