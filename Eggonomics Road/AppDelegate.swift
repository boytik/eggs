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
        print("✅ Device registered for remote notifications")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Deep Links support (Universal Links / URL Schemes)
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        print("🔗 [AppDelegate] Universal Link received: \(userActivity.webpageURL?.absoluteString ?? "nil")")
        AppsFlyerLib.shared().continue(userActivity, restorationHandler: nil)
        
        // Перезапускаем flow через небольшую задержку, чтобы AppsFlyer обработал данные
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        print("🔗 [AppDelegate] URL Scheme received: \(url.absoluteString)")
        AppsFlyerLib.shared().handleOpen(url, options: options)
        
        // Перезапускаем flow через небольшую задержку, чтобы AppsFlyer обработал данные
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
