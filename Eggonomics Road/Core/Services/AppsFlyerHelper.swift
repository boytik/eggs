import Foundation
import AppsFlyerLib
import UIKit
import FirebaseMessaging

final class AppsFlyerHelper: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    static let shared = AppsFlyerHelper()
    private override init() {}

    private let conversionKey = "af_raw_conversion_json"
    private let deepLinkKey = "af_raw_deeplink_json" // store raw UDL JSON string
    
    // Механизм ожидания конверсионных данных
    private var conversionContinuation: CheckedContinuation<[AnyHashable: Any]?, Never>?
    private var hasReceivedConversionData = false 

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
        
        // Уведомляем ожидающих о получении данных
        hasReceivedConversionData = true
        conversionContinuation?.resume(returning: conversionInfo)
        conversionContinuation = nil
    }

    func onConversionDataFail(_ error: Error) {
        print("❌ [AF] Conversion error: \(error.localizedDescription)")
        
        // Уведомляем ожидающих об ошибке (возвращаем nil)
        hasReceivedConversionData = true
        conversionContinuation?.resume(returning: nil)
        conversionContinuation = nil
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
    
    /// Ожидает получения конверсионных данных от AppsFlyer с таймаутом
    func waitForConversionData(timeout: TimeInterval = 10.0) async -> [AnyHashable: Any]? {
        // Если данные уже получены, возвращаем их сразу
        if hasReceivedConversionData {
            print("🔄 [AF] Conversion data already available")
            return rawConversionDict()
        }
        
        print("⏳ [AF] Waiting for conversion data (timeout: \(timeout)s)...")
        
        return await withTaskGroup(of: [AnyHashable: Any]?.self) { group in
            // Задача ожидания данных
            group.addTask {
                await withCheckedContinuation { continuation in
                    self.conversionContinuation = continuation
                }
            }
            
            // Задача таймаута
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                print("⏰ [AF] Conversion data timeout reached")
                return nil
            }
            
            // Возвращаем первый результат
            for await result in group {
                group.cancelAll()
                return result
            }
            
            return nil
        }
    }

    /// Build merged payload (raw AF + client fields + UDL data). DO NOT mutate AF keys/types/nulls.
    func buildMergedPayload() async -> [String: Any] {
        // Ожидаем получения конверсионных данных
        _ = await waitForConversionData()
        
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
        print("🔍 [AF] af_id value: '\(af_id ?? "nil")'")
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let storeID = "id6754333754"
        let locale = Locale.current.identifier
        let pushToken = try? await Messaging.messaging().token()
        let firebaseProjectID = "8934278530"
        print("🔍 [AF] bundleID: '\(bundleID)', storeID: '\(storeID)', locale: '\(locale)'")
        print("🔍 [AF] pushToken: '\(pushToken ?? "nil")', firebaseProjectID: '\(firebaseProjectID)'")

        merged["af_id"] = af_id
        merged["bundle_id"] = bundleID
        merged["os"] = "iOS"
        merged["store_id"] = storeID
        merged["locale"] = locale
        if let pushToken = pushToken { merged["push_token"] = pushToken }
        merged["firebase_project_id"] = firebaseProjectID

        print("🔍 [AF] Final merged payload keys: \(merged.keys.sorted())")
        if merged["af_status"] as? String == "Non-organic" {
            print("🔍 [AF] Non-organic install - full payload will be sent to server")
        }

        return merged
    }
}
