import Foundation
import UserNotifications
import FirebaseMessaging
import UIKit

final class PushPermissionService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = PushPermissionService()
    private override init() {}

    private let nextAskKey = "push_next_ask_date"
    private let syncQueue = DispatchQueue(label: "PushPermissionService.Sync")
    private var apnsTokenData: Data?
    private var currentFCMTokenInternal: String?

    func configure() {
        print("🔧 [Push] Configuring PushPermissionService...")
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Запускаем диагностику при инициализации
        Task {
            await checkCurrentPermissionStatus()
        }
        print("✅ [Push] PushPermissionService configured successfully")
    }

    func shouldShowCustomAsk() -> Bool {
        let now = Date()
        let next = UserDefaults.standard.object(forKey: nextAskKey) as? Date ?? .distantPast
        return now >= next
    }

    func scheduleReaskIn3Days() {
        // 3 дня = 259200 секунд
        let next = Calendar.current.date(byAdding: .second, value: 259200, to: Date())!
        UserDefaults.standard.set(next, forKey: nextAskKey)
        print("⏰ [Push] Will re-ask on: \(next) (in 3 days / 259200 seconds)")
        LogCollector.shared.logPush("Will re-ask system permission on \(next)")
    }
    
    func markPermissionAsked() {
        // Помечаем что разрешение уже спрашивали (для однократного показа)
        UserDefaults.standard.set(true, forKey: "push_permission_asked")
        print("✅ [Push] Marked permission as asked")
    }
    
    func hasAskedPermissionBefore() -> Bool {
        return UserDefaults.standard.bool(forKey: "push_permission_asked")
    }
    
    func canAskForPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        
        print("🔔 [Push] Authorization status: \(settings.authorizationStatus.rawValue)")
        print("🔔 [Push] Should show custom ask: \(shouldShowCustomAsk())")
        
        // НЕ показываем экран если:
        // 1. Пользователь уже дал разрешение (.authorized)
        // 2. Пользователь запретил (.denied) и еще не прошло 3 дня
        // 3. Разрешение временно недоступно (.provisional, .ephemeral)
        
        switch settings.authorizationStatus {
        case .authorized:
            print("🔔 [Push] Permission already granted - not showing screen")
            return false
        case .denied:
            let canReask = shouldShowCustomAsk()
            print("🔔 [Push] Permission denied - can reask: \(canReask)")
            return canReask
        case .notDetermined:
            print("🔔 [Push] Permission not determined - can ask")
            return true
        case .provisional:
            print("🔔 [Push] Provisional permission - not showing screen")
            return false
        case .ephemeral:
            print("🔔 [Push] Ephemeral permission - not showing screen")
            return false
        @unknown default:
            print("🔔 [Push] Unknown permission status - not showing screen")
            return false
        }
    }

    func requestSystemAuthorization() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings])
                LogCollector.shared.logPush("System authorization result: \(granted)")
                
                if granted {
                    print("✅ [Push] System permission granted - registering for remote notifications")
                    LogCollector.shared.logPush("System permission granted - registering for remote notifications")
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("🚫 [Push] System permission denied - scheduling re-ask in 3 days")
                    LogCollector.shared.logPush("System permission denied by user")
                    // Если пользователь отказался в системном диалоге, планируем повторный показ через 3 дня
                    scheduleReaskIn3Days()
                }
            } catch {
                print("❌ [Push] System authorization request error: \(error)")
                LogCollector.shared.logError("System authorization request error: \(error)")
                // При ошибке также планируем повторный показ
                scheduleReaskIn3Days()
            }
        }
    }

    // MARK: UNUserNotificationCenterDelegate
    
    // Показываем уведомления даже когда приложение активно
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 [Push] === NOTIFICATION RECEIVED WHILE APP ACTIVE ===")
        print("🔔 [Push] Title: \(notification.request.content.title)")
        print("🔔 [Push] Body: \(notification.request.content.body)")
        print("🔔 [Push] UserInfo: \(notification.request.content.userInfo)")
        print("🔔 [Push] Badge: \(notification.request.content.badge ?? 0)")
        print("🔔 [Push] Sound: \(notification.request.content.sound?.debugDescription ?? "default")")
        
        LogCollector.shared.logPush("Notification received while app active - Title: \(notification.request.content.title)")
        
        // Показываем уведомления даже когда приложение активно
        completionHandler([.alert, .badge, .sound])
        print("🔔 [Push] Notification will be presented with [alert, badge, sound]")
    }
    
    // Обработка нажатия на уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("🔔 [Push] === USER TAPPED NOTIFICATION ===")
        print("🔔 [Push] Action identifier: \(response.actionIdentifier)")
        print("🔔 [Push] Notification title: \(response.notification.request.content.title)")
        print("🔔 [Push] Notification body: \(response.notification.request.content.body)")
        
        let userInfo = response.notification.request.content.userInfo
        print("🔔 [Push] Full notification payload: \(userInfo)")
        
        LogCollector.shared.logPush("User tapped notification - Action: \(response.actionIdentifier), Title: \(response.notification.request.content.title)")
        
        // Ищем URL в data секции payload
        var urlString: String?
        
        // Проверяем разные возможные структуры payload
        if let dataDict = userInfo["data"] as? [String: Any],
           let url = dataDict["url"] as? String {
            // Структура: { "data": { "url": "https://example.com/" } }
            urlString = url
            print("🔔 [Push] Found URL in data section: \(url)")
        } else if let url = userInfo["url"] as? String {
            // Прямая структура: { "url": "https://example.com/" }
            urlString = url
            print("🔔 [Push] Found URL in root: \(url)")
        }
        
        if let urlString = urlString, 
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            print("🔔 [Push] ✅ Opening URL from notification: \(urlString)")
            print("🔔 [Push] ⚠️  This is a temporary URL - will not be saved")
            NotificationCenter.default.post(name: .openURLInsideApp, object: url)
        } else {
            print("🔔 [Push] ❌ No valid URL found in notification payload")
        }
    }

    // MARK: MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📮 [Push] === FCM TOKEN DELEGATE CALLBACK ===")
        print("📮 [Push] FCM token from delegate: \(fcmToken?.prefix(20) ?? "nil")...")
        print("📮 [Push] Token length: \(fcmToken?.count ?? 0)")
        
        guard let token = fcmToken, !token.isEmpty else {
            print("❌ [Push] FCM token delegate callback provided empty token")
            LogCollector.shared.logError("FCM token delegate callback provided empty token")
            return
        }
        
        print("✅ [Push] Valid FCM token received via delegate")
        LogCollector.shared.logPush("FCM token received via delegate (length: \(token.count))")
        storeFCMToken(token, source: "delegate")
    }
    
    func updateAPNSToken(_ token: Data) {
        let tokenString = token.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 [Push] APNs device token updated: \(tokenString)")
        LogCollector.shared.logPush("APNs device token received: \(tokenString)")
        syncQueue.async {
            self.apnsTokenData = token
        }
        refreshFCMToken(reason: "APNs token updated")
    }
    
    // Получение текущего FCM токена (с ожиданием до timeout секунд)
    func getCurrentFCMToken(timeout: TimeInterval = 10.0) async -> String? {
        print("📮 [Push] === FCM TOKEN REQUEST START ===")
        LogCollector.shared.logPush("FCM token request started (timeout: \(timeout)s)")
        
        if let cached = currentFCMTokenSnapshot(), !cached.isEmpty {
            print("📮 [Push] ✅ Using cached FCM token: \(cached.prefix(20))...")
            LogCollector.shared.logPush("Using cached FCM token (length: \(cached.count))")
            return cached
        }
        
        print("📮 [Push] ⏳ No cached token - waiting for FCM token (timeout: \(timeout)s)")
        LogCollector.shared.logPush("No cached token - waiting for FCM token")
        refreshFCMToken(reason: "Explicit request from payload builder")

        let interval: TimeInterval = 0.5
        let iterations = max(1, Int(timeout / interval))

        for attempt in 0..<iterations {
            if let token = currentFCMTokenSnapshot(), !token.isEmpty {
                print("📮 [Push] ✅ FCM token obtained after \(Double(attempt) * interval)s wait")
                print("📮 [Push] Token: \(token.prefix(20))... (length: \(token.count))")
                LogCollector.shared.logPush("FCM token obtained after \(Double(attempt) * interval)s wait (length: \(token.count))")
                return token
            }
            
            print("📮 [Push] ⏳ Attempt \(attempt + 1)/\(iterations) - no token yet, sleeping \(interval)s")
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

            // Повторно запрашиваем токен каждые 2 секунды, если его все еще нет
            if (attempt + 1) % 4 == 0 {
                print("📮 [Push] 🔄 Retry \(attempt + 1) - refreshing FCM token")
                refreshFCMToken(reason: "Retry while waiting (attempt \(attempt + 1))")
            }
        }

        // Финальная проверка на границе таймаута
        if let token = currentFCMTokenSnapshot(), !token.isEmpty {
            print("📮 [Push] ✅ FCM token obtained at timeout boundary")
            print("📮 [Push] Token: \(token.prefix(20))... (length: \(token.count))")
            LogCollector.shared.logPush("FCM token obtained at timeout boundary (length: \(token.count))")
            return token
        }

        print("📮 [Push] ❌ FCM token wait timed out after \(timeout)s")
        print("📮 [Push] === FCM TOKEN REQUEST FAILED ===")
        LogCollector.shared.logError("FCM token wait timed out after \(timeout)s")
        return nil
    }

    // MARK: - Testing Methods
    func sendTestNotification() {
        print("🧪 [Push] Sending test local notification...")
        let content = UNMutableNotificationContent()
        content.title = "Test Push Notification"
        content.body = "This is a test notification to verify push notifications are working"
        content.sound = .default
        content.badge = 1
        
        let request = UNNotificationRequest(identifier: "test-notification-\(Date().timeIntervalSince1970)", 
                                          content: content, 
                                          trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ [Push] Failed to schedule test notification: \(error)")
                LogCollector.shared.logError("Failed to schedule test notification: \(error)")
            } else {
                print("✅ [Push] Test notification scheduled successfully")
                LogCollector.shared.logPush("Test notification scheduled successfully")
            }
        }
    }
    
    func printCurrentTokens() async {
        print("🔍 [Push] === CURRENT TOKENS ===")
        
        // FCM Token
        if let fcmToken = await getCurrentFCMToken(timeout: 5.0) {
            print("📮 [Push] FCM Token: \(fcmToken.prefix(20))...(\(fcmToken.count) chars)")
        } else {
            print("❌ [Push] FCM Token: Not available")
        }
        
        // APNs Token
        let apnsToken = syncQueue.sync { apnsTokenData }
        if let apnsToken = apnsToken {
            let tokenString = apnsToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("📱 [Push] APNs Token: \(tokenString)")
        } else {
            print("❌ [Push] APNs Token: Not available")
        }
        
        print("🔍 [Push] === END TOKENS ===")
    }
    
    func forceRefreshTokens() {
        print("🔄 [Push] Force refreshing all tokens...")
        LogCollector.shared.logPush("Force refreshing all tokens")
        
        // Принудительно обновляем FCM токен
        refreshFCMToken(reason: "Force refresh requested")
        
        // Перерегистрируемся для push уведомлений
        UIApplication.shared.registerForRemoteNotifications()
        
        print("✅ [Push] Token refresh initiated")
    }
    
    func getAPNSTokenForDiagnostics() -> String? {
        return syncQueue.sync {
            guard let tokenData = apnsTokenData else { return nil }
            return tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        }
    }

    // MARK: - Diagnostic Methods
    func checkCurrentPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        print("🔔 [Push] === PERMISSION DIAGNOSTICS ===")
        print("🔔 [Push] Authorization status: \(settings.authorizationStatus.rawValue) (\(authorizationStatusDescription(settings.authorizationStatus)))")
        print("🔔 [Push] Alert setting: \(settings.alertSetting.rawValue) (\(notificationSettingDescription(settings.alertSetting)))")
        print("🔔 [Push] Badge setting: \(settings.badgeSetting.rawValue) (\(notificationSettingDescription(settings.badgeSetting)))")
        print("🔔 [Push] Sound setting: \(settings.soundSetting.rawValue) (\(notificationSettingDescription(settings.soundSetting)))")
        print("🔔 [Push] Notification center setting: \(settings.notificationCenterSetting.rawValue) (\(notificationSettingDescription(settings.notificationCenterSetting)))")
        print("🔔 [Push] Lock screen setting: \(settings.lockScreenSetting.rawValue) (\(notificationSettingDescription(settings.lockScreenSetting)))")
        print("🔔 [Push] Critical alert setting: \(settings.criticalAlertSetting.rawValue) (\(notificationSettingDescription(settings.criticalAlertSetting)))")
        print("🔔 [Push] === END DIAGNOSTICS ===")
        
        LogCollector.shared.logPush("Permission diagnostics - Auth: \(authorizationStatusDescription(settings.authorizationStatus)), Alert: \(notificationSettingDescription(settings.alertSetting))")
    }
    
    private func authorizationStatusDescription(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func notificationSettingDescription(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }

    // MARK: - Private helpers
    private func currentFCMTokenSnapshot() -> String? {
        syncQueue.sync { currentFCMTokenInternal }
    }
    
    private func storeFCMToken(_ token: String, source: String) {
        guard !token.isEmpty else {
            LogCollector.shared.logError("Attempted to store empty FCM token (source: \(source))")
            return
        }
        LogCollector.shared.logPush("Storing FCM token (source: \(source))")
        syncQueue.async {
            self.currentFCMTokenInternal = token
        }
    }
    
    private func refreshFCMToken(reason: String) {
        LogCollector.shared.logPush("Refreshing FCM token (reason: \(reason))")
        Task {
            do {
                let token = try await Messaging.messaging().token()
                print("📮 [Push] Retrieved FCM token after refresh: \(token)")
                storeFCMToken(token, source: "refresh")
            } catch {
                print("❌ [Push] Failed to refresh FCM token: \(error)")
                LogCollector.shared.logError("Failed to refresh FCM token: \(error)")
            }
        }
    }
}

extension Notification.Name {
    static let openURLInsideApp = Notification.Name("openURLInsideApp")
}
