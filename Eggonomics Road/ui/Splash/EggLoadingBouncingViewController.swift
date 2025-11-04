import UIKit

class EggLoadingBouncingViewController: UIViewController {
    
    private let particlesContainerView = UIView()
    private let shadowView = UIView()
    private let eggView = EggView()
    private let loadingLabel = UILabel()
    private let progressView = CustomProgressView()
    
    private var progress: Float = 0.0
    private var progressTimer: Timer?
    private var particleViews: [UIView] = []
    private var shouldAutoTransition = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
        setupParticles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
        startLoadingSimulation()
    }
    
    // MARK: - Orientation Support
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown // Поддерживает все ориентации кроме перевернутой
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // Обновляем градиент при повороте
            if let gradientLayer = self.view.layer.sublayers?.first as? CAGradientLayer {
                gradientLayer.frame = CGRect(origin: .zero, size: size)
            }
        }, completion: nil)
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
    }
    
    private func setupUI() {
        // Container for animations
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Particles container
        particlesContainerView.backgroundColor = .clear
        particlesContainerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(particlesContainerView)
        
        // Shadow
        shadowView.backgroundColor = .black
        shadowView.alpha = 0.2
        shadowView.layer.cornerRadius = 40
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(shadowView)
        
        // Egg
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
        
        // Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 240),
            containerView.heightAnchor.constraint(equalToConstant: 240),
            
            // Particles
            particlesContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            particlesContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            particlesContainerView.widthAnchor.constraint(equalToConstant: 240),
            particlesContainerView.heightAnchor.constraint(equalToConstant: 240),
            
            // Shadow
            shadowView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            shadowView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: 90),
            shadowView.widthAnchor.constraint(equalToConstant: 80),
            shadowView.heightAnchor.constraint(equalToConstant: 20),
            
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
            progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
    }
    
    private func setupParticles() {
        for i in 0..<8 {
            let particle = UIView()
            particle.backgroundColor = .white
            particle.alpha = 0.6
            particle.layer.cornerRadius = 4
            particle.translatesAutoresizingMaskIntoConstraints = false
            particlesContainerView.addSubview(particle)
            
            let angle = Double(i) * .pi / 4
            let radius: CGFloat = 80
            let x = cos(angle) * Double(radius) + 120
            let y = sin(angle) * Double(radius) + 120
            
            NSLayoutConstraint.activate([
                particle.widthAnchor.constraint(equalToConstant: 8),
                particle.heightAnchor.constraint(equalToConstant: 8),
                particle.centerXAnchor.constraint(equalTo: particlesContainerView.leadingAnchor, constant: x),
                particle.centerYAnchor.constraint(equalTo: particlesContainerView.topAnchor, constant: y)
            ])
            
            particleViews.append(particle)
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        startBounceAnimation()
        startParticlesAnimation()
    }
    
    private func startBounceAnimation() {
        // Create bounce sequence
        let bounceUp = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounceUp.values = [0, -50]
        bounceUp.keyTimes = [0, 1]
        bounceUp.duration = 0.3
        bounceUp.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let bounceDown = CAKeyframeAnimation(keyPath: "transform.translation.y")
        bounceDown.values = [-50, 0]
        bounceDown.keyTimes = [0, 1]
        bounceDown.duration = 0.3
        bounceDown.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        // Squash animation
        let normalScale = CAKeyframeAnimation(keyPath: "transform.scale")
        normalScale.values = [1.0, 1.0]
        normalScale.duration = 0.3
        
        let squashScale = CAKeyframeAnimation(keyPath: "transform.scale")
        squashScale.values = [
            [1.0, 1.0],
            [1.0, 0.9]
        ]
        squashScale.keyTimes = [0, 1]
        squashScale.duration = 0.3
        
        // Perform bounce cycle
        performBounceSequence()
    }
    
    private func performBounceSequence() {
        // Phase 1: Jump up
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.eggView.transform = CGAffineTransform(translationX: 0, y: -50)
            self.eggView.transform = self.eggView.transform.scaledBy(x: 1.0, y: 1.0)
        }, completion: { _ in
            // Phase 2: Fall down
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
                self.eggView.transform = CGAffineTransform(translationX: 0, y: 0)
                    .scaledBy(x: 1.0, y: 0.9)
            }, completion: { _ in
                // Phase 3: Bounce back to normal
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
                    self.eggView.transform = .identity
                }, completion: { _ in
                    // Repeat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.performBounceSequence()
                    }
                })
            })
        })
        
        // Animate shadow in sync
        animateShadow()
    }
    
    private func animateShadow() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.shadowView.transform = CGAffineTransform(scaleX: 1.3, y: 1.0)
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
                self.shadowView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut], animations: {
                    self.shadowView.transform = .identity
                })
            })
        })
    }
    
    private func startParticlesAnimation() {
        let particlesAnimation = CAKeyframeAnimation(keyPath: "opacity")
        particlesAnimation.values = [0.3, 1.0, 0.3]
        particlesAnimation.keyTimes = [0, 0.5, 1.0]
        particlesAnimation.duration = 0.8
        particlesAnimation.repeatCount = .infinity
        particlesAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        particlesContainerView.layer.add(particlesAnimation, forKey: "particlesPulse")
    }
    
    // MARK: - Loading Simulation
    
    private func startLoadingSimulation() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            if self.progress < 1.0 {
                self.progress += 0.01
                self.progressView.setProgress(self.progress, animated: true)
            } else {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func disableAutoTransition() {
        shouldAutoTransition = false
    }
    
    deinit {
        progressTimer?.invalidate()
    }
}
