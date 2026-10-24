import SwiftUI

/// 每日快照编辑器(新建 / 编辑)
struct SnapshotEditorView: View {
    enum Mode {
        case create
        case edit(snapshot: DailySnapshot)
    }

    let mode: Mode
    /// 保存回调(参数:已编辑的快照,Editor 已写盘)
    let onSaved: (DailySnapshot) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date()
    @State private var totalAssetsText: String = ""
    @State private var holdings: [Holding] = []
    @State private var notes: String = ""
    @State private var showingImageImport = false
    @State private var errorMessage: String?

    private var isCreate: Bool {
        if case .create = mode { return true } else { return false }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "快照日期",
                        selection: $date,
                        displayedComponents: .date
                    )
                    HStack {
                        Text("账户总资产")
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("可选", text: $totalAssetsText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 180)
                        Text("¥")
                            .foregroundStyle(.secondary)
                    }

                    // 实时显示"已用仓位 + 可用资金"(自动算,无需填)
                    if let total = Double(totalAssetsText
                        .replacingOccurrences(of: ",", with: "")
                        .trimmingCharacters(in: .whitespaces)),
                       total > 0 {
                        let marketValue = holdings.reduce(0) { $0 + $1.marketValue }
                        let cash = total - marketValue
                        let ratio = marketValue / total * 100
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("已用仓位")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.1f%%", ratio))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.orange)
                            }
                            HStack {
                                Text("可用资金")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(CurrencyFormatter.format(cash))
                                    .font(.caption.monospaced())
                            }
                        }
                    }
                } header: {
                    Text("日期 / 总资产")
                } footer: {
                    Text("填了总资产后才能在详情页看到每只股票的持仓占比。已用仓位和可用资金自动算。")
                }

                Section {
                    ForEach($holdings) { $holding in
                        HoldingRowEditor(
                            holding: $holding,
                            totalAssetsText: totalAssetsText
                        )
                    }
                    .onDelete(perform: deleteHoldings)

                    Button {
                        holdings.append(Holding())
                    } label: {
                        Label("添加持仓", systemImage: "plus.circle.fill")
                    }
                } header: {
                    HStack {
                        Text("持仓 (\(holdings.count))")
                        Spacer()
                        Button {
                            showingImageImport = true
                        } label: {
                            Label("截图导入", systemImage: "camera.viewfinder")
                                .font(.caption)
                        }
                    }
                } footer: {
                    Text("支持代码、名称、股数、成本价、当前价。代码 6 位数字。")
                }

                Section("备注") {
                    TextField("可选:今日市场观察、操作思路", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isCreate ? "新建快照" : "编辑快照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                }
            }
            .sheet(isPresented: $showingImageImport) {
                ImageImportSheet { imported in
                    holdings = imported
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
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        switch mode {
        case .create:
            date = Date()
            totalAssetsText = ""
            holdings = []
            notes = ""
        case .edit(let snapshot):
            date = snapshot.date
            totalAssetsText = snapshot.totalAssets.map { String($0) } ?? ""
            holdings = snapshot.holdings
            notes = snapshot.notes ?? ""
        }
    }

    private func deleteHoldings(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
    }

    private func save() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAssets = totalAssetsText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        let parsedAssets: Double? = trimmedAssets.isEmpty ? nil : Double(trimmedAssets)

        let snapshot: DailySnapshot
        switch mode {
        case .create:
            snapshot = DailySnapshot(
                date: date,
                totalAssets: parsedAssets,
                holdings: holdings,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
        case .edit(let original):
            snapshot = DailySnapshot(
                id: original.id,
                date: date,
                totalAssets: parsedAssets,
                holdings: holdings,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                createdAt: original.createdAt,
                updatedAt: Date()
            )
        }

        do {
            try FileStore.shared.writeSnapshot(snapshot)
            onSaved(snapshot)
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
}

/// 单只股票编辑行(行内编辑代码 / 名称 / 股数 / 成本 / 现价)
private struct HoldingRowEditor: View {
    @Binding var holding: Holding
    /// 编辑器顶部"总资产"输入的实时值(用于算占比);nil 表示未填
    let totalAssetsText: String

    /// 实时占比(总资产 - 单只市值 / 总资产)
    private var liveWeight: Double? {
        let total = Double(totalAssetsText
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)) ?? 0
        guard total > 0, holding.marketValue > 0 else { return nil }
        return holding.marketValue / total * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("代码", text: $holding.code)
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                TextField("名称", text: $holding.name)
                if let w = liveWeight {
                    Text(String(format: "%.1f%%", w))
                        .font(.caption.monospaced())
                        .foregroundStyle(.orange)
                        .frame(width: 50, alignment: .trailing)
                }
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
}
