import Foundation
import Security

/// API Key 存储服务 - 使用 iOS Keychain
///
/// 安全性:
/// - Keychain 由系统加密,沙盒内其他 App 无法访问
/// - 数据持久化在系统层,卸载 App 时自动清除
/// - iTunes/iCloud 备份默认不包含 Keychain 数据
///
/// 详见 SPEC.md §6.2 隐私与安全设计。
struct KeychainStore {
    static let shared = KeychainStore()

    private let service = "com.gjb.stockbuffett.apikey"
    private let account = "minimax-m3-api-key"

    private init() {}

    // MARK: - CRUD

    /// 读取 API Key
    /// - Returns: 存储的 Key;不存在时返回 nil
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        return key
    }

    /// 写入 API Key(覆盖已存在的)
    /// - Parameter key: MiniMax API Key
    func setAPIKey(_ key: String) {
        let data = Data(key.utf8)

        // 先删除已存在的项(确保唯一性)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // 写入新的项
        // kSecAttrAccessibleAfterFirstUnlock:首次解锁后即可访问,适合后台任务
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            print("[KeychainStore] setAPIKey failed with status: \(status)")
        }
    }

    /// 删除 API Key
    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - 查询

    /// 是否已配置 API Key
    var hasAPIKey: Bool {
        getAPIKey() != nil
    }
}
