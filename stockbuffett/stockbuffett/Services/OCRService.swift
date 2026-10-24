import Foundation
import UIKit
import Vision

/// 截图 OCR + 解析服务
///
/// M3 简化策略:
/// 1. Vision 识别中文/英文文本
/// 2. 启发式正则解析:匹配 6 位股票代码 + 周围的中文名 + 数字(股数/成本/价格)
/// 3. 解析结果给用户二次确认(不保证 100% 准确)
struct OCRService {
    /// 识别图片中的文字(多行,按识别顺序拼接)
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            // 关掉语言模型纠正 — 同花顺截图里"市值"会被瞎改成"闯",字形完全不像
            request.usesLanguageCorrection = false
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// 启发式解析 OCR 文本 → holdings 列表
    ///
    /// **M3 现实策略**(基于真实同花顺截图测试):
    /// - Vision 实际能拿到的只有 **名称 + 市值**;盈亏/股数/成本/现价/代码经常丢失
    /// - 行清理:去掉前导误识单字(沪/深/港/闯/市/值/今/昨/涨/跌)
    /// - 看到有效名称 → 下一行第一个数字 → 作为市值(放 `marketValueOnly`)
    /// - 其他字段留空,用户在编辑器里手动填
    static func parseHoldings(_ text: String) -> [Holding] {
        // 1. 拆行 + 去空
        let rawLines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // 2. 行清理:去掉前导误识单字
        let leadingPrefixes = ["沪", "深", "港", "闯", "市", "值", "今", "昨", "涨", "跌", "1", "2"]
        let cleanedLines: [String] = rawLines.map { line in
            var s = line
            for p in leadingPrefixes {
                if s.hasPrefix(p) {
                    s = String(s.dropFirst()).trimmingCharacters(in: .whitespaces)
                    break // 只去一次
                }
            }
            return s
        }

        // 3. 关键词黑名单
        let nonStockKeywords: Set<String> = [
            "总资产", "总市值", "总盈亏", "当日参考盈亏", "当日参考",
            "可用", "可取", "可用资金", "持仓管理", "批量买入", "批量卖出",
            "止盈止损", "持仓资讯", "资产分析", "持仓股", "查看已清仓",
            "买入", "卖出", "撤单", "查询", "仓位",
            "首页", "行情", "自选", "交易", "资讯", "理财",
            "成本", "现价", "股数", "市值", "盈亏", "持仓", "可用", "逆回购", "转账",
            "中国银河证券", "华泰证券", "中信证券", "招商证券", "国泰君安",
            "海通证券", "广发证券", "国信证券", "安信证券", "申万宏源",
            "查看已清仓股票", "同花顺", "App", "App", "4G", "《", "闯", "1"
        ]

        // 4. 正则
        let chinesePattern = #"[一-龥][一-龥\-A-Za-z0-9 ]*"#
        let numberPattern = #"[+-]?[0-9]{1,3}(?:,[0-9]{3})+(?:\.[0-9]+)?|[+-]?[0-9]+(?:\.[0-9]+)?"#

        guard let chineseRegex = try? NSRegularExpression(pattern: chinesePattern),
              let numberRegex = try? NSRegularExpression(pattern: numberPattern) else {
            return []
        }

        // 5. 简化:看到有效名称 → 下一行的第一个数字 = 市值
        var holdings: [Holding] = []
        var i = 0
        while i < cleanedLines.count {
            let line = cleanedLines[i]
            let lineRange = NSRange(line.startIndex..., in: line)

            // 找首个中文串
            guard let nameMatch = chineseRegex.firstMatch(in: line, range: lineRange),
                  let nameRange = Range(nameMatch.range, in: line) else {
                i += 1
                continue
            }
            // 提取并清理名称(去多余空格,如"美团 -W" → "美团-W")
            let rawName = String(line[nameRange])
            let name = rawName
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespaces)

            guard name.count >= 2, name.count <= 8, !nonStockKeywords.contains(name) else {
                i += 1
                continue
            }

            // 找下一行的第一个数字 = 市值
            var marketValue: Double = 0
            if i + 1 < cleanedLines.count {
                let nextLine = cleanedLines[i + 1]
                let nextRange = NSRange(nextLine.startIndex..., in: nextLine)
                if let numMatch = numberRegex.firstMatch(in: nextLine, range: nextRange),
                   let r = Range(numMatch.range, in: nextLine) {
                    marketValue = Double(nextLine[r].replacingOccurrences(of: ",", with: "")) ?? 0
                }
            }

            holdings.append(Holding(
                code: "",
                name: name,
                shares: 0,
                costPrice: 0,
                currentPrice: nil,
                marketValueOnly: marketValue > 0 ? marketValue : nil
            ))

            i += 1  // 跳到下一行(下一行可能含数字,会被 chineseRegex 跳过)
        }
        return holdings
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "图片无法识别"
        case .recognitionFailed(let msg): return "识别失败:\(msg)"
        }
    }
}
