import SwiftUI
import UIKit

/// 主题 C · 柔和多彩
///
/// 风格:年轻活力(Robinhood/Acorns 风)
/// 主色:靛紫
/// 适合:90/00 后、轻量化、不喜欢沉闷的用户
struct VibrantMultiTheme: ThemeColors {
    var tint: Color { Color(red: 0.37, green: 0.36, blue: 0.90) } // 靛紫 #5E5CE6

    var accentNotes: Color { Color(red: 0.37, green: 0.36, blue: 0.90) }    // 靛紫
    var accentHoldings: Color { Color(red: 0.20, green: 0.83, blue: 0.60) } // 薄荷绿
    var accentChat: Color { Color(red: 0.98, green: 0.57, blue: 0.24) }     // 粉橙
    var accentSettings: Color { Color(red: 0.55, green: 0.36, blue: 0.96) } // 紫蓝

    var brandPrimary: Color { Color(red: 0.37, green: 0.36, blue: 0.90) }

    var profit: Color { Color(red: 0.20, green: 0.83, blue: 0.60) } // 薄荷绿
    var loss: Color { Color(red: 0.98, green: 0.44, blue: 0.52) }   // 桃粉
    var warning: Color { Color(red: 0.98, green: 0.75, blue: 0.14) } // 琥珀

    var pageBackground: Color { Color(uiColor: .systemGroupedBackground) }
    var cardBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }

    var primaryText: Color { Color.primary }
    var secondaryText: Color { Color.secondary }
}
