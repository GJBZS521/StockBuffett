import Foundation

/// 单日持仓快照
///
/// 每天一份,记录当天所有持仓 + 备注 + 总览。
/// 存储位置: `~/Documents/buffett/holdings/YYYY-MM-DD.json`
struct DailySnapshot: Codable, Identifiable, Hashable {
    let id: UUID
    var date: Date              // 持仓日期(对齐到当天 0 点)
    var totalAssets: Double?    // 账户总资产(可选,用于算持仓占比)
    var holdings: [Holding]     // 当日所有持仓
    var notes: String?          // 当日备注
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        totalAssets: Double? = nil,
        holdings: [Holding] = [],
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.totalAssets = totalAssets
        self.holdings = holdings
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 当日总市值
    var totalMarketValue: Double {
        holdings.reduce(0) { $0 + $1.marketValue }
    }

    /// 当日总成本
    var totalCost: Double {
        holdings.reduce(0) { $0 + $1.costValue }
    }

    /// 当日浮动盈亏
    var totalProfit: Double {
        totalMarketValue - totalCost
    }

    /// 当日盈亏比例 (%)
    var totalProfitPercent: Double {
        guard totalCost > 0 else { return 0 }
        return totalProfit / totalCost * 100
    }

    /// 可用资金 = 总资产 - 持仓总市值
    /// 总资产未填时返回 nil
    var availableCash: Double? {
        guard let total = totalAssets else { return nil }
        return total - totalMarketValue
    }

    /// 持仓总占比(%)— 反映"已用仓位"
    /// 总资产未填时返回 nil
    var positionRatio: Double? {
        guard let total = totalAssets, total > 0 else { return nil }
        return totalMarketValue / total * 100
    }
}
