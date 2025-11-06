import UIKit
import WebKit
import UniformTypeIdentifiers

final class WebContainerViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView!
    private var initialURL: URL
    private var lastRedirectURL: URL?
    private var redirectCount = 0
    private let maxRedirects = 20
    private var fileUploadCompletionHandler: (([URL]?) -> Void)?
    
    // Navigation UI
    private var backButton: UIButton!
    private var forwardButton: UIButton!
    private var refreshButton: UIButton!
    private var navigationContainer: UIView!
    private var isNavigationVisible = false

    init(initialURL: URL) {
        self.initialURL = initialURL
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🌍 [WebView] viewDidLoad started")
        view.backgroundColor = .black
        
        let config = WKWebViewConfiguration()
        
        // 1. Полная поддержка JavaScript
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // 2. Поддержка inline autoplay video
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        
        // 3. Поддержка Cookie и сессий
        let dataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = dataStore
        
        // 4. Настройки для редиректов
        if #available(iOS 14.0, *) {
            config.limitsNavigationsToAppBoundDomains = false
        }
        
        // 5. User Content Controller для JavaScript injection
        let userContentController = WKUserContentController()
        config.userContentController = userContentController
        
        // 6. JavaScript для отладки кликов и навигации
        let debugJS = """
        console.log('WebView JavaScript loaded');
        document.addEventListener('click', function(e) {
            console.log('Click detected on:', e.target.tagName, e.target.type);
        });
        """
        let debugScript = WKUserScript(source: debugJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(debugScript)
        
        // 7. JavaScript для обработки file input
        let fileUploadJS = """
        document.addEventListener('change', function(e) {
            if (e.target && e.target.type === 'file') {
                console.log('File input detected');
                // Trigger file upload через prompt
                var result = prompt('file_upload_request', '');
                if (result && result !== '') {
                    // Создаем fake file для input
                    var dt = new DataTransfer();
                    var file = new File([''], result.split('/').pop(), {type: 'application/octet-stream'});
                    dt.items.add(file);
                    e.target.files = dt.files;
                    
                    // Trigger change event
                    var changeEvent = new Event('change', {bubbles: true});
                    e.target.dispatchEvent(changeEvent);
                }
            }
        });
        """
        let fileUploadScript = WKUserScript(source: fileUploadJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(fileUploadScript)
        
        print("🌍 [WebView] Full configuration created with all features")
        
        print("🌍 [WebView] Creating WKWebView with configuration...")
        webView = WKWebView(frame: .zero, configuration: config)
        print("🌍 [WebView] WKWebView created successfully")
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        print("🌍 [WebView] WebView delegates and properties configured")
        
        // Убираем навигационную панель - теперь веб-вью занимает весь экран
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            // Веб-вью теперь учитывает safeArea со всех сторон
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        print("🌍 [WebView] Setup complete, loading initial URL...")
        load(url: initialURL)
        print("🌍 [WebView] viewDidLoad completed")
        
        // Настройка наблюдателей за клавиатурой
        setupKeyboardObservers()
        
        // Настройка навигации
        setupNavigationControls()
        setupGestures()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Keyboard Handling
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        print("⌨️ [WebView] Keyboard will show, height: \(keyboardFrame.height)")
        
        // Получаем высоту клавиатуры с учетом safe area
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        
        // Анимируем изменение constraints
        UIView.animate(withDuration: animationDuration) {
            // Добавляем отступ снизу для WebView
            self.webView.scrollView.contentInset.bottom = keyboardHeight
            self.webView.scrollView.scrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        print("⌨️ [WebView] Keyboard will hide")
        
        // Анимируем возврат к исходному состоянию
        UIView.animate(withDuration: animationDuration) {
            self.webView.scrollView.contentInset.bottom = 0
            self.webView.scrollView.scrollIndicatorInsets.bottom = 0
        }
    }
    
    // MARK: - Navigation Setup
    
    private func setupNavigationControls() {
        // Контейнер для навигационных кнопок
        navigationContainer = UIView()
        navigationContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        navigationContainer.layer.cornerRadius = 25
        navigationContainer.translatesAutoresizingMaskIntoConstraints = false
        navigationContainer.alpha = 0 // Изначально скрыт
        view.addSubview(navigationContainer)
        
        // Кнопка "Назад"
        backButton = createNavigationButton(systemName: "chevron.left", action: #selector(goBack))
        
        // Кнопка "Вперед"
        forwardButton = createNavigationButton(systemName: "chevron.right", action: #selector(goForward))
        
        // Кнопка "Обновить"
        refreshButton = createNavigationButton(systemName: "arrow.clockwise", action: #selector(refresh))
        
        // Добавляем кнопки в контейнер
        let stackView = UIStackView(arrangedSubviews: [backButton, forwardButton, refreshButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        navigationContainer.addSubview(stackView)
        
        // Constraints для контейнера
        NSLayoutConstraint.activate([
            navigationContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            navigationContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            navigationContainer.heightAnchor.constraint(equalToConstant: 50),
            navigationContainer.widthAnchor.constraint(equalToConstant: 180)
        ])
        
        // Constraints для stack view
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: navigationContainer.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: navigationContainer.bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: navigationContainer.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: navigationContainer.trailingAnchor, constant: -20)
        ])
        
        print("🧭 [Navigation] Controls created")
    }
    
    private func createNavigationButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем анимацию нажатия
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        return button
    }
    
    private func setupGestures() {
        // Жест для показа/скрытия навигации (двойной тап)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(toggleNavigation))
        doubleTap.numberOfTapsRequired = 2
        webView.addGestureRecognizer(doubleTap)
        
        // Жест свайпа влево (назад)
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeBack))
        swipeLeft.direction = .right
        swipeLeft.numberOfTouchesRequired = 2 // Двумя пальцами
        webView.addGestureRecognizer(swipeLeft)
        
        // Жест свайпа вправо (вперед)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeForward))
        swipeRight.direction = .left
        swipeRight.numberOfTouchesRequired = 2 // Двумя пальцами
        webView.addGestureRecognizer(swipeRight)
        
        // Долгое нажатие для обновления
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressRefresh))
        longPress.minimumPressDuration = 1.0
        webView.addGestureRecognizer(longPress)
        
        print("🧭 [Navigation] Gestures configured")
    }
    
    // MARK: - Navigation Actions
    
    @objc private func goBack() {
        print("🧭 [Navigation] Going back")
        if webView.canGoBack {
            webView.goBack()
            updateNavigationButtons()
        }
    }
    
    @objc private func goForward() {
        print("🧭 [Navigation] Going forward")
        if webView.canGoForward {
            webView.goForward()
            updateNavigationButtons()
        }
    }
    
    @objc private func refresh() {
        print("🧭 [Navigation] Refreshing")
        webView.reload()
    }
    
    @objc private func toggleNavigation() {
        print("🧭 [Navigation] Toggling navigation visibility")
        isNavigationVisible.toggle()
        
        UIView.animate(withDuration: 0.3) {
            self.navigationContainer.alpha = self.isNavigationVisible ? 1.0 : 0.0
        }
        
        updateNavigationButtons()
        
        // Автоматически скрываем через 5 секунд
        if isNavigationVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if self.isNavigationVisible {
                    self.hideNavigation()
                }
            }
        }
    }
    
    @objc private func swipeBack() {
        print("🧭 [Navigation] Swipe back gesture")
        goBack()
        showNavigationTemporarily()
    }
    
    @objc private func swipeForward() {
        print("🧭 [Navigation] Swipe forward gesture")
        goForward()
        showNavigationTemporarily()
    }
    
    @objc private func longPressRefresh(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            print("🧭 [Navigation] Long press refresh")
            refresh()
            showNavigationTemporarily()
        }
    }
    
    @objc private func buttonTouchDown(_ button: UIButton) {
        UIView.animate(withDuration: 0.1) {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }
    }
    
    @objc private func buttonTouchUp(_ button: UIButton) {
        UIView.animate(withDuration: 0.1) {
            button.transform = CGAffineTransform.identity
        }
    }
    
    private func updateNavigationButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        
        backButton.alpha = webView.canGoBack ? 1.0 : 0.5
        forwardButton.alpha = webView.canGoForward ? 1.0 : 0.5
        
        print("🧭 [Navigation] Buttons updated - Back: \(webView.canGoBack), Forward: \(webView.canGoForward)")
    }
    
    private func showNavigationTemporarily() {
        if !isNavigationVisible {
            isNavigationVisible = true
            UIView.animate(withDuration: 0.3) {
                self.navigationContainer.alpha = 1.0
            }
            updateNavigationButtons()
            
            // Скрываем через 3 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.hideNavigation()
            }
        }
    }
    
    private func hideNavigation() {
        if isNavigationVisible {
            isNavigationVisible = false
            UIView.animate(withDuration: 0.3) {
                self.navigationContainer.alpha = 0.0
            }
        }
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
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        print("🌍 [WebView] Load request sent")
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        let urlString = url.absoluteString
        let navigationType = navigationAction.navigationType
        
        print("🌍 [WebView] Navigation to: \(urlString)")
        print("🌍 [WebView] Navigation type: \(navigationType.rawValue)")
        print("🌍 [WebView] Target frame is main frame: \(navigationAction.targetFrame?.isMainFrame ?? false)")
        
        // Обработка диплинков
        if isDeepLink(url: url) {
            print("🔗 [WebView] Deep link detected: \(urlString)")
            handleDeepLink(url: url)
            decisionHandler(.cancel)
            return
        }
        
        // Обработка отсутствующих target frames (часто для JavaScript кнопок)
        if navigationAction.targetFrame == nil {
            print("🌍 [WebView] No target frame - loading in main frame")
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }
        
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
            print("🌍 [WebView] Other navigation (JavaScript/redirect) - allowing")
        @unknown default:
            print("🌍 [WebView] Unknown navigation type - allowing")
        }
        
        decisionHandler(.allow)
    }
    
    // MARK: - Deep Link Handling
    
    private func isDeepLink(url: URL) -> Bool {
        let scheme = url.scheme?.lowercased() ?? ""
        
        // Проверяем на диплинки (не http/https)
        if scheme != "http" && scheme != "https" {
            return true
        }
        
        // Проверяем на специальные домены
        let host = url.host?.lowercased() ?? ""
        let deepLinkHosts = ["itunes.apple.com", "apps.apple.com", "play.google.com", "market.android.com"]
        
        return deepLinkHosts.contains(host)
    }
    
    private func handleDeepLink(url: URL) {
        print("🔗 [WebView] Handling deep link: \(url.absoluteString)")
        
        // Открываем диплинк в системе
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                print("🔗 [WebView] Deep link opened: \(success)")
                
                // Возвращаемся на предыдущую страницу после открытия диплинка
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if self.webView.canGoBack {
                        print("🔗 [WebView] Going back after deep link")
                        self.webView.goBack()
                    }
                }
            }
        } else {
            print("❌ [WebView] Cannot open deep link: \(url.absoluteString)")
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🌍 [WebView] Started loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌍 [WebView] Finished loading: \(webView.url?.absoluteString ?? "unknown")")
        updateNavigationButtons()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ [WebView] Provisional navigation failed: \(error.localizedDescription)")
        
        let nsError = error as NSError
        print("❌ [WebView] Error domain: \(nsError.domain)")
        print("❌ [WebView] Error code: \(nsError.code)")
        
        // Обработка ERR_TOO_MANY_REDIRECTS
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorHTTPTooManyRedirects {
            print("🔄 [WebView] Too many redirects detected - attempting recovery")
            
            if let url = lastRedirectURL {
                print("🔄 [WebView] Loading last redirect URL: \(url.absoluteString)")
                let request = URLRequest(url: url)
                webView.load(request)
                return
            } else if redirectCount > 0 {
                print("🔄 [WebView] Loading initial URL as fallback")
                let request = URLRequest(url: initialURL)
                webView.load(request)
                return
            }
        }
        
        // Обрабатываем другие специфические ошибки
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
        let currentURL = webView.url?.absoluteString ?? "unknown"
        redirectCount += 1
        lastRedirectURL = webView.url
        
        print("🔄 [WebView] Server redirect #\(redirectCount) received to: \(currentURL)")
        
        if redirectCount > maxRedirects {
            print("⚠️ [WebView] Too many redirects (\(redirectCount)), may hit limit soon")
        }
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
    
    // MARK: - Media Permissions
    
    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        print("🎥 [WebView] Media capture permission requested for: \(origin.host)")
        print("🎥 [WebView] Media type: \(type.rawValue)")
        
        // Автоматически разрешаем доступ к медиа
        decisionHandler(.grant)
        print("🎥 [WebView] Media permission granted automatically")
    }
    
    @available(iOS 14.5, *)
    func webView(_ webView: WKWebView, requestDeviceOrientationAndMotionPermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        print("📱 [WebView] Device orientation permission requested for: \(origin.host)")
        
        // Автоматически разрешаем доступ к ориентации устройства
        decisionHandler(.grant)
        print("📱 [WebView] Device orientation permission granted automatically")
    }
    
    // MARK: - File Upload Support
    
    // Универсальная обработка file upload через JavaScript injection
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        // Проверяем наш специальный запрос на загрузку файла
        if prompt == "file_upload_request" {
            print("📁 [WebView] File upload requested via JavaScript injection")
            
            // Конвертируем в file upload completionHandler
            let fileCompletionHandler: ([URL]?) -> Void = { urls in
                if let firstURL = urls?.first {
                    completionHandler(firstURL.absoluteString)
                } else {
                    completionHandler("")
                }
            }
            
            presentFileUploadOptions(allowsMultipleSelection: false, completionHandler: fileCompletionHandler)
            return
        }
        
        // Проверяем общие ключевые слова для file upload
        if prompt.lowercased().contains("file") || prompt.lowercased().contains("upload") {
            print("📁 [WebView] File upload detected via generic prompt")
            
            let fileCompletionHandler: ([URL]?) -> Void = { urls in
                if let firstURL = urls?.first {
                    completionHandler(firstURL.absoluteString)
                } else {
                    completionHandler(nil)
                }
            }
            
            presentFileUploadOptions(allowsMultipleSelection: false, completionHandler: fileCompletionHandler)
            return
        }
        
        // Обычный JavaScript prompt
        let alert = UIAlertController(title: "Input", message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        present(alert, animated: true)
    }
    
    private func presentFileUploadOptions(allowsMultipleSelection: Bool, completionHandler: @escaping ([URL]?) -> Void) {
        let alertController = UIAlertController(title: "Select Source", message: "Choose how to upload files", preferredStyle: .actionSheet)
        
        // Camera option
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                self.presentImagePicker(sourceType: .camera, completionHandler: completionHandler)
            })
        }
        
        // Photo Library option
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alertController.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
                self.presentImagePicker(sourceType: .photoLibrary, completionHandler: completionHandler)
            })
        }
        
        // Document picker option
        alertController.addAction(UIAlertAction(title: "Files", style: .default) { _ in
            self.presentDocumentPicker(allowsMultipleSelection: allowsMultipleSelection, completionHandler: completionHandler)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        
        // For iPad
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = webView
            popover.sourceRect = CGRect(x: webView.bounds.midX, y: webView.bounds.midY, width: 0, height: 0)
        }
        
        present(alertController, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType, completionHandler: @escaping ([URL]?) -> Void) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        
        // Store completion handler for later use
        self.fileUploadCompletionHandler = completionHandler
        
        present(picker, animated: true)
    }
    
    private func presentDocumentPicker(allowsMultipleSelection: Bool = true, completionHandler: @escaping ([URL]?) -> Void) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = self
        picker.allowsMultipleSelection = allowsMultipleSelection
        
        // Store completion handler for later use
        self.fileUploadCompletionHandler = completionHandler
        
        present(picker, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension WebContainerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            fileUploadCompletionHandler?(nil)
            return
        }
        
        // Save image to temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "upload_\(Date().timeIntervalSince1970).jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: fileURL)
                print("📁 [WebView] Image saved to: \(fileURL.path)")
                fileUploadCompletionHandler?([fileURL])
            } else {
                fileUploadCompletionHandler?(nil)
            }
        } catch {
            print("❌ [WebView] Failed to save image: \(error)")
            fileUploadCompletionHandler?(nil)
        }
        
        fileUploadCompletionHandler = nil
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        fileUploadCompletionHandler?(nil)
        fileUploadCompletionHandler = nil
    }
}

// MARK: - UIDocumentPickerDelegate

extension WebContainerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("📁 [WebView] Documents selected: \(urls.count)")
        fileUploadCompletionHandler?(urls)
        fileUploadCompletionHandler = nil
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("📁 [WebView] Document picker cancelled")
        fileUploadCompletionHandler?(nil)
        fileUploadCompletionHandler = nil
    }
}
