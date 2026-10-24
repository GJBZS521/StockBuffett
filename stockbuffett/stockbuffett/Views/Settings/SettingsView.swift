import SwiftUI

/// 设置页面
///
/// 主要功能:
/// - 外观主题切换(4 个 Theme + 色板预览)
/// - API Key 配置(从 Keychain 读写)
/// - 数据导出(即将上线)
/// - 关于
struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager

    @State private var apiKeyInput: String = ""
    @State private var apiKeyConfigured: Bool = false
    @State private var showAPIKeySaved: Bool = false
    @State private var errorMessage: String?

    private let keychain = KeychainStore.shared

    var body: some View {
        Form {
            // 主题选择
            Section {
                ForEach(AppTheme.allCases) { theme in
                    ThemeRow(
                        theme: theme,
                        isSelected: theme == themeManager.currentTheme,
                        onSelect: { themeManager.setTheme(theme) }
                    )
                }
            } header: {
                Text("外观")
            } footer: {
                Text("实时切换,无需重启 App")
            }

            // API Key
            Section {
                LabeledContent("状态") {
                    Text(apiKeyConfigured ? "已配置" : "未配置")
                        .foregroundStyle(apiKeyConfigured ? .green : .orange)
                }
                SecureField(
                    apiKeyConfigured ? "已保存(输入新值覆盖)" : "输入 API Key",
                    text: $apiKeyInput
                )
                .textContentType(.password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.done)
                .onSubmit { saveAPIKey() }

                Button {
                    saveAPIKey()
                } label: {
                    Label("保存到 Keychain", systemImage: "lock.shield")
                }
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if apiKeyConfigured {
                    Button(role: .destructive) {
                        deleteAPIKey()
                    } label: {
                        Label("删除 API Key", systemImage: "trash")
                    }
                }
            } header: {
                Text("MiniMax API Key")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("用于操作建议模块的 LLM 调用。")
                    Text("Key 存在 iOS Keychain,不会上传任何地方。")
                    Text("API 提供方:MiniMax-M3(Anthropic 兼容协议)。")
                }
                .font(.caption2)
            }

            // 数据
            Section("数据") {
                Text("导出备份功能即将上线")
                    .foregroundStyle(.secondary)
            }

            // 关于
            Section("关于") {
                LabeledContent("版本", value: appVersion)
                LabeledContent("项目", value: "stockbuffett")
            }
        }
        .navigationTitle("设置")
        .alert("已保存", isPresented: $showAPIKeySaved) {
            Button("好") {}
        } message: {
            Text("API Key 已存到 Keychain")
        }
        .alert("提示", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear(perform: refreshKeyStatus)
    }

    private func refreshKeyStatus() {
        apiKeyConfigured = keychain.hasAPIKey
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        keychain.setAPIKey(trimmed)
        apiKeyInput = ""
        refreshKeyStatus()
        showAPIKeySaved = true
    }

    private func deleteAPIKey() {
        keychain.deleteAPIKey()
        refreshKeyStatus()
    }

    private var appVersion: String {
        let dict = Bundle.main.infoDictionary
        let version = dict?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = dict?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// 主题选择行(色板预览 + 名称 + 描述 + 选中态)
struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void

    private var themeColors: ThemeColors {
        theme.makeColors()
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 色板预览(2x3 圆点矩阵)
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle().fill(themeColors.brandPrimary).frame(width: 14, height: 14)
                        Circle().fill(themeColors.profit).frame(width: 14, height: 14)
                        Circle().fill(themeColors.loss).frame(width: 14, height: 14)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(themeColors.accentNotes).frame(width: 14, height: 14)
                        Circle().fill(themeColors.accentHoldings).frame(width: 14, height: 14)
                        Circle().fill(themeColors.accentChat).frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(theme.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(themeColors.brandPrimary)
                                .imageScale(.small)
                        }
                    }
                    Text(theme.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(ThemeManager.shared)
    }
}
