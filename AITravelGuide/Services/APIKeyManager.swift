import Foundation
import Security

final class APIKeyManager {
    static let shared = APIKeyManager()
    private let service = "com.aitravelguide.apikeys"

    private init() {}

    // MARK: - Claude API Key

    var claudeAPIKey: String? {
        get { read(account: "claude-api-key") }
        set {
            if let value = newValue {
                save(account: "claude-api-key", value: value)
            } else {
                delete(account: "claude-api-key")
            }
        }
    }

    var hasAPIKey: Bool {
        claudeAPIKey != nil && !(claudeAPIKey?.isEmpty ?? true)
    }

    // MARK: - OpenAI API Key

    var openAIAPIKey: String? {
        get { read(account: "openai-api-key") }
        set {
            if let value = newValue {
                save(account: "openai-api-key", value: value)
            } else {
                delete(account: "openai-api-key")
            }
        }
    }

    var hasOpenAIKey: Bool {
        openAIAPIKey != nil && !(openAIAPIKey?.isEmpty ?? true)
    }

    // MARK: - Keychain Operations

    private func save(account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Delete existing item first
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(account: String) -> String? {
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
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
