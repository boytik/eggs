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
        let next = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        UserDefaults.standard.set(next, forKey: nextAskKey)
        print("⏰ [Push] Will re-ask on: \(next)")
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
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        if let urlString = userInfo["url"] as? String, let url = URL(string: urlString) {
            NotificationCenter.default.post(name: .openURLInsideApp, object: url)
        }
    }

    // MARK: MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("📮 [Push] FCM token: \(fcmToken ?? "nil")")
    }
}

extension Notification.Name {
    static let openURLInsideApp = Notification.Name("openURLInsideApp")
}
