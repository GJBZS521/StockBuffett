import Foundation

/// 单只股票持仓记录
///
/// 简化模型:股票代码 + 名称 + 股数 + 成本价 + 当前价(可选)
/// 用于每日快照的明细行。
struct Holding: Codable, Identifiable, Hashable {
    let id: UUID
    var code: String        // 股票代码(6 位数字)
    var name: String        // 股票名称
    var shares: Double      // 持有股数
    var costPrice: Double   // 成本价(元/股)
    var currentPrice: Double?  // 当前价(可选,未填则用成本价算市值)
    /// OCR 临时字段:Vision 识别到的市值(用户没填股数/成本前用于显示)
    /// 用户填了 `shares > 0` 后自动改用 `marketValue` 计算
    var marketValueOnly: Double?

    init(
        id: UUID = UUID(),
        code: String = "",
        name: String = "",
        shares: Double = 0,
        costPrice: Double = 0,
        currentPrice: Double? = nil,
        marketValueOnly: Double? = nil
    ) {
        self.id = id
        self.code = code
        self.name = name
        self.shares = shares
        self.costPrice = costPrice
        self.currentPrice = currentPrice
        self.marketValueOnly = marketValueOnly
    }

    /// 持仓市值
    /// - 用户填了 `shares > 0` → 用 (currentPrice ?? costPrice) * shares
    /// - 否则(纯 OCR 名称)→ 用 `marketValueOnly`
    /// - 都没 → 0
    var marketValue: Double {
        if shares > 0 {
            return (currentPrice ?? costPrice) * shares
        }
        return marketValueOnly ?? 0
    }

    /// 持仓成本(仅在有 shares 时有意义)
    var costValue: Double {
        costPrice * shares
    }

    /// 浮动盈亏
    var profit: Double {
        marketValue - costValue
    }

    /// 盈亏比例 (%)
    var profitPercent: Double {
        guard costValue > 0 else { return 0 }
        return profit / costValue * 100
    }

    /// 占总资产比例(%) — `snapshotTotalAssets` 为 nil 时返回 0
    func weightPercent(snapshotTotalAssets: Double?) -> Double {
        guard let total = snapshotTotalAssets, total > 0 else { return 0 }
        guard marketValue > 0 else { return 0 }
        return marketValue / total * 100
    }
}
