import SwiftUI

/// App 顶层 TabView
///
/// 接入 ThemeManager:
/// - 全局 tint 跟随当前主题
/// - 4 个 Tab 的 EmptyStateView 用各自 accentColor,主题切换时全站联动
/// - 设置 Tab 不需要 accentColor(有自己的主题选择 UI)
struct RootView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var chatPath = NavigationPath()

    var body: some View {
        let colors = themeManager.colors

        TabView {
            NavigationStack {
                TopicsListView(accentColor: colors.accentNotes)
            }
            .tabItem {
                Label("心得", systemImage: "book.closed")
            }

            NavigationStack {
                HoldingsListView(accentColor: colors.accentHoldings)
            }
            .tabItem {
                Label("持股", systemImage: "chart.pie")
            }

            NavigationStack(path: $chatPath) {
                ChatListView(
                    accentColor: colors.accentChat,
                    navigationPath: $chatPath
                )
            }
            .tabItem {
                Label("建议", systemImage: "bubble.left.and.bubble.right")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .tint(colors.tint)
    }
}

#Preview {
    RootView()
        .environmentObject(ThemeManager.shared)
}
