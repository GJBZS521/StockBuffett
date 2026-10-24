import SwiftUI
import UIKit

/// 主题 B · 极简黑白+暖金 ⭐ 默认
///
/// 风格:向价值投资致敬(项目名 stockbuffett)
/// 主色:暖金(像金币、老钱、低调奢华)
/// 适合:喜欢极简、有质感的用户;深色模式表现尤佳
struct MinimalistGoldTheme: ThemeColors {
    var tint: Color { Color(red: 0.79, green: 0.66, blue: 0.38) } // 暖金 #C9A961

    var accentNotes: Color { Color(red: 0.11, green: 0.11, blue: 0.12) }    // 深空灰
    var accentHoldings: Color { Color(red: 0.79, green: 0.66, blue: 0.38) } // 暖金
    var accentChat: Color { Color(red: 0.02, green: 0.47, blue: 0.34) }     // 墨绿
    var accentSettings: Color { Color(red: 0.42, green: 0.45, blue: 0.50) } // 中灰

    var brandPrimary: Color { Color(red: 0.79, green: 0.66, blue: 0.38) }

    var profit: Color { Color(red: 0.02, green: 0.47, blue: 0.34) } // 墨绿
    var loss: Color { Color(red: 0.73, green: 0.11, blue: 0.11) }   // 砖红
    var warning: Color { Color(red: 0.96, green: 0.62, blue: 0.04) } // 琥珀

    var pageBackground: Color { Color(uiColor: .systemBackground) }
    var cardBackground: Color { Color(red: 0.96, green: 0.96, blue: 0.97) } // #F5F5F7

    var primaryText: Color { Color.primary }
    var secondaryText: Color { Color.secondary }
}
