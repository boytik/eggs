import UIKit

class EggView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEgg()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEgg()
    }
    
    private func setupEgg() {
        backgroundColor = .clear
        
        // Создаем слой для яйца
        let eggLayer = CAShapeLayer()
        
        // Создаем путь в форме яйца
        let eggPath = createEggPath()
        eggLayer.path = eggPath.cgPath
        
        // Настраиваем градиент для яйца
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor(red: 0.95, green: 0.95, blue: 0.9, alpha: 1.0).cgColor,
            UIColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.3, y: 0.2)
        gradientLayer.endPoint = CGPoint(x: 0.7, y: 0.8)
        gradientLayer.mask = eggLayer
        
        // Добавляем тень
        eggLayer.shadowColor = UIColor.black.cgColor
        eggLayer.shadowOffset = CGSize(width: 2, height: 4)
        eggLayer.shadowOpacity = 0.2
        eggLayer.shadowRadius = 8
        
        layer.addSublayer(gradientLayer)
        
        // Добавляем блик
        addHighlight()
    }
    
    private func createEggPath() -> UIBezierPath {
        let path = UIBezierPath()
        let width: CGFloat = 120
        let height: CGFloat = 150
        
        // Создаем форму яйца с помощью кривых Безье
        path.move(to: CGPoint(x: width/2, y: 0))
        
        // Верхняя часть (более острая)
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.4),
            controlPoint1: CGPoint(x: width * 0.8, y: height * 0.1),
            controlPoint2: CGPoint(x: width, y: height * 0.25)
        )
        
        // Правая сторона
        path.addCurve(
            to: CGPoint(x: width/2, y: height),
            controlPoint1: CGPoint(x: width, y: height * 0.7),
            controlPoint2: CGPoint(x: width * 0.75, y: height)
        )
        
        // Левая сторона
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.4),
            controlPoint1: CGPoint(x: width * 0.25, y: height),
            controlPoint2: CGPoint(x: 0, y: height * 0.7)
        )
        
        // Верхняя левая часть
        path.addCurve(
            to: CGPoint(x: width/2, y: 0),
            controlPoint1: CGPoint(x: 0, y: height * 0.25),
            controlPoint2: CGPoint(x: width * 0.2, y: height * 0.1)
        )
        
        path.close()
        return path
    }
    
    private func addHighlight() {
        let highlightLayer = CAShapeLayer()
        let highlightPath = UIBezierPath(
            ovalIn: CGRect(x: 25, y: 20, width: 30, height: 40)
        )
        highlightLayer.path = highlightPath.cgPath
        highlightLayer.fillColor = UIColor.white.withAlphaComponent(0.6).cgColor
        highlightLayer.shadowColor = UIColor.clear.cgColor
        
        layer.addSublayer(highlightLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Обновляем размеры градиента при изменении размера view
        for sublayer in layer.sublayers ?? [] {
            if let gradientLayer = sublayer as? CAGradientLayer {
                gradientLayer.frame = bounds
            }
        }
    }
}




