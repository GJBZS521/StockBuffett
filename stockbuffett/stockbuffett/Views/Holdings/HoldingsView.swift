import SwiftUI

/// 当前持股 - 主页面
///
/// M1 占位:展示功能预告。
/// 后续 Milestone 实现按天记录 + 截图导入。
/// accentColor 由 RootView 从 ThemeManager 传入。
struct HoldingsView: View {
    let accentColor: Color

    var body: some View {
        EmptyStateView(
            systemImage: "chart.pie",
            title: "当前持股",
            message: "按天记录持仓\n支持截图导入和手动输入\n即将上线",
            accentColor: accentColor
        )
        .navigationTitle("持股")
    }
}

#Preview {
    NavigationStack {
        HoldingsView(accentColor: .green)
    }
}
