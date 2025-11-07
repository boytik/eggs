import Foundation

struct ConfigResponse: Codable {
    let ok: Bool
    let url: String?
    let expires: TimeInterval?
    let message: String?
}

final class ConfigClient {
    static let shared = ConfigClient()
    private init() {}

    private let endpoint = URL(string: "https://eggonomicsroad.com/config.php")!

    func fetchConfig(withMergedPayload payload: [String: Any]) async throws -> ConfigResponse {
        print("🌐 [Config] === SENDING CONFIG REQUEST ===")
        print("🌐 [Config] Endpoint: \(endpoint)")
        print("🌐 [Config] Method: POST")
        print("🌐 [Config] Content-Type: application/json")
        
        // Логируем ключевые параметры для регистрации
        print("🌐 [Config] Key registration parameters:")
        print("🌐 [Config]   af_id: '\(payload["af_id"] ?? "nil")'")
        print("🌐 [Config]   push_token: '\((payload["push_token"] as? String)?.prefix(20) ?? "nil")...'")
        print("🌐 [Config]   firebase_project_id: '\(payload["firebase_project_id"] ?? "nil")'")
        print("🌐 [Config]   af_status: '\(payload["af_status"] ?? "nil")'")
        print("🌐 [Config]   bundle_id: '\(payload["bundle_id"] ?? "nil")'")
        print("🌐 [Config]   store_id: '\(payload["store_id"] ?? "nil")'")
        
        print("🌐 [Config] Total payload keys: \(payload.keys.count)")
        print("🌐 [Config] All keys: \(Array(payload.keys).sorted())")
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // DO NOT change keys/order/types/nulls for AF data. We serialize as-is.
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = jsonData
        
        // Логируем размер payload
        print("🌐 [Config] Payload size: \(jsonData.count) bytes")
        
        print("🌐 [Config] Sending request...")
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        print("📥 [Config] === RESPONSE RECEIVED ===")
        print("📥 [Config] Status: \(http.statusCode)")
        print("📥 [Config] Headers: \(http.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 [Config] Raw response: \(responseString)")
        } else {
            print("📥 [Config] Response data size: \(data.count) bytes (not UTF-8)")
        }

        // Decode even on non-200 (server can return {ok:false})
        let decoded = try JSONDecoder().decode(ConfigResponse.self, from: data)
        print("📥 [Config] Decoded response: ok=\(decoded.ok), url=\(decoded.url ?? "nil"), message=\(decoded.message ?? "nil")")
        return decoded
    }
}
