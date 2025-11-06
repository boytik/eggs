import UIKit
import WebKit

final class WebContainerViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var initialURL: URL

    init(initialURL: URL) {
        self.initialURL = initialURL
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // Настройки для автовоспроизведения видео
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Настройки для обработки множественных редиректов
        config.processPool = WKProcessPool()
        
        // Дополнительные настройки для редиректов
        if #available(iOS 14.0, *) {
            config.limitsNavigationsToAppBoundDomains = false
        }
        
        // Настройки preferences для лучшей совместимости
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.preferences.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // Настройки для поддержки всех типов контента
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        
        // Настройки пользовательского агента для лучшей совместимости
        config.applicationNameForUserAgent = "EggonomicsRoad/1.0"
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Убираем навигационную панель - теперь веб-вью занимает весь экран
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            // Веб-вью теперь учитывает safeArea со всех сторон
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        load(url: initialURL)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown // Портрет + альбомные
    }

    override var shouldAutorotate: Bool {
        return true
    }

    func load(url: URL) {
        print("🌍 [WebView] Loading URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        
        // Настройки для лучшей обработки редиректов
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30.0
        
        // Добавляем заголовки для лучшей совместимости
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        print("🌍 [WebView] Request headers configured for better redirect handling")
        webView.load(request)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString ?? "unknown"
        let navigationType = navigationAction.navigationType
        
        print("🌍 [WebView] Navigation to: \(url)")
        print("🌍 [WebView] Navigation type: \(navigationType.rawValue)")
        print("🌍 [WebView] Target frame is main frame: \(navigationAction.targetFrame?.isMainFrame ?? false)")
        
        // Разрешаем все типы навигации для поддержки редиректов
        switch navigationType {
        case .linkActivated:
            print("🌍 [WebView] Link activated - allowing")
        case .formSubmitted:
            print("🌍 [WebView] Form submitted - allowing")
        case .backForward:
            print("🌍 [WebView] Back/Forward navigation - allowing")
        case .reload:
            print("🌍 [WebView] Page reload - allowing")
        case .formResubmitted:
            print("🌍 [WebView] Form resubmitted - allowing")
        case .other:
            print("🌍 [WebView] Other navigation (redirect) - allowing")
        @unknown default:
            print("🌍 [WebView] Unknown navigation type - allowing")
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🌍 [WebView] Started loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌍 [WebView] Finished loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Provisional navigation failed: \(error.localizedDescription)")
        
        // Дополнительная информация об ошибке
        let nsError = error as NSError
        print("❌ [WebView] Error domain: \(nsError.domain)")
        print("❌ [WebView] Error code: \(nsError.code)")
        
        // Обрабатываем специфические ошибки
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorServerCertificateUntrusted:
                print("❌ [WebView] SSL certificate issue")
            case NSURLErrorCannotFindHost:
                print("❌ [WebView] Cannot find host")
            case NSURLErrorTimedOut:
                print("❌ [WebView] Request timed out")
            case NSURLErrorNotConnectedToInternet:
                print("❌ [WebView] No internet connection")
            default:
                print("❌ [WebView] Other URL error: \(nsError.code)")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("🔄 [WebView] Server redirect received to: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("🌍 [WebView] Navigation committed to: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Обновляем layout веб-вью при изменении ориентации
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Обрабатываем попытки открыть новые окна - перенаправляем в текущий WebView
        print("🌍 [WebView] Attempting to create new window for: \(navigationAction.request.url?.absoluteString ?? "unknown")")
        print("🌍 [WebView] Redirecting to current WebView instead")
        
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        
        return nil
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("🌍 [WebView] Response from: \(navigationResponse.response.url?.absoluteString ?? "unknown")")
        print("🌍 [WebView] Status code: \((navigationResponse.response as? HTTPURLResponse)?.statusCode ?? 0)")
        print("🌍 [WebView] Can show MIME type: \(navigationResponse.canShowMIMEType)")
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        // Обрабатываем JavaScript алерты
        print("🌍 [WebView] JavaScript alert: \(message)")
        
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        // Обрабатываем JavaScript подтверждения
        print("🌍 [WebView] JavaScript confirm: \(message)")
        
        let alert = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        
        present(alert, animated: true)
    }
}
