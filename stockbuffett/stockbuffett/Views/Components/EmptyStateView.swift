import SwiftUI

/// 空状态 / 占位视图
///
/// 用于功能尚未实现或数据为空时的友好提示。
/// 视觉构成:
/// - 渐变背景(accentColor 15% 透明 → 系统背景)
/// - 大图标 + 圆环背景(hierarchical 渲染)
/// - 卡片化标题 + 多行说明
///
/// accentColor 由 ThemeManager 提供,保证主题切换时整站联动。
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    let accentColor: Color

    init(
        systemImage: String,
        title: String,
        message: String,
        accentColor: Color
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.accentColor = accentColor
    }

    var body: some View {
        ZStack {
            // 渐变背景:accentColor 浅染色 → 系统分组背景
            LinearGradient(
                colors: [
                    accentColor.opacity(0.15),
                    Color(.systemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 大图标 + 圆环背景
                Image(systemName: systemImage)
                    .font(.system(size: 56, weight: .light))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(accentColor)
                    .frame(width: 120, height: 120)
                    .background {
                        Circle()
                            .fill(accentColor.opacity(0.12))
                            .overlay {
                                Circle()
                                    .stroke(accentColor.opacity(0.25), lineWidth: 1)
                            }
                    }

                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text(message)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
    }
}

#Preview {
    EmptyStateView(
        systemImage: "book.closed",
        title: "示例标题",
        message: "这是一段说明文字,用于描述当前模块的功能。",
        accentColor: .blue
    )
}
