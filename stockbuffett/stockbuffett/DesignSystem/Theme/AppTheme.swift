import Foundation

/// App 主题枚举
///
/// 4 个内置主题:
/// - A: 经典金融蓝
/// - B: 极简黑白+暖金(默认)
/// - C: 柔和多彩
/// - D: Liquid Glass(iOS 26+ 增强)
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case classicBlue = "A"
    case minimalistGold = "B"
    case vibrantMulti = "C"
    case liquidGlass = "D"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classicBlue: return "经典蓝"
        case .minimalistGold: return "暖金"
        case .vibrantMulti: return "柔彩"
        case .liquidGlass: return "玻璃"
        }
    }

    var description: String {
        switch self {
        case .classicBlue: return "传统券商风,稳重专业"
        case .minimalistGold: return "极简黑白,价值投资致敬"
        case .vibrantMulti: return "多彩明亮,年轻活力"
        case .liquidGlass: return "iOS 26 原生 Liquid Glass"
        }
    }

    /// 创建该主题的色板实例
    func makeColors() -> ThemeColors {
        switch self {
        case .classicBlue: return ClassicBlueTheme()
        case .minimalistGold: return MinimalistGoldTheme()
        case .vibrantMulti: return VibrantMultiTheme()
        case .liquidGlass: return LiquidGlassTheme()
        }
    }
}
