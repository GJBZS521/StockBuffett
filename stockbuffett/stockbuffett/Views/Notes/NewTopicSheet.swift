import SwiftUI

/// 新建主题弹窗
///
/// M2:
/// - 输入主题名(自动 .asFolderName 安全处理)
/// - 创建 / 取消
struct NewTopicSheet: View {
    /// 创建成功回调(参数:已清洗的安全主题名)
    let onCreated: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var errorMessage: String?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && trimmedName.asFolderName != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("例如:交易纪律、复盘心得", text: $name)
                        .submitLabel(.done)
                        .onSubmit {
                            if canSave { save() }
                        }
                } header: {
                    Text("主题名")
                } footer: {
                    Text("两层目录结构的第一层。可随时修改或删除。")
                }
            }
            .navigationTitle("新建主题")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("提示", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save() {
        guard let safeName = trimmedName.asFolderName else {
            errorMessage = "主题名包含非法字符(/\\?*<>\"|:)或为空"
            return
        }
        onCreated(safeName)
        dismiss()
    }
}

#Preview {
    NewTopicSheet { _ in }
}
