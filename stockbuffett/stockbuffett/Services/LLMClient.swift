import Foundation

/// MiniMax-M3 LLM 客户端
///
/// 走 Anthropic Messages API 兼容协议:
/// `POST https://api.minimax.io/anthropic/v1/messages`
///
/// 头:
/// - `x-api-key: {key}`
/// - `anthropic-version: 2023-06-01`
/// - `content-type: application/json`
struct LLMClient {
    let apiKey: String
    let model: String
    let baseURL: URL

    init(
        apiKey: String,
        model: String = "MiniMax-M3",
        baseURL: URL = URL(string: "https://api.minimax.io/anthropic")!
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    enum LLMError: LocalizedError {
        case noApiKey
        case invalidResponse
        case httpStatus(Int, String)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noApiKey: return "请先在设置中填写 API Key"
            case .invalidResponse: return "无效的服务器响应"
            case .httpStatus(let code, let body): return "HTTP \(code): \(body.prefix(200))"
            case .apiError(let msg): return msg
            }
        }
    }

    /// 发送消息(非流式)
    /// - Parameters:
    ///   - system: 系统提示(拼装好的,含 notes + holdings 上下文)
    ///   - messages: 对话历史(建议只传最近几轮,过长会超 token 限制)
    ///   - maxTokens: 最大回复 token 数
    /// - Returns: 助手回复文本
    func sendMessage(system: String, messages: [ChatMessage], maxTokens: Int = 4096) async throws -> String {
        guard !apiKey.isEmpty else { throw LLMError.noApiKey }

        // 转换消息格式(Anthropic 格式: [{role, content}])
        let apiMessages: [[String: Any]] = messages
            .filter { $0.role != .system }
            .map { msg in
                ["role": msg.role.rawValue, "content": msg.content]
            }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": apiMessages
        ]

        let url = baseURL.appendingPathComponent("v1/messages")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            throw LLMError.httpStatus(http.statusCode, body)
        }

        // 解析响应: {content: [{type: "text", text: "..."}], stop_reason: ...}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.invalidResponse
        }
        if let error = json["error"] as? [String: Any],
           let msg = error["message"] as? String {
            throw LLMError.apiError(msg)
        }
        guard let content = json["content"] as? [[String: Any]] else {
            throw LLMError.invalidResponse
        }
        let text = content.compactMap { $0["text"] as? String }.joined()
        if text.isEmpty {
            throw LLMError.invalidResponse
        }
        return text
    }
}
