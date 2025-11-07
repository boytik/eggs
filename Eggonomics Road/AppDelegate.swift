import UIKit
import UserNotifications
import Firebase
import FirebaseMessaging
import AppsFlyerLib
import AppTrackingTransparency
import AdSupport

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // MARK: - AppsFlyer Configuration
    private let appsFlyerDevKey = "NJa8iEGgMwMwwikv2AQDRn"
    private let appsFlyerAppID = "6754333754" // без префикса "id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("🚀 App: Starting initialization...")

        // Проверяем launch options на наличие URL
        if let url = launchOptions?[.url] as? URL {
            print("🔗 [AppDelegate] Launched with URL: \(url.absoluteString)")
        }
        if let userActivity = launchOptions?[.userActivityDictionary] as? [String: Any] {
            print("🔗 [AppDelegate] Launched with user activity: \(userActivity)")
        }

        // 1) Firebase + пуши
        setupFirebase(application: application)

        // 2) AppsFlyer
        setupAppsFlyer()

        print("✅ App: SDK initialization completed")

        // 3) Window / Root - New Integration
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Hide status bar globally
        UIApplication.shared.isStatusBarHidden = true
        
        // Start with new RootContainerViewController
        let rootVC = RootContainerViewController()
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        UINavigationBar.appearance().tintColor = .black
        
        // Configure push service
        PushPermissionService.shared.configure()

        return true
    }

    // MARK: - Firebase Setup
    private func setupFirebase(application: UIApplication) {
        print("🔥 Firebase: Configuring...")
        FirebaseApp.configure()

        // Делегаты уведомлений/FCM
        UNUserNotificationCenter.current().delegate = PushPermissionService.shared
        Messaging.messaging().delegate = PushPermissionService.shared

        print("✅ Firebase: Configuration completed")
    }

    // MARK: - AppsFlyer Setup
    private func setupAppsFlyer() {
        print("📊 AppsFlyer: Configuring...")

        let af = AppsFlyerLib.shared()
        af.appsFlyerDevKey = appsFlyerDevKey
        af.appleAppID = appsFlyerAppID
        af.delegate = AppsFlyerHelper.shared
        af.deepLinkDelegate = AppsFlyerHelper.shared // UDL delegate
        af.isDebug = true                 // ВРЕМЕННО включен для отладки
        af.minTimeBetweenSessions = 5
        af.waitForATTUserAuthorization(timeoutInterval: 60)

        print("✅ AppsFlyer: Configuration completed")
        print("   Dev Key: \(appsFlyerDevKey)")
        print("   App ID: \(appsFlyerAppID)")
    }

    // MARK: - AppsFlyer start (+ ATT)
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 [AppDelegate] App became active")
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                print("🔒 [AppDelegate] ATT Status: \(status.rawValue)")
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    print("🚀 AppsFlyer: Started tracking")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
            print("🚀 AppsFlyer: Started tracking")
        }
    }

    // MARK: Remote notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ [Push] Device registered for remote notifications")
        print("📱 [Push] Device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Messaging.messaging().apnsToken = deviceToken
        LogCollector.shared.logPush("APNs token assigned to Firebase Messaging")
        PushPermissionService.shared.updateAPNSToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [Push] Failed to register for remote notifications: \(error.localizedDescription)")
        LogCollector.shared.logError("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Обработка push-уведомлений когда приложение в фоне
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("🔔 [Push] Received remote notification (background): \(userInfo)")
    }
    
    // Обработка push-уведомлений с completion handler
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔔 [Push] Received remote notification with completion handler: \(userInfo)")
        
        // Ищем URL в data секции payload (как в примере из документации)
        var urlString: String?
        
        if let dataDict = userInfo["data"] as? [String: Any],
           let url = dataDict["url"] as? String {
            urlString = url
            print("🔔 [Push] Found URL in data section: \(url)")
        } else if let url = userInfo["url"] as? String {
            urlString = url
            print("🔔 [Push] Found URL in root: \(url)")
        }
        
        if let urlString = urlString, 
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            print("🔔 [Push] ✅ Processing URL from background notification: \(urlString)")
            print("🔔 [Push] ⚠️  This is a temporary URL - will not be saved")
            NotificationCenter.default.post(name: .openURLInsideApp, object: url)
            completionHandler(.newData)
        } else {
            print("🔔 [Push] ❌ No valid URL found in background notification")
            completionHandler(.noData)
        }
    }

    // MARK: - Deep Links support (Universal Links / URL Schemes)
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let urlString = userActivity.webpageURL?.absoluteString ?? "nil"
        print("🔗 [AppDelegate] Universal Link received: \(urlString)")
        
        // Определяем тип ссылки
        if let url = userActivity.webpageURL?.absoluteString {
            if url.contains("onelink.me") {
                print("🔗 [AppDelegate] ⭐ This is a OneLink Universal Link")
            } else if url.contains("app.appsflyer.com") {
                print("🔗 [AppDelegate] ⭐ This is a direct AppsFlyer Universal Link")
            } else {
                print("🔗 [AppDelegate] ⭐ This is a custom Universal Link: \(url)")
            }
        }
        
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        
        // Перезапускаем flow через задержку, чтобы AppsFlyer обработал данные
        // Для OneLink ссылок может потребоваться больше времени
        let delay: TimeInterval = urlString.contains("onelink.me") ? 4.0 : 2.0
        print("🔄 [AppDelegate] Will restart flow in \(delay) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController as? RootContainerViewController {
                print("🔄 [AppDelegate] Restarting flow after Universal Link")
                Task { await rootVC.startFlow(forceFirstLaunch: true) }
            }
        }
        
        return true
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let urlString = url.absoluteString
        print("🔗 [AppDelegate] URL Scheme received: \(urlString)")
        
        // Определяем тип ссылки
        if urlString.contains("onelink.me") {
            print("🔗 [AppDelegate] ⭐ This is a OneLink URL Scheme")
        } else if urlString.contains("app.appsflyer.com") {
            print("🔗 [AppDelegate] ⭐ This is a direct AppsFlyer URL Scheme")
        } else {
            print("🔗 [AppDelegate] ⭐ This is a custom URL Scheme: \(urlString)")
        }
        
        AppsFlyerLib.shared().handleOpen(url, options: options)
        
        // Перезапускаем flow через задержку, чтобы AppsFlyer обработал данные
        // Для OneLink ссылок может потребоваться больше времени
        let delay: TimeInterval = urlString.contains("onelink.me") ? 4.0 : 2.0
        print("🔄 [AppDelegate] Will restart flow in \(delay) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController as? RootContainerViewController {
                print("🔄 [AppDelegate] Restarting flow after URL Scheme")
                Task { await rootVC.startFlow(forceFirstLaunch: true) }
            }
        }
        
        return true
    }

    // MARK: - Orientation Support
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Получаем текущий контроллер
        guard let rootVC = window?.rootViewController else {
            return .portrait
        }
        
        // Проверяем тип контроллера
        if let _ = rootVC as? WebContainerViewController {
            return .allButUpsideDown // Портрет + альбомные
        }
        
        // Если это RootContainerViewController, проверяем его дочерние контроллеры
        if let containerVC = rootVC as? RootContainerViewController {
            // Проверяем текущий показываемый контроллер
            if let currentVC = containerVC.children.first {
                if let _ = currentVC as? WebContainerViewController {
                    return .allButUpsideDown
                }
                if let navController = currentVC as? UINavigationController {
                    if let topVC = navController.topViewController {
                        if topVC is EggLoadingBouncingViewController {
                            return .allButUpsideDown
                        }
                        // Для игровых экранов принудительно поворачиваем в портрет
                        if topVC is ChickTabBar || topVC is ChickMenu || topVC is ChickOnboarding {
                            DispatchQueue.main.async {
                                self.forcePortraitOrientation(for: window)
                            }
                        }
                    }
                }
            }
        }
        
        // Для всех остальных контроллеров - только портрет
        return .portrait
    }
    
    // MARK: - Orientation Helper
    private func forcePortraitOrientation(for window: UIWindow?) {
        guard UIDevice.current.orientation.isLandscape else { return }
        
        print("🔄 [AppDelegate] Forcing portrait orientation for game screen")
        
        if #available(iOS 16.0, *) {
            window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
                if error != nil {
                    print("❌ [AppDelegate] Failed to force portrait: \(error)")
                } else {
                    print("✅ [AppDelegate] Successfully forced portrait orientation")
                }
            }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            print("✅ [AppDelegate] Forced portrait orientation (legacy)")
        }
    }
}
