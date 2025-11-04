import UIKit

class EggLoadingSpinningViewController: UIViewController {
    
    private let glowView = UIView()
    private let eggView = EggView()
    private let loadingLabel = UILabel()
    private let progressView = CustomProgressView()
    private let percentLabel = UILabel()
    
    private var progress: Float = 0.0
    private var progressTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
        startLoadingSimulation()
    }
    
    // MARK: - Setup
    
    private func setupGradientBackground() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 0.95, green: 0.65, blue: 0.1, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Radial gradient overlay
        let radialGradient = RadialGradientView(frame: view.bounds)
        radialGradient.alpha = 1.0
        view.addSubview(radialGradient)
    }
    
    private func setupUI() {
        // Container for glow and egg
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Glow View
        glowView.backgroundColor = .clear
        glowView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(glowView)
        
        // Egg View
        eggView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(eggView)
        
        // Loading Label
        loadingLabel.text = "LOADING..."
        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        loadingLabel.textColor = .white
        loadingLabel.textAlignment = .center
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingLabel)
        
        // Progress View
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // Percent Label
        percentLabel.text = "0%"
        percentLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        percentLabel.textColor = UIColor.white.withAlphaComponent(0.8)
        percentLabel.textAlignment = .center
        percentLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(percentLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 240),
            containerView.heightAnchor.constraint(equalToConstant: 240),
            
            // Glow
            glowView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            glowView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            glowView.widthAnchor.constraint(equalToConstant: 240),
            glowView.heightAnchor.constraint(equalToConstant: 240),
            
            // Egg
            eggView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            eggView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            eggView.widthAnchor.constraint(equalToConstant: 120),
            eggView.heightAnchor.constraint(equalToConstant: 150),
            
            // Loading label
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -12),
            
            // Progress view
            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 250),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            progressView.bottomAnchor.constraint(equalTo: percentLabel.topAnchor, constant: -8),
            
            // Percent label
            percentLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            percentLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
        
        setupGlow()
    }
    
    private func setupGlow() {
        let glowLayer = CAGradientLayer()
        glowLayer.type = .radial
        glowLayer.colors = [
            UIColor.yellow.withAlphaComponent(0.3).cgColor,
            UIColor.orange.withAlphaComponent(0.15).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        glowLayer.endPoint = CGPoint(x: 1, y: 1)
        glowLayer.frame = glowView.bounds
        glowView.layer.addSublayer(glowLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let glowLayer = glowView.layer.sublayers?.first as? CAGradientLayer {
            glowLayer.frame = glowView.bounds
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // 3D rotation animation
        var perspective = CATransform3DIdentity
        perspective.m34 = -1.0 / 500.0
        eggView.layer.transform = perspective
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.y")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = CGFloat.pi * 2
        rotationAnimation.duration = 3.0
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        eggView.layer.add(rotationAnimation, forKey: "rotation3D")
        
        // Glow pulsing animation
        let glowAnimation = CAKeyframeAnimation(keyPath: "opacity")
        glowAnimation.values = [0.3, 0.6, 0.3]
        glowAnimation.keyTimes = [0, 0.5, 1.0]
        glowAnimation.duration = 1.5
        glowAnimation.repeatCount = .infinity
        glowAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glowView.layer.add(glowAnimation, forKey: "glowPulse")
    }
    
    // MARK: - Loading Simulation
    
    private func startLoadingSimulation() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.progress < 1.0 {
                self.progress += 0.01
                self.progressView.setProgress(self.progress, animated: true)
                self.percentLabel.text = "\(Int(self.progress * 100))%"
            } else {
                timer.invalidate()
            }
        }
    }
    
    deinit {
        progressTimer?.invalidate()
    }
}

// MARK: - Radial Gradient View

class RadialGradientView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    private func setupGradient() {
        backgroundColor = .clear
        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .radial
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = bounds
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let gradientLayer = layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bounds
        }
    }
}
