import Foundation
import UserNotifications
import FirebaseMessaging
import UIKit

final class PushPermissionService: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = PushPermissionService()
    private override init() {}

    private let nextAskKey = "push_next_ask_date"

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
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
        
        // Можем спросить если:
        // 1. Разрешение еще не определено (первый запуск)
        // 2. Или если прошло 3 дня с момента отказа
        let canAsk = settings.authorizationStatus == .notDetermined || shouldShowCustomAsk()
        
        print("🔔 [Push] Can ask for permission: \(canAsk)")
        print("🔔 [Push] Authorization status: \(settings.authorizationStatus.rawValue)")
        print("🔔 [Push] Should show custom ask: \(shouldShowCustomAsk())")
        
        return canAsk
    }

    func requestSystemAuthorization() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound, .providesAppNotificationSettings])
                print(granted ? "🔔 [Push] Granted" : "🚫 [Push] Denied")
                if granted { UIApplication.shared.registerForRemoteNotifications() }
            } catch {
                print("❌ [Push] Request error: \(error)")
            }
        }
    }

    // MARK: UNUserNotificationCenterDelegate
    
    // Показываем уведомления даже когда приложение активно
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 [Push] Received notification while app is active")
        // Показываем уведомления даже когда приложение активно
        completionHandler([.alert, .badge, .sound])
    }
    
    // Обработка нажатия на уведомление
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("🔔 [Push] User tapped notification")
        let userInfo = response.notification.request.content.userInfo
        print("🔔 [Push] Full notification payload: \(userInfo)")
        
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
        print("📮 [Push] FCM token: \(fcmToken ?? "nil")")
    }
    
    // Получение текущего FCM токена
    func getCurrentFCMToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            print("📮 [Push] Retrieved FCM token: \(token)")
            return token
        } catch {
            print("❌ [Push] Failed to get FCM token: \(error)")
            return nil
        }
    }
}

extension Notification.Name {
    static let openURLInsideApp = Notification.Name("openURLInsideApp")
}
