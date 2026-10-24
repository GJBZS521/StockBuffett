import Foundation

/// Prompt 拼装器:把 Notes + Holdings 注入 system prompt
struct PromptBuilder {
    /// 拼装 system prompt(每次发送消息前调用,自动取最新上下文)
    static func buildSystemPrompt() -> String {
        let notesContext = collectNotes()
        let holdingsContext = collectHoldings()

        return """
        你是巴菲特式的长期价值投资顾问。用户记录了一些交易心得和当前持仓,基于这些给建议。

        ## 用户的交易心得

        \(notesContext)

        ## 用户当前持仓(最新一天)

        \(holdingsContext)

        ---

        请基于以上上下文回答用户问题。回答要:
        - 引用用户的心得(原话或摘要),让建议有依据
        - 引用用户的具体持仓(代码、名称、占比、盈亏),让建议落地
        - 如果用户问的操作跟自己的心得冲突,温和指出
        - 不要编造用户没记录的数据(代码、价格、盈亏)
        - 简短务实,避免长篇大论,500 字以内为主
        - 用 Markdown 格式,允许标题/列表/粗体
        """
    }

    private static func collectNotes() -> String {
        let topics = FileStore.shared.listTopics()
        if topics.isEmpty {
            return "(暂无心得记录)"
        }
        var result = ""
        for topic in topics {
            let notes = FileStore.shared.listNotes(in: topic)
            result += "### 主题: \(topic)(\(notes.count) 篇)\n\n"
            for note in notes {
                let raw = (try? FileStore.shared.readNote(note))?.content ?? note.content
                // 截断超长内容(单篇 > 800 字)
                let preview = raw.count > 800 ? String(raw.prefix(800)) + "..." : raw
                result += "**\(note.title)**\n\n\(preview)\n\n---\n\n"
            }
        }
        return result
    }

    private static func collectHoldings() -> String {
        let snapshots = FileStore.shared.listSnapshots()
        guard let latest = snapshots.first else {
            return "(暂无持仓记录)"
        }
        var result = "快照日期: \(formatDate(latest.date))\n"
        if let total = latest.totalAssets {
            result += "账户总资产: ¥\(formatNumber(total))\n"
            if let cash = latest.availableCash {
                result += "可用资金: ¥\(formatNumber(cash))(= 总资产 - 持仓总市值)\n"
            }
            if let ratio = latest.positionRatio {
                result += "已用仓位: \(String(format: "%.1f", ratio))%\n"
            }
        }
        result += "持仓数: \(latest.holdings.count) 只\n\n"

        if latest.holdings.isEmpty {
            result += "(无持仓明细)\n"
        } else {
            for holding in latest.holdings {
                let codeStr = holding.code.isEmpty ? "—" : holding.code
                let price = holding.currentPrice ?? holding.costPrice
                let weight = holding.weightPercent(snapshotTotalAssets: latest.totalAssets)
                let weightStr = weight > 0 ? String(format: "%.1f%%", weight) : "—"
                let profit = holding.profit
                let profitPercent = holding.profitPercent
                result += "- **\(holding.name)**(\(codeStr)):\n"
                result += "  - 股数: \(Int(holding.shares)), 成本: ¥\(formatNumber(holding.costPrice)), 现价: ¥\(formatNumber(price))\n"
                result += "  - 市值: ¥\(formatNumber(holding.marketValue)), 持仓占比: \(weightStr)\n"
                if holding.shares > 0 {
                    let sign = profit >= 0 ? "+" : ""
                    result += "  - 浮动盈亏: \(sign)¥\(formatNumber(profit))(\(String(format: "%+.2f", profitPercent))%)\n"
                }
            }
        }
        if let notes = latest.notes, !notes.isEmpty {
            result += "\n当日备注:\n\(notes)\n"
        }
        return result
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private static func formatNumber(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
