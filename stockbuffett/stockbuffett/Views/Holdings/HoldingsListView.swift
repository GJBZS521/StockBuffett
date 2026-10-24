import SwiftUI

/// 当前持股 - 每日快照列表(首页)
///
/// M3 真实实现:
/// - 从 FileStore 读取所有快照(按日期倒序)
/// - 顶部:最新一天的摘要卡片(总市值 / 盈亏 / 持仓数)
/// - 历史:日期列表(日期 / 持仓数 / 当日市值)
/// - 右上 + → 新建当日快照(支持截图导入)
/// - 滑动删除
struct HoldingsListView: View {
    let accentColor: Color

    @State private var snapshots: [DailySnapshot] = []
    @State private var showingNewSnapshot = false
    @State private var errorMessage: String?

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private var latest: DailySnapshot? { snapshots.first }

    var body: some View {
        Group {
            if snapshots.isEmpty {
                EmptyStateView(
                    systemImage: "chart.pie",
                    title: "暂无持股记录",
                    message: "点击右上角 + 添加第一天的持仓\n支持手动录入或券商截图识别",
                    accentColor: accentColor
                )
            } else {
                List {
                    if let latest = latest {
                        Section("最新") {
                            SnapshotSummaryCard(
                                snapshot: latest,
                                shortDateFormatter: Self.shortDateFormatter
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }

                    Section("历史快照 (\(snapshots.count))") {
                        ForEach(snapshots) { snapshot in
                            NavigationLink(value: snapshot) {
                                SnapshotRow(
                                    snapshot: snapshot,
                                    shortDateFormatter: Self.shortDateFormatter
                                )
                            }
                        }
                        .onDelete(perform: deleteSnapshots)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("当前持股")
        .navigationDestination(for: DailySnapshot.self) { snapshot in
            SnapshotDetailView(
                snapshot: snapshot,
                accentColor: accentColor,
                onUpdated: { loadSnapshots() }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if !snapshots.isEmpty { EditButton() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewSnapshot = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewSnapshot) {
            SnapshotEditorView(mode: .create) { _ in
                loadSnapshots()
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
        .onAppear(perform: loadSnapshots)
    }

    private func loadSnapshots() {
        snapshots = FileStore.shared.listSnapshots()
    }

    private func deleteSnapshots(at offsets: IndexSet) {
        for i in offsets {
            do {
                try FileStore.shared.deleteSnapshot(snapshots[i])
            } catch {
                errorMessage = "删除失败: \(error.localizedDescription)"
                break
            }
        }
        loadSnapshots()
    }
}

/// 最新摘要卡片
private struct SnapshotSummaryCard: View {
    let snapshot: DailySnapshot
    let shortDateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(shortDateFormatter.string(from: snapshot.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.holdings.count) 只股票")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(profitText)
                        .font(.headline)
                        .foregroundStyle(snapshot.totalProfit >= 0 ? .green : .red)
                    Text(profitPercentText)
                        .font(.caption)
                        .foregroundStyle(snapshot.totalProfit >= 0 ? .green : .red)
                }
            }
            Divider()
            if let total = snapshot.totalAssets {
                HStack {
                    Text("账户总资产")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(total))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                HStack {
                    Text("可用资金")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.format(snapshot.availableCash ?? 0))
                        .font(.subheadline)
                }
            }
            HStack {
                Text("总市值")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CurrencyFormatter.format(snapshot.totalMarketValue))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            HStack {
                Text("总成本")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(CurrencyFormatter.format(snapshot.totalCost))
                    .font(.subheadline)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    private var profitText: String {
        let sign = snapshot.totalProfit >= 0 ? "+" : ""
        return "\(sign)\(CurrencyFormatter.format(snapshot.totalProfit))"
    }

    private var profitPercentText: String {
        let sign = snapshot.totalProfitPercent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, snapshot.totalProfitPercent)
    }
}

/// 历史快照行
private struct SnapshotRow: View {
    let snapshot: DailySnapshot
    let shortDateFormatter: DateFormatter

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortDateFormatter.string(from: snapshot.date))
                    .font(.body)
                    .fontWeight(.medium)
                Text("\(snapshot.holdings.count) 只股票")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(snapshot.totalMarketValue))
                    .font(.subheadline)
                Text(profitText)
                    .font(.caption)
                    .foregroundStyle(snapshot.totalProfit >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 2)
    }

    private var profitText: String {
        let sign = snapshot.totalProfit >= 0 ? "+" : ""
        return "\(sign)\(CurrencyFormatter.format(snapshot.totalProfit))"
    }
}
