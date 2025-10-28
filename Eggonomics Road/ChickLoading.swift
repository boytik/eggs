import UIKit
import SnapKit

final class ChickLoading: UIViewController {
    
    private let chickLaunch = UIImageView(image: UIImage(named: "chickLaunch"))
    private let progressLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private var progressTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chickSource()
        setupProgressComponents()
        startProgress()
    }
    
    deinit {
        progressTimer?.invalidate()
    }

    private func chickSource() {
        chickLaunch.frame = view.bounds
        chickLaunch.contentMode = .scaleAspectFill
        view.addSubview(chickLaunch)
    }
    
    private func setupProgressComponents() {
        // Настройка label
        progressLabel.text = "LOADING..."
        progressLabel.textColor = .white
        progressLabel.textAlignment = .center
        
        // Загрузка кастомного шрифта
        if let customFont = UIFont(name: "Digitalt", size: 22) {
            progressLabel.font = customFont
        } else {
            progressLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        }
        
        // Настройка progress view
        progressView.progressTintColor = UIColor(named: "chickYellow")
        progressView.trackTintColor = .white.withAlphaComponent(0.30)
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        
        // Добавление компонентов на view
        view.addSubview(progressLabel)
        view.addSubview(progressView)
        
        // Настройка constraints
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(progressView.snp.top).offset(-12)
        }
        
        progressView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-5)
            make.width.equalTo(231)
            make.height.equalTo(12)
        }
    }
    
    private func startProgress() {
        var progress: Float = 0.0
        // Ускоряем прогрузку - уменьшаем интервал и увеличиваем шаг
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            progress += 0.05
            
            DispatchQueue.main.async {
                self?.progressView.setProgress(progress, animated: true)
            }
            
            if progress >= 1.0 {
                timer.invalidate()
                self?.checkOnboardingStatus()
            }
        }
    }
    
    private func checkOnboardingStatus() {
        // Проверяем, проходил ли пользователь onboarding
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        if hasSeenOnboarding {
            // Если уже проходил onboarding, показываем меню
            transitionToMenu()
        } else {
            // Если не проходил, показываем onboarding
            transitionToOnboarding()
        }
    }
    
    private func transitionToMenu() {
        let menuVC = UINavigationController(rootViewController:  ChickTabBar())
        menuVC.modalPresentationStyle = .fullScreen
        menuVC.modalTransitionStyle = .crossDissolve
        present(menuVC, animated: true)
    }
    
    private func transitionToOnboarding() {
        let onboardingVC = UINavigationController(rootViewController:  ChickOnboarding())
        onboardingVC.modalPresentationStyle = .fullScreen
        onboardingVC.modalTransitionStyle = .crossDissolve
        present(onboardingVC, animated: true)
    }
}

