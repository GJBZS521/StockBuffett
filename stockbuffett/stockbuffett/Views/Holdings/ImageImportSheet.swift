import SwiftUI
import PhotosUI
import UIKit

/// 截图导入(从相册选券商截图 → Vision OCR 解析 → 填入编辑器)
struct ImageImportSheet: View {
    /// 应用回调(参数:解析出的 holdings 列表)
    let onApply: ([Holding]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var parsedHoldings: [Holding] = []
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("选择券商截图", systemImage: "photo.on.rectangle")
                    }
                    .onChange(of: selectedItem) { _, newValue in
                        handleSelection(newValue)
                    }
                } header: {
                    Text("1. 选择图片")
                } footer: {
                    Text("支持中文/数字文本识别。识别结果需要你确认后再应用。")
                }

                if let image = selectedImage {
                    Section("预览") {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .frame(maxWidth: .infinity)
                    }
                }

                if isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                            Text("识别中...")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if !parsedHoldings.isEmpty {
                    Section {
                        ForEach($parsedHoldings) { $holding in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    TextField("名称", text: $holding.name)
                                        .font(.body)
                                    TextField("代码", text: $holding.code)
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                        .font(.caption.monospaced())
                                }
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("股数")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        TextField("0", value: $holding.shares, format: .number)
                                            .keyboardType(.decimalPad)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("成本")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        TextField("0.00", value: $holding.costPrice, format: .number)
                                            .keyboardType(.decimalPad)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("现价")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                        TextField("可选", value: Binding(
                                            get: { holding.currentPrice ?? 0 },
                                            set: { holding.currentPrice = $0 > 0 ? $0 : nil }
                                        ), format: .number)
                                        .keyboardType(.decimalPad)
                                    }
                                }
                                .font(.caption.monospaced())
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            parsedHoldings.remove(atOffsets: indexSet)
                        }
                    } header: {
                        Text("2. 识别结果 (\(parsedHoldings.count) 只,可编辑)")
                    } footer: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OCR 启发式解析可能不准确。点击字段直接修改,左滑可删除。")
                            Text("• 代码空 → 手动补;港股 5 位(03690)、A 股 6 位(600519)")
                            Text("• 现价可留空;成本/股数通常 ≥ 100")
                        }
                        .font(.caption2)
                    }

                    if !recognizedText.isEmpty {
                        Section {
                            DisclosureGroup("查看原始识别文本") {
                                Text(recognizedText)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let err = errorMessage {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                // 永远显示 Vision 原始识别文本(诊断用)
                if !recognizedText.isEmpty {
                    Section {
                        DisclosureGroup("Vision 原始识别文本(\(recognizedText.count) 字符)") {
                            Text(recognizedText)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    } header: {
                        Text("调试:Vision 看到了什么")
                    }
                }
            }
            .navigationTitle("截图导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用") {
                        onApply(parsedHoldings)
                        dismiss()
                    }
                    .disabled(parsedHoldings.isEmpty)
                }
            }
        }
    }

    private func handleSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        isProcessing = true
        errorMessage = nil
        recognizedText = ""
        parsedHoldings = []
        selectedImage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw OCRError.invalidImage
                }
                selectedImage = image
                let text = try await OCRService.recognizeText(in: image)
                recognizedText = text
                parsedHoldings = OCRService.parseHoldings(text)
                if parsedHoldings.isEmpty {
                    errorMessage = "未能从图片中识别出有效持仓。可手动填写或换张图试试。"
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}
