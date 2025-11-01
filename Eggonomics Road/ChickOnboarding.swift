import UIKit
import SnapKit

final class ChickOnboarding: UIViewController {
    
    private let backgroundImageView = UIImageView()
    private var currentImageIndex = 0
    private let images = ["chickOnbo1", "chickOnbo2"]
    
    // Gesture recognizers
    private var topRightTap: UITapGestureRecognizer!
    private var topLeftTap: UITapGestureRecognizer!
    private var bottomStartTap: UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupInteractiveZones()
        showCurrentImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // Только портрет
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
//        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = true
        view.addSubview(backgroundImageView)
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupInteractiveZones() {
        // Создаем gesture recognizers с делегатами
        topRightTap = UITapGestureRecognizer(target: self, action: #selector(topRightZoneTapped))
        topLeftTap = UITapGestureRecognizer(target: self, action: #selector(topLeftZoneTapped))
        bottomStartTap = UITapGestureRecognizer(target: self, action: #selector(startZoneTapped))
        
        // Устанавливаем делегаты
        topRightTap.delegate = self
        topLeftTap.delegate = self
        bottomStartTap.delegate = self
        
        view.addGestureRecognizer(topRightTap)
        view.addGestureRecognizer(topLeftTap)
        view.addGestureRecognizer(bottomStartTap)
    }
    
    private func showCurrentImage() {
        let imageName = images[currentImageIndex]
        backgroundImageView.image = UIImage(named: imageName)
        print("Showing image: \(imageName) at index: \(currentImageIndex)")
    }
    
    @objc private func topRightZoneTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let topRightZone = CGRect(x: view.bounds.width - 120, y: 0, width: 120, height: 100)
        
        print("TopRight tap at: \(location), zone: \(topRightZone), currentIndex: \(currentImageIndex)")
        
        if topRightZone.contains(location) && currentImageIndex == 0 {
            print("Transitioning to next image")
            currentImageIndex += 1
            animateTransition()
        }
    }
    
    @objc private func topLeftZoneTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let topLeftZone = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        print("TopLeft tap at: \(location), zone: \(topLeftZone), currentIndex: \(currentImageIndex)")
        
        if topLeftZone.contains(location) && currentImageIndex == 1 {
            print("Transitioning to previous image")
            currentImageIndex -= 1
            animateTransition()
        }
    }
    
    @objc private func startZoneTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        let bottomZone = CGRect(x: view.bounds.width/2 - 120, y: view.bounds.height - 200, width: 240, height: 150)
        
        print("Bottom tap at: \(location), zone: \(bottomZone), currentIndex: \(currentImageIndex)")
        
        if bottomZone.contains(location) && currentImageIndex == 1 {
            print("go")
            // Сохраняем флаг о прохождении onboarding
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
            // Переходим в меню
            transitionToMenu()
        }
    }
    
    private func transitionToMenu() {
        let menuVC = UINavigationController(rootViewController:  ChickTabBar())
        menuVC.modalPresentationStyle = .fullScreen
        menuVC.modalTransitionStyle = .crossDissolve
        present(menuVC, animated: true)
    }
    
    private func animateTransition() {
        UIView.transition(with: backgroundImageView, duration: 0.5, options: .transitionCrossDissolve) {
            self.showCurrentImage()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ChickOnboarding: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        
        // Проверяем, какой gesture recognizer должен сработать
        if gestureRecognizer == topRightTap {
            // Большая зона сверху справа для первой картинки
            let topRightZone = CGRect(x: view.bounds.width - 120, y: 0, width: 120, height: 100)
            return topRightZone.contains(location) && currentImageIndex == 0
        } else if gestureRecognizer == topLeftTap {
            // Зона слева сверху для второй картинки
            let topLeftZone = CGRect(x: 0, y: 0, width: 100, height: 100)
            return topLeftZone.contains(location) && currentImageIndex == 1
        } else if gestureRecognizer == bottomStartTap {
            // Зона снизу посередине для второй картинки (намного ниже)
            let bottomZone = CGRect(x: view.bounds.width/2 - 120, y: view.bounds.height - 200, width: 240, height: 150)
            return bottomZone.contains(location) && currentImageIndex == 1
        }
        
        return false
    }
}
