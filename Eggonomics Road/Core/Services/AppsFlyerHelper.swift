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
        af.isDebug = true  // ВРЕМЕННО включен для отладки
        af.start()
        print("🚀 [AF] Started")
        LogCollector.shared.logAppsFlyer("SDK started with appID: \(appID), devKey: \(devKey)")
    }

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
        print("✅ [AF] Conversion received")
        LogCollector.shared.logAppsFlyer("Conversion data received: \(conversionInfo.count) keys")
        
        // Логируем ключевые параметры
        let afStatus = conversionInfo["af_status"] as? String ?? "nil"
        let isFirstLaunch = conversionInfo["is_first_launch"] as? Bool ?? false
        print("🔍 [AF] af_status: '\(afStatus)', is_first_launch: \(isFirstLaunch)")
        
        // Логируем все ключи для отладки
        let keys = "🔍 All conversion keys: \(Array(conversionInfo.keys).map { "\($0)" }.sorted())"
        print(keys)
        
        // Keep RAW JSON (no key changes, no null removal)
        do {
            let data = try JSONSerialization.data(withJSONObject: conversionInfo, options: [])
            if let json = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(json, forKey: conversionKey)
                print("💾 [AF] Conversion data saved to UserDefaults")
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
        
        // Проверяем тип ссылки через clickEvent данные
        if let deepLink = result.deepLink {
            let clickEvent = deepLink.clickEvent
            print("🔗 [AF] Deep link click event received")
            
            // Проверяем различные поля для определения источника
            if let af_dp = clickEvent["af_dp"] as? String {
                print("🔗 [AF] Deep link af_dp: \(af_dp)")
                if af_dp.contains("onelink.me") {
                    print("🔗 [AF] ⭐ This is a OneLink URL")
                } else if af_dp.contains("app.appsflyer.com") {
                    print("🔗 [AF] ⭐ This is a direct AppsFlyer URL")
                }
            }
            
            // Также проверяем другие поля
            if let link = clickEvent["link"] as? String {
                print("🔗 [AF] Deep link 'link' field: \(link)")
            }
            
            if let originalURL = clickEvent["original_link"] as? String {
                print("🔗 [AF] Deep link original URL: \(originalURL)")
                if originalURL.contains("onelink.me") {
                    print("🔗 [AF] ⭐ Original URL is OneLink")
                } else if originalURL.contains("app.appsflyer.com") {
                    print("🔗 [AF] ⭐ Original URL is direct AppsFlyer")
                }
            }
        }
        
        switch result.status {
        case .found:
            if let deepLinkObj = result.deepLink?.clickEvent {
                print("✅ [AF] Deep link data found")
                
                // Логируем ключевые параметры deep link
                if let pid = deepLinkObj["pid"] as? String {
                    print("🔍 [AF] Deep link pid: '\(pid)'")
                }
                if let campaign = deepLinkObj["c"] as? String {
                    print("🔍 [AF] Deep link campaign: '\(campaign)'")
                }
                
                // Специальная проверка для OneLink
                if let af_dp = deepLinkObj["af_dp"] as? String {
                    print("🔍 [AF] OneLink deep link parameter (af_dp): '\(af_dp)'")
                }
                
                // Логируем все ключи deep link для отладки
                let deepKeys = "🔍 All deep link keys: \(Array(deepLinkObj.keys).map { "\($0)" }.sorted())"
                print(deepKeys)
                
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
        
        // Правильная логика согласно документации:
        // "В случае совпадения используются первые полученные данные"
        // Deep link данные обычно приходят первыми, поэтому они имеют приоритет
        
        var merged: [String: Any] = [:]
        
        // Сначала добавляем conversion data
        if let conversionData = rawConversionDict() {
            print("📊 [AF] Adding conversion data to payload (\(conversionData.count) keys)")
            for (key, value) in conversionData {
                merged[key] = value
            }
        }
        
        // Затем добавляем UDL data (перезаписывает совпадающие ключи, т.к. deep link данные "первые")
        if let deepLinkData = rawDeepLinkDict() {
            print("🔗 [AF] Adding UDL data to payload (\(deepLinkData.count) keys)")
            print("🔗 [AF] UDL keys: \(Array(deepLinkData.keys).sorted())")
            
            for (key, value) in deepLinkData {
                if merged[key] != nil {
                    print("🔄 [AF] Overriding key '\(key)' with UDL value (first received data priority)")
                }
                    merged[key] = value
                }
            
            // ВАЖНО: Если есть deep link данные, это означает Non-organic установку
            if !deepLinkData.isEmpty {
                print("🔗 [AF] Deep link data present - ensuring af_status is Non-organic")
                merged["af_status"] = "Non-organic"
            }
        }
        
        // Additional client fields
        let af_id = AppsFlyerLib.shared().getAppsFlyerUID()
        print("🔍 [AF] af_id value: '\(af_id)'")
        print("🔍 [AF] af_id type: \(type(of: af_id))")
        print("🔍 [AF] af_id isEmpty: \(af_id.isEmpty)")
        
        // Используем только реальный AppsFlyer ID
        let finalAfId = af_id
        print("🔍 [AF] Using AppsFlyer ID: '\(finalAfId)'")
        
        if af_id.isEmpty {
            print("⚠️ [AF] WARNING: AppsFlyer ID is empty - this may affect analytics and push notifications")
        }
        
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let storeID = "id6754333754"
        let locale = Locale.current.identifier
        // Получаем FCM токен через PushPermissionService
        let pushToken = await PushPermissionService.shared.getCurrentFCMToken()
        let firebaseProjectID = "279290682673"
        print("🔍 [AF] bundleID: '\(bundleID)', storeID: '\(storeID)', locale: '\(locale)'")
        print("🔍 [AF] pushToken: '\(pushToken ?? "nil")', firebaseProjectID: '\(firebaseProjectID)'")
        if let token = pushToken, !token.isEmpty {
            LogCollector.shared.logPush("Using FCM token in payload")
        } else {
            LogCollector.shared.logError("FCM token missing when building AppsFlyer payload")
        }

        merged["af_id"] = finalAfId
        merged["bundle_id"] = bundleID
        merged["os"] = "iOS"
        merged["store_id"] = storeID
        merged["locale"] = locale
        if let pushToken = pushToken { merged["push_token"] = pushToken }
        merged["firebase_project_id"] = firebaseProjectID

        // Специальные параметры согласно документации
        // sub_id_1 до sub_id_5 берем из af_sub1-af_sub5 если есть
        merged["sub_id_1"] = merged["af_sub1"] ?? ""
        merged["sub_id_2"] = merged["af_sub2"] ?? ""
        merged["sub_id_3"] = merged["af_sub3"] ?? ""
        merged["sub_id_4"] = merged["af_sub4"] ?? ""
        merged["sub_id_5"] = storeID // id6754333754

        // sub_id_7 - пока пустой
        merged["sub_id_7"] = ""

        // sub_id_10 - af_id в специальном формате
        merged["sub_id_10"] = finalAfId

        // sub_id_11 - пока пустой
        merged["sub_id_11"] = ""

        // extra_param_* - пока пустые
        merged["extra_param_2"] = ""
        merged["extra_param_3"] = ""
        merged["extra_param_4"] = ""
        merged["extra_param_5"] = ""
        merged["extra_param_6"] = ""
        merged["extra_param_8"] = ""

        // extra_param_7 - специальная строка с параметрами
        let agency = merged["agency"] as? String ?? ""
        let campaign = merged["campaign"] as? String ?? ""
        let campaignId = merged["campaign_id"] as? String ?? ""
        let mediaSource = merged["media_source"] as? String ?? ""
        let extraParam7 = "af_id=\(finalAfId)&agency=\(agency)&campaign=\(campaign)&campaign_id=\(campaignId)&media_source=\(mediaSource)"
        merged["extra_param_7"] = extraParam7

        // deep_link_value и deep_link_sub1 из deep link данных
        if let deepLinkData = rawDeepLinkDict() {
            merged["deep_link_value"] = deepLinkData["deep_link_value"] ?? "test_link"
            merged["deep_link_sub1"] = deepLinkData["deep_link_sub1"] ?? "test_val"
        } else {
            merged["deep_link_value"] = "test_link"
            merged["deep_link_sub1"] = "test_val"
        }

        print("🔍 [AF] Added special parameters:")
        print("🔍 [AF] sub_id_1: '\(merged["sub_id_1"] ?? "")'")
        print("🔍 [AF] sub_id_2: '\(merged["sub_id_2"] ?? "")'")
        print("🔍 [AF] sub_id_3: '\(merged["sub_id_3"] ?? "")'")
        print("🔍 [AF] sub_id_4: '\(merged["sub_id_4"] ?? "")'")
        print("🔍 [AF] sub_id_5: '\(merged["sub_id_5"] ?? "")'")
        print("🔍 [AF] sub_id_10: '\(merged["sub_id_10"] ?? "")'")
        print("🔍 [AF] extra_param_7: '\(merged["extra_param_7"] ?? "")'")
        print("🔍 [AF] deep_link_value: '\(merged["deep_link_value"] ?? "")'")
        print("🔍 [AF] deep_link_sub1: '\(merged["deep_link_sub1"] ?? "")'")
        print("🔍 [AF] Final af_id used: '\(finalAfId)'")

        // Подробная диагностика для OneLink
        print("🔍 [AF] === DIAGNOSTIC INFO ===")
        print("🔍 [AF] Has conversion data: \(rawConversionDict() != nil)")
        print("🔍 [AF] Has deep link data: \(rawDeepLinkDict() != nil)")
        
        if let conversionData = rawConversionDict() {
            print("🔍 [AF] Conversion data af_status: '\(conversionData["af_status"] ?? "nil")'")
            print("🔍 [AF] Conversion data keys count: \(conversionData.count)")
        }
        
        if let deepLinkData = rawDeepLinkDict() {
            print("🔍 [AF] Deep link data af_status: '\(deepLinkData["af_status"] ?? "nil")'")
            print("🔍 [AF] Deep link data keys count: \(deepLinkData.count)")
            print("🔍 [AF] Deep link data sample keys: \(Array(deepLinkData.keys).prefix(10).sorted())")
        }
        
        // Проверяем null значения
        let nullKeys = merged.compactMap { key, value in
            if value is NSNull { return key }
            return nil
        }
        if !nullKeys.isEmpty {
            print("🔍 [AF] Keys with null values: \(nullKeys.sorted())")
        }
        
        print("🔍 [AF] === END DIAGNOSTIC ===")

        // Финальная отладочная информация
        let finalAfStatus = merged["af_status"] as? String ?? "nil"
        print("🔍 [AF] Final af_status: '\(finalAfStatus)'")
        print("🔍 [AF] Final merged payload keys: \(Array(merged.keys).map { "\($0)" }.sorted())")
        
        // === МАКСИМАЛЬНО ПОДРОБНОЕ ЛОГИРОВАНИЕ PAYLOAD ===
        print("🔍 [AF] === COMPLETE PAYLOAD DUMP START ===")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: merged, options: [.prettyPrinted])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                LogCollector.shared.logAppsFlyer("COMPLETE PAYLOAD: \(jsonString)")
            }
        } catch {
            print("❌ [AF] Failed to serialize payload for logging: \(error)")
            LogCollector.shared.logError("Failed to serialize AppsFlyer payload: \(error)")
        }
        print("🔍 [AF] === COMPLETE PAYLOAD DUMP END ===")
        
        // Финальная проверка критических полей
        print("🔍 [AF] === FINAL CRITICAL FIELDS CHECK ===")
        let criticalFields = ["af_id", "push_token", "firebase_project_id", "bundle_id", "af_status", "store_id"]
        var missingFields: [String] = []
        var emptyFields: [String] = []
        
        for field in criticalFields {
            if let value = merged[field] {
                let stringValue = "\(value)"
                if stringValue.isEmpty || stringValue == "nil" {
                    emptyFields.append(field)
                    print("🔍 [AF] ⚠️ \(field): EMPTY VALUE '\(stringValue)'")
                } else {
                    print("🔍 [AF] ✅ \(field): '\(stringValue)' (\(stringValue.count) chars)")
                }
            } else {
                missingFields.append(field)
                print("🔍 [AF] ❌ \(field): MISSING")
            }
        }
        
        if !missingFields.isEmpty {
            LogCollector.shared.logError("Missing critical fields: \(missingFields.joined(separator: ", "))")
        }
        if !emptyFields.isEmpty {
            LogCollector.shared.logError("Empty critical fields: \(emptyFields.joined(separator: ", "))")
        }
        
        print("🔍 [AF] === END FINAL CHECK ===")
        
        if finalAfStatus.lowercased() == "non-organic" {
            print("🔍 [AF] Non-organic install - full payload will be sent to server")
            LogCollector.shared.logAppsFlyer("Non-organic install detected - sending payload to server")
        } else {
            print("🔍 [AF] Organic install - fan mode will be used")
            LogCollector.shared.logAppsFlyer("Organic install detected - using fan mode")
        }

        return merged
    }
}
