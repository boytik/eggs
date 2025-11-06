import UIKit

class CustomProgressView: UIView {
    
    private let backgroundLayer = CALayer()
    private let progressLayer = CAGradientLayer()
    private var _progress: Float = 0.0
    
    var progress: Float {
        get { return _progress }
        set { setProgress(newValue, animated: false) }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupProgressView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupProgressView()
    }
    
    private func setupProgressView() {
        backgroundColor = .clear
        
        // Background layer
        backgroundLayer.backgroundColor = UIColor.black.withAlphaComponent(0.2).cgColor
        backgroundLayer.cornerRadius = 4
        layer.addSublayer(backgroundLayer)
        
        // Progress layer with gradient
        progressLayer.colors = [
            UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0).cgColor,
            UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1.0).cgColor
        ]
        progressLayer.startPoint = CGPoint(x: 0, y: 0.5)
        progressLayer.endPoint = CGPoint(x: 1, y: 0.5)
        progressLayer.cornerRadius = 4
        progressLayer.masksToBounds = true
        
        // Add glow effect
        progressLayer.shadowColor = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0).cgColor
        progressLayer.shadowOffset = CGSize.zero
        progressLayer.shadowRadius = 4
        progressLayer.shadowOpacity = 0.8
        
        layer.addSublayer(progressLayer)
        
        updateProgressLayer()
    }
    
    func setProgress(_ progress: Float, animated: Bool) {
        let clampedProgress = max(0.0, min(1.0, progress))
        _progress = clampedProgress
        
        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.2)
            CATransaction.setAnimationTimingFunction(
                CAMediaTimingFunction(name: .easeInEaseOut)
            )
            updateProgressLayer()
            CATransaction.commit()
        } else {
            updateProgressLayer()
        }
    }
    
    private func updateProgressLayer() {
        let progressWidth = bounds.width * CGFloat(_progress)
        progressLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: progressWidth,
            height: bounds.height
        )
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundLayer.frame = bounds
        updateProgressLayer()
        
        // Update corner radius based on height
        let cornerRadius = bounds.height / 2
        backgroundLayer.cornerRadius = cornerRadius
        progressLayer.cornerRadius = cornerRadius
    }
}

