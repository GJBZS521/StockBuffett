import SwiftUI

/// 单日快照详情页(查看模式)
struct SnapshotDetailView: View {
    let snapshot: DailySnapshot
    let accentColor: Color
    let onUpdated: () -> Void

    @State private var loadedSnapshot: DailySnapshot?
    @State private var showingEditor = false
    @State private var errorMessage: String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日 EEEE"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    var body: some View {
        List {
            if let s = loadedSnapshot {
                Section("总览") {
                    VStack(alignment: .leading, spacing: 10) {
                        if let total = s.totalAssets {
                            summaryRow("账户总资产", value: total)
                            Divider()
                            if let cash = s.availableCash {
                                summaryRow("可用资金", value: cash)
                                Divider()
                            }
                            if let ratio = s.positionRatio {
                                HStack {
                                    Text("已用仓位")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f%%", ratio))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.orange)
                                }
                                Divider()
                            }
                        }
                        summaryRow("总市值", value: s.totalMarketValue)
                        Divider()
                        summaryRow("总成本", value: s.totalCost)
                        Divider()
                        HStack {
                            Text("浮动盈亏")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(profitText(s.totalProfit))
                                    .font(.headline)
                                    .foregroundStyle(s.totalProfit >= 0 ? .green : .red)
                                Text(profitPercentText(s.totalProfitPercent))
                                    .font(.caption)
                                    .foregroundStyle(s.totalProfit >= 0 ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("持仓 (\(s.holdings.count))") {
                    if s.holdings.isEmpty {
                        Text("无持仓记录")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(s.holdings) { holding in
                            HoldingDetailRow(
                                holding: holding,
                                weightPercent: holding.weightPercent(snapshotTotalAssets: s.totalAssets)
                            )
                        }
                    }
                }

                if let notes = s.notes, !notes.isEmpty {
                    Section("备注") {
                        Text(notes)
                            .font(.body)
                    }
                }
            } else if let err = errorMessage {
                Section {
                    Text("加载失败: \(err)")
                        .foregroundStyle(.red)
                }
            } else {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(Self.dateFormatter.string(from: snapshot.date))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "pencil")
                }
                .disabled(loadedSnapshot == nil)
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let s = loadedSnapshot {
                SnapshotEditorView(mode: .edit(snapshot: s)) { updated in
                    do {
                        try FileStore.shared.writeSnapshot(updated)
                        loadedSnapshot = updated
                        onUpdated()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
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
        .onAppear {
            loadedSnapshot = snapshot
        }
    }

    private func summaryRow(_ label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatter.format(value))
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func profitText(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(CurrencyFormatter.format(value))"
    }

    private func profitPercentText(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, value)
    }
}

/// 持仓详情行(详情页用)
private struct HoldingDetailRow: View {
    let holding: Holding
    let weightPercent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.name)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(holding.code.isEmpty ? "—" : holding.code)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyFormatter.format(holding.marketValue))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(profitText)
                        .font(.caption)
                        .foregroundStyle(holding.profit >= 0 ? .green : .red)
                }
            }
            HStack(spacing: 12) {
                detailItem("股数", "\(Int(holding.shares))")
                detailItem("成本", String(format: "¥%.2f", holding.costPrice))
                if let current = holding.currentPrice {
                    detailItem("现价", String(format: "¥%.2f", current))
                }
                if weightPercent > 0 {
                    detailItem("占比", String(format: "%.1f%%", weightPercent))
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var profitText: String {
        let sign = holding.profit >= 0 ? "+" : ""
        return "\(sign)\(CurrencyFormatter.format(holding.profit))"
    }

    private func detailItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption.monospaced())
        }
    }
}
