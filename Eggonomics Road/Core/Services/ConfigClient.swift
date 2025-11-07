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
        
        LogCollector.shared.logConfig("Sending config request to \(endpoint)")
        
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
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        request.httpBody = jsonData
        
        // === МАКСИМАЛЬНО ПОДРОБНОЕ ЛОГИРОВАНИЕ PAYLOAD ===
        print("🌐 [Config] === FULL JSON PAYLOAD START ===")
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
            LogCollector.shared.logConfig("FULL JSON PAYLOAD: \(jsonString)")
        } else {
            print("❌ [Config] Failed to convert JSON data to string")
            LogCollector.shared.logError("Failed to convert JSON payload to string")
        }
        print("🌐 [Config] === FULL JSON PAYLOAD END ===")
        
        // Детальная проверка критических полей
        print("🌐 [Config] === CRITICAL FIELDS VALIDATION ===")
        let criticalFields = ["af_id", "push_token", "firebase_project_id", "bundle_id", "af_status"]
        for field in criticalFields {
            if let value = payload[field] {
                print("🌐 [Config] ✅ \(field): '\(value)' (type: \(type(of: value)))")
                LogCollector.shared.logConfig("Field \(field): '\(value)' (type: \(type(of: value)))")
            } else {
                print("🌐 [Config] ❌ \(field): MISSING")
                LogCollector.shared.logError("Critical field \(field) is MISSING from payload")
            }
        }
        print("🌐 [Config] === END CRITICAL FIELDS ===")
        
        // Логируем размер payload
        print("🌐 [Config] Payload size: \(jsonData.count) bytes")
        
        print("🌐 [Config] Sending request...")
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        print("📥 [Config] === RESPONSE RECEIVED ===")
        print("📥 [Config] Status: \(http.statusCode)")
        print("📥 [Config] Headers: \(http.allHeaderFields)")
        LogCollector.shared.logConfig("Response status: \(http.statusCode)")
        
        // === МАКСИМАЛЬНО ПОДРОБНОЕ ЛОГИРОВАНИЕ ОТВЕТА ===
        print("📥 [Config] === FULL SERVER RESPONSE START ===")
        if let responseString = String(data: data, encoding: .utf8) {
            print(responseString)
            LogCollector.shared.logConfig("FULL SERVER RESPONSE: \(responseString)")
        } else {
            print("📥 [Config] Response data size: \(data.count) bytes (not UTF-8)")
            LogCollector.shared.logError("Server response is not UTF-8 encoded")
        }
        print("📥 [Config] === FULL SERVER RESPONSE END ===")
        
        // Анализ статуса ответа
        print("📥 [Config] === RESPONSE ANALYSIS ===")
        switch http.statusCode {
        case 200:
            print("📥 [Config] ✅ HTTP 200 OK - Request successful")
            LogCollector.shared.logConfig("HTTP 200 OK - Request successful")
        case 400:
            print("📥 [Config] ❌ HTTP 400 Bad Request - Invalid payload or missing fields")
            LogCollector.shared.logError("HTTP 400 Bad Request - Server rejected our payload")
        case 404:
            print("📥 [Config] ❌ HTTP 404 Not Found - Endpoint not found")
            LogCollector.shared.logError("HTTP 404 Not Found - Config endpoint not found")
        case 500...599:
            print("📥 [Config] ❌ HTTP \(http.statusCode) Server Error")
            LogCollector.shared.logError("HTTP \(http.statusCode) Server Error")
        default:
            print("📥 [Config] ⚠️ HTTP \(http.statusCode) Unexpected status")
            LogCollector.shared.logError("HTTP \(http.statusCode) Unexpected status")
        }
        print("📥 [Config] === END RESPONSE ANALYSIS ===")

        // Decode even on non-200 (server can return {ok:false})
        do {
            let decoded = try JSONDecoder().decode(ConfigResponse.self, from: data)
            print("📥 [Config] === DECODED RESPONSE ===")
            print("📥 [Config] ✅ Successfully decoded JSON response")
            print("📥 [Config] ok: \(decoded.ok)")
            print("📥 [Config] url: \(decoded.url ?? "nil")")
            print("📥 [Config] expires: \(decoded.expires ?? 0)")
            print("📥 [Config] message: \(decoded.message ?? "nil")")
            print("📥 [Config] === END DECODED RESPONSE ===")
            
            LogCollector.shared.logConfig("Decoded response: ok=\(decoded.ok), url=\(decoded.url ?? "nil"), message=\(decoded.message ?? "nil")")
            
            if !decoded.ok {
                LogCollector.shared.logError("Server returned ok=false: \(decoded.message ?? "no message")")
            }
            
            return decoded
        } catch {
            print("❌ [Config] Failed to decode JSON response: \(error)")
            LogCollector.shared.logError("Failed to decode JSON response: \(error)")
            throw error
        }
    }
}
