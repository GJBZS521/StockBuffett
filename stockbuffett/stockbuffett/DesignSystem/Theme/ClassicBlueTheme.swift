import SwiftUI
import UIKit

/// 主题 A · 经典金融蓝
///
/// 风格:传统券商风(富途/老虎/雪球)
/// 主色:深蓝
/// 适合:喜欢专业金融感、券商 App 风格的用户
struct ClassicBlueTheme: ThemeColors {
    var tint: Color { Color(red: 0.12, green: 0.25, blue: 0.69) } // #1E40AF

    var accentNotes: Color { Color(red: 0.12, green: 0.25, blue: 0.69) }    // 深蓝
    var accentHoldings: Color { Color(red: 0.06, green: 0.73, blue: 0.51) } // 翠绿
    var accentChat: Color { Color(red: 0.39, green: 0.40, blue: 0.95) }     // 靛紫
    var accentSettings: Color { Color(red: 0.42, green: 0.45, blue: 0.50) }  // 中灰

    var brandPrimary: Color { Color(red: 0.12, green: 0.25, blue: 0.69) }

    var profit: Color { Color(red: 0.06, green: 0.73, blue: 0.51) } // 翠绿
    var loss: Color { Color(red: 0.94, green: 0.27, blue: 0.27) }   // 警示红
    var warning: Color { Color(red: 0.96, green: 0.62, blue: 0.04) } // 琥珀

    var pageBackground: Color { Color(uiColor: .systemGroupedBackground) }
    var cardBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }

    var primaryText: Color { Color.primary }
    var secondaryText: Color { Color.secondary }
}
