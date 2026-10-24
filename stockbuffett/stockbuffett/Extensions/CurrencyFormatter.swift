import Foundation

/// 货币格式化助手(¥ 符号)
///
/// 独立文件,所有 View 层可直接使用 `CurrencyFormatter.format(value)`。
enum CurrencyFormatter {
    static func format(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "¥"
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "¥0.00"
    }
}
