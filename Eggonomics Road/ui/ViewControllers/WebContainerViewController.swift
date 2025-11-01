import UIKit
import WebKit

final class WebContainerViewController: UIViewController, WKNavigationDelegate {
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
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // Navigation bar
        let navBar = UIView()
        navBar.backgroundColor = .black
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        let backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        let refreshButton = UIButton(type: .system)
        refreshButton.setTitle("↻ Refresh", for: .normal)
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(navBar)
        view.addSubview(webView)
        navBar.addSubview(backButton)
        navBar.addSubview(refreshButton)
        
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 70),
            
            backButton.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            
            refreshButton.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -16),
            refreshButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            
            webView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
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
        print("🌍 Loading: \(url.absoluteString)")
        webView.load(URLRequest(url: url))
    }
    
    @objc private func backTapped() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func refreshTapped() {
        webView.reload()
    }
}
