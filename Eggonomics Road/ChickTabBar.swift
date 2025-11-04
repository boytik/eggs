import UIKit

final class ChickTabBar: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        addedTabBarSetup()
        initCount()
    }
    
    private func initCount() {
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "worldCount") == 0 {
            defaults.set(6000, forKey: "worldCount")
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // Только портрет
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Принудительно обновляем layout при появлении
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Дополнительное обновление layout после полного появления
        DispatchQueue.main.async {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            
            // Обновляем layout всех дочерних контроллеров
            for viewController in self.viewControllers ?? [] {
                viewController.view.setNeedsLayout()
                viewController.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
        
    private func addedTabBarSetup() {
        let ta1VC = UINavigationController(rootViewController: ChickMenu())
        let ta2VC = UINavigationController(rootViewController: ChickArticles())
        let ta3VC = UINavigationController(rootViewController: ChickArticlessQuizzesLevels())
        let ta4VC = UINavigationController(rootViewController: ChickFinance())
        let ta5VC = UINavigationController(rootViewController: ChickInfo())
        
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().backgroundColor = .white
        
        ta1VC.tabBarItem = UITabBarItem(
            title: "", image: UIImage(named: "pltab1")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "pltab1Ac")?.withRenderingMode(.alwaysOriginal)
        )

        ta2VC.tabBarItem = UITabBarItem(
            title: "", image: UIImage(named: "pltab2")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "pltab2Ac")?.withRenderingMode(.alwaysOriginal)
        )
        
        ta3VC.tabBarItem = UITabBarItem(
            title: "", image: UIImage(named: "pltab3")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "pltab3Ac")?.withRenderingMode(.alwaysOriginal)
        )
        
        ta4VC.tabBarItem = UITabBarItem(
            title: "", image: UIImage(named: "pltab4")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "pltab4Ac")?.withRenderingMode(.alwaysOriginal)
        )
        
        ta5VC.tabBarItem = UITabBarItem(
            title: "", image: UIImage(named: "pltab5")?.withRenderingMode(.alwaysOriginal),
            selectedImage: UIImage(named: "pltab5Ac")?.withRenderingMode(.alwaysOriginal)
        )
        
        viewControllers = [ta1VC, ta2VC, ta3VC, ta4VC, ta5VC]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
