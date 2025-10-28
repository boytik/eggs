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
        print("🌐 [Config] Sending config request...")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // DO NOT change keys/order/types/nulls for AF data. We serialize as-is.
        request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

        let (data, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        print("📥 [Config] Status: \(http.statusCode)")

        // Decode even on non-200 (server can return {ok:false})
        let decoded = try JSONDecoder().decode(ConfigResponse.self, from: data)
        return decoded
    }
}
