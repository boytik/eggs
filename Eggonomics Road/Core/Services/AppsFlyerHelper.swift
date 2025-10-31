import Foundation
import AppsFlyerLib
import UIKit
import FirebaseMessaging

final class AppsFlyerHelper: NSObject, AppsFlyerLibDelegate {
    static let shared = AppsFlyerHelper()
    private override init() {}

    private let conversionKey = "af_raw_conversion_json" 

    func startSDK(appID: String, devKey: String, scene: UIWindowScene?) {
        let af = AppsFlyerLib.shared()
        af.appsFlyerDevKey = devKey
        af.appleAppID = appID
        af.delegate = self
        af.isDebug = false
        af.start()
        print("🚀 [AF] Started")
    }

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("✅ [AF] Conversion received")
        // Keep RAW JSON (no key changes, no null removal)
        do {
            let data = try JSONSerialization.data(withJSONObject: conversionInfo, options: [])
            if let json = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(json, forKey: conversionKey)
            }
        } catch {
            print("❌ [AF] Failed to serialize conversion data: \(error)")
        }
    }

    func onConversionDataFail(_ error: Error) {
        print("❌ [AF] Conversion error: \(error.localizedDescription)")
    }

    /// Returns raw AppsFlyer JSON object (as Dictionary) EXACTLY as provided (no mutation).
    func rawConversionDict() -> [String: Any]? {
        guard let json = UserDefaults.standard.string(forKey: conversionKey),
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { return nil }
        return obj
    }

    /// Build merged payload (raw AF + client fields). DO NOT mutate AF keys/types/nulls.
    func buildMergedPayload() async -> [String: Any] {
        var merged: [String: Any] = rawConversionDict() ?? [:]
        // Additional client fields
        let af_id = AppsFlyerLib.shared().getAppsFlyerUID()
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let storeID = "id6754333754"
        let locale = Locale.current.identifier
        let pushToken = try? await Messaging.messaging().token()
        let firebaseProjectID = "8934278530"

        merged["af_id"] = af_id
        merged["bundle_id"] = bundleID
        merged["os"] = "iOS"
        merged["store_id"] = storeID
        merged["locale"] = locale
        if let pushToken = pushToken { merged["push_token"] = pushToken }
        merged["firebase_project_id"] = firebaseProjectID

        return merged
    }
}
