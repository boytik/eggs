//import UIKit
//
//class EggLoadingViewController: UIViewController {
//    
//    private let eggView = EggView()
//    private let loadingLabel = UILabel()
//    private let progressView = CustomProgressView()
//    
//    private var progress: Float = 0.0
//    private var progressTimer: Timer?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupGradientBackground()
//        setupUI()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        startAnimations()
//        startLoadingSimulation()
//    }
//    
//    // MARK: - Setup
//    
//    private func setupGradientBackground() {
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.frame = view.bounds
//        gradientLayer.colors = [
//            UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1.0).cgColor,
//            UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0).cgColor,
//            UIColor(red: 0.95, green: 0.65, blue: 0.1, alpha: 1.0).cgColor
//        ]
//        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
//        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
//        view.layer.insertSublayer(gradientLayer, at: 0)
//    }
//    
//    private func setupUI() {
//        // Egg View
//        eggView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(eggView)
//        
//        // Loading Label
//        loadingLabel.text = "LOADING..."
//        loadingLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
//        loadingLabel.textColor = .white
//        loadingLabel.textAlignment = .center
//        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(loadingLabel)
//        
//        // Progress View
//        progressView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(progressView)
//        
//        // Constraints
//        NSLayoutConstraint.activate([
//            // Egg in center
//            eggView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            eggView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            eggView.widthAnchor.constraint(equalToConstant: 120),
//            eggView.heightAnchor.constraint(equalToConstant: 150),
//            
//            // Loading label
//            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loadingLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -12),
//            
//            // Progress view
//            progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            progressView.widthAnchor.constraint(equalToConstant: 250),
//            progressView.heightAnchor.constraint(equalToConstant: 8),
//            progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
//        ])
//    }
//    
//    // MARK: - Animations
//    
//    private func startAnimations() {
//        // Rotation animation (rocking)
//        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
//        rotationAnimation.values = [0, 0.087, 0, -0.087, 0] // ±5 degrees in radians
//        rotationAnimation.keyTimes = [0, 0.25, 0.5, 0.75, 1.0]
//        rotationAnimation.duration = 1.5
//        rotationAnimation.repeatCount = .infinity
//        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        eggView.layer.add(rotationAnimation, forKey: "rotation")
//        
//        // Scale animation (pulsing)
//        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
//        scaleAnimation.values = [1.0, 1.1, 1.0]
//        scaleAnimation.keyTimes = [0, 0.5, 1.0]
//        scaleAnimation.duration = 1.2
//        scaleAnimation.repeatCount = .infinity
//        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        eggView.layer.add(scaleAnimation, forKey: "scale")
//        
//        // Bounce animation (up and down)
//        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
//        bounceAnimation.values = [0, -10, 0]
//        bounceAnimation.keyTimes = [0, 0.5, 1.0]
//        bounceAnimation.duration = 1.0
//        bounceAnimation.repeatCount = .infinity
//        bounceAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
//        eggView.layer.add(bounceAnimation, forKey: "bounce")
//    }
//    
//    // MARK: - Loading Simulation
//    
//    private func startLoadingSimulation() {
//        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
//            guard let self = self else { return }
//            if self.progress < 1.0 {
//                self.progress += 0.01
//                self.progressView.setProgress(self.progress, animated: true)
//            } else {
//                timer.invalidate()
//            }
//        }
//    }
//    
//    deinit {
//        progressTimer?.invalidate()
//    }
//}
//
//// MARK: - Egg View
//
//class EggView: UIView {
//    
//    private let shadowLayer = CAShapeLayer()
//    private let eggLayer = CAGradientLayer()
//    private let highlightLayer = CAGradientLayer()
//    private let strokeLayer = CAShapeLayer()
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayers()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayers()
//    }
//    
//    private func setupLayers() {
//        backgroundColor = .clear
//        
//        // Shadow
//        shadowLayer.fillColor = UIColor.black.withAlphaComponent(0.2).cgColor
//        layer.addSublayer(shadowLayer)
//        
//        // Egg gradient
//        eggLayer.colors = [
//            UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0).cgColor,
//            UIColor(red: 1.0, green: 0.75, blue: 0.2, alpha: 1.0).cgColor,
//            UIColor(red: 0.95, green: 0.6, blue: 0.1, alpha: 1.0).cgColor
//        ]
//        eggLayer.startPoint = CGPoint(x: 0, y: 0)
//        eggLayer.endPoint = CGPoint(x: 1, y: 1)
//        layer.addSublayer(eggLayer)
//        
//        // Highlight
//        highlightLayer.colors = [
//            UIColor.white.withAlphaComponent(0.6).cgColor,
//            UIColor.white.withAlphaComponent(0.3).cgColor,
//            UIColor.clear.cgColor
//        ]
//        highlightLayer.type = .radial
//        highlightLayer.startPoint = CGPoint(x: 0.3, y: 0.3)
//        highlightLayer.endPoint = CGPoint(x: 0.8, y: 0.8)
//        layer.addSublayer(highlightLayer)
//        
//        // Stroke
//        strokeLayer.fillColor = UIColor.clear.cgColor
//        strokeLayer.strokeColor = UIColor.orange.withAlphaComponent(0.8).cgColor
//        strokeLayer.lineWidth = 2
//        layer.addSublayer(strokeLayer)
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        let eggPath = createEggPath(in: bounds)
//        
//        // Shadow
//        let shadowPath = createEggPath(in: CGRect(
//            x: bounds.origin.x + 10,
//            y: bounds.origin.y + 5,
//            width: bounds.width - 20,
//            height: bounds.height - 10
//        ))
//        shadowLayer.path = shadowPath.cgPath
//        
//        // Egg
//        eggLayer.frame = bounds
//        let eggMask = CAShapeLayer()
//        eggMask.path = eggPath.cgPath
//        eggLayer.mask = eggMask
//        
//        // Highlight
//        highlightLayer.frame = bounds
//        let highlightMask = CAShapeLayer()
//        highlightMask.path = eggPath.cgPath
//        highlightLayer.mask = highlightMask
//        
//        // Stroke
//        strokeLayer.path = eggPath.cgPath
//    }
//    
//    private func createEggPath(in rect: CGRect) -> UIBezierPath {
//        let path = UIBezierPath()
//        let width = rect.width
//        let height = rect.height
//        
//        // Start at top
//        path.move(to: CGPoint(x: width / 2, y: 0))
//        
//        // Top curve (sharper)
//        path.addCurve(
//            to: CGPoint(x: width, y: height * 0.6),
//            controlPoint1: CGPoint(x: width * 0.85, y: height * 0.15),
//            controlPoint2: CGPoint(x: width, y: height * 0.35)
//        )
//        
//        // Bottom right curve (rounder)
//        path.addCurve(
//            to: CGPoint(x: width / 2, y: height),
//            controlPoint1: CGPoint(x: width, y: height * 0.85),
//            controlPoint2: CGPoint(x: width * 0.75, y: height)
//        )
//        
//        // Bottom left curve
//        path.addCurve(
//            to: CGPoint(x: 0, y: height * 0.6),
//            controlPoint1: CGPoint(x: width * 0.25, y: height),
//            controlPoint2: CGPoint(x: 0, y: height * 0.85)
//        )
//        
//        // Top left curve
//        path.addCurve(
//            to: CGPoint(x: width / 2, y: 0),
//            controlPoint1: CGPoint(x: 0, y: height * 0.35),
//            controlPoint2: CGPoint(x: width * 0.15, y: height * 0.15)
//        )
//        
//        path.close()
//        return path
//    }
//}
//
//// MARK: - Custom Progress View
//
//class CustomProgressView: UIView {
//    
//    private let backgroundLayer = CAShapeLayer()
//    private let progressLayer = CAGradientLayer()
//    private var progressMask = CAShapeLayer()
//    
//    private var currentProgress: Float = 0.0
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupLayers()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupLayers()
//    }
//    
//    private func setupLayers() {
//        // Background
//        backgroundLayer.fillColor = UIColor.white.withAlphaComponent(0.3).cgColor
//        layer.addSublayer(backgroundLayer)
//        
//        // Progress gradient
//        progressLayer.colors = [
//            UIColor.white.cgColor,
//            UIColor.white.withAlphaComponent(0.8).cgColor
//        ]
//        progressLayer.startPoint = CGPoint(x: 0, y: 0.5)
//        progressLayer.endPoint = CGPoint(x: 1, y: 0.5)
//        progressLayer.mask = progressMask
//        layer.addSublayer(progressLayer)
//    }
//    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        let path = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2)
//        backgroundLayer.path = path.cgPath
//        
//        progressLayer.frame = bounds
//        updateProgress()
//    }
//    
//    func setProgress(_ progress: Float, animated: Bool) {
//        currentProgress = min(max(progress, 0.0), 1.0)
//        updateProgress()
//    }
//    
//    private func updateProgress() {
//        let progressWidth = bounds.width * CGFloat(currentProgress)
//        let progressRect = CGRect(x: 0, y: 0, width: progressWidth, height: bounds.height)
//        let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: bounds.height / 2)
//        
//        progressMask.path = progressPath.cgPath
//    }
//}
