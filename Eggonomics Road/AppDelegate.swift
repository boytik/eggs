import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let hasVisitedSVViewController = UserDefaults.standard.bool(forKey: "sosi")
        if hasVisitedSVViewController {
            window?.rootViewController = UINavigationController(rootViewController: ChickLoading())

        } else {
            window?.rootViewController = UINavigationController(rootViewController: ChickLoading())
        }
        window?.makeKeyAndVisible()
        UINavigationBar.appearance().tintColor = UIColor.black
        return true
    }
}
