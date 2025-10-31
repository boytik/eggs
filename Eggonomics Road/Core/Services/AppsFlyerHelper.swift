import Foundation
import AppsFlyerLib
import UIKit
import FirebaseMessaging

final class AppsFlyerHelper: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    static let shared = AppsFlyerHelper()
    private override init() {}

    private let conversionKey = "af_raw_conversion_json"
    private let deepLinkKey = "af_raw_deeplink_json" // store raw UDL JSON string 

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
    
    // MARK: - Deep Link Delegate
    func didResolveDeepLink(_ result: DeepLinkResult) {
        print("🔗 [AF] Deep link received")
        
        switch result.status {
        case .found:
            if let deepLinkObj = result.deepLink?.clickEvent {
                print("✅ [AF] Deep link data found")
                // Keep RAW UDL JSON (no key changes, no null removal)
                do {
                    let data = try JSONSerialization.data(withJSONObject: deepLinkObj, options: [])
                    if let json = String(data: data, encoding: .utf8) {
                        UserDefaults.standard.set(json, forKey: deepLinkKey)
                        print("💾 [AF] Deep link data cached")
                    }
                } catch {
                    print("❌ [AF] Failed to serialize deep link data: \(error)")
                }
            }
        case .notFound:
            print("🔍 [AF] Deep link not found")
        case .failure:
            print("❌ [AF] Deep link error: \(result.error?.localizedDescription ?? "unknown")")
        @unknown default:
            print("⚠️ [AF] Unknown deep link status")
        }
    }

    /// Returns raw AppsFlyer JSON object (as Dictionary) EXACTLY as provided (no mutation).
    func rawConversionDict() -> [String: Any]? {
        guard let json = UserDefaults.standard.string(forKey: conversionKey),
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { return nil }
        return obj
    }
    
    /// Returns raw Deep Link JSON object (as Dictionary) EXACTLY as provided (no mutation).
    func rawDeepLinkDict() -> [String: Any]? {
        guard let json = UserDefaults.standard.string(forKey: deepLinkKey),
              let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        else { return nil }
        return obj
    }

    /// Build merged payload (raw AF + client fields + UDL data). DO NOT mutate AF keys/types/nulls.
    func buildMergedPayload() async -> [String: Any] {
        // Start with conversion data
        var merged: [String: Any] = rawConversionDict() ?? [:]
        
        // Add UDL data if available (conversion data takes priority for duplicate keys)
        if let deepLinkData = rawDeepLinkDict() {
            print("🔗 [AF] Adding UDL data to payload")
            for (key, value) in deepLinkData {
                // Only add if key doesn't exist (conversion data has priority)
                if merged[key] == nil {
                    merged[key] = value
                }
            }
        }
        
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
