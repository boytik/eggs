import UIKit

final class PushPermissionViewController: UIViewController {
    private let onAllow: () -> Void
    private let onLater: () -> Void
    
    // UI элементы
    private let backgroundImageView = UIImageView()
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let allowButton = UIButton(type: .custom)
    private let laterButton = UIButton(type: .custom)

    init(onAllow: @escaping () -> Void, onLater: @escaping () -> Void) {
        self.onAllow = onAllow
        self.onLater = onLater
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    private func setupUI() {
        // Фоновое изображение как в остальном приложении
        backgroundImageView.image = UIImage(named: "chickBGMain")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.frame = view.bounds
        view.addSubview(backgroundImageView)
        
        // Контейнер для контента
        containerView.backgroundColor = UIColor(named: "chickYellowLight") ?? UIColor.systemYellow.withAlphaComponent(0.9)
        containerView.layer.cornerRadius = 20
        containerView.layer.borderWidth = 4.0
        containerView.layer.borderColor = (UIColor(named: "chickDarkYellow") ?? UIColor.orange).cgColor
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        // Иконка уведомлений
        iconImageView.image = UIImage(systemName: "bell.fill")
        iconImageView.tintColor = UIColor(named: "chickOrange") ?? UIColor.orange
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)
        
        // Заголовок
        titleLabel.text = "🎁 Get Exclusive Bonuses!"
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 28) ?? UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(named: "chickBrown") ?? UIColor.brown
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        containerView.addSubview(titleLabel)
        
        // Подзаголовок
        subtitleLabel.text = "Enable notifications to receive special offers, bonuses, and exclusive deals directly to your device!"
        subtitleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = UIColor(named: "chickBrown") ?? UIColor.brown
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        containerView.addSubview(subtitleLabel)
        
        // Кнопка разрешить (основная)
        allowButton.setTitle("🎁 Yes, I Want Bonuses!", for: .normal)
        allowButton.titleLabel?.font = UIFont(name: "BlackHanSans-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        allowButton.setTitleColor(.white, for: .normal)
        allowButton.backgroundColor = UIColor(named: "chickOrange") ?? UIColor.orange
        allowButton.layer.cornerRadius = 25
        allowButton.layer.borderWidth = 3.0
        allowButton.layer.borderColor = (UIColor(named: "chickBrown") ?? UIColor.brown).cgColor
        allowButton.addTarget(self, action: #selector(tapAllow), for: .touchUpInside)
        view.addSubview(allowButton)
        
        // Кнопка пропустить (вторичная)
        laterButton.setTitle("Skip", for: .normal)
        laterButton.titleLabel?.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        laterButton.setTitleColor(UIColor(named: "chickBrown") ?? UIColor.brown, for: .normal)
        laterButton.backgroundColor = UIColor.clear
        laterButton.layer.cornerRadius = 20
        laterButton.layer.borderWidth = 2.0
        laterButton.layer.borderColor = (UIColor(named: "chickBrown") ?? UIColor.brown).cgColor
        laterButton.addTarget(self, action: #selector(tapLater), for: .touchUpInside)
        view.addSubview(laterButton)
        
        // Настройка анимации нажатия
        setupButtonAnimations()
    }
    
    private func setupButtonAnimations() {
        [allowButton, laterButton].forEach { button in
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        }
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.1) {
            sender.transform = CGAffineTransform.identity
        }
    }
    
    private func setupConstraints() {
        [backgroundImageView, containerView, iconImageView, titleLabel, subtitleLabel, allowButton, laterButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Фоновое изображение
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Контейнер с контентом (центр экрана)
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Иконка
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            iconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Заголовок
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Подзаголовок
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            subtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            
            // Кнопка разрешить (внизу экрана)
            allowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            allowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            allowButton.bottomAnchor.constraint(equalTo: laterButton.topAnchor, constant: -15),
            allowButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Кнопка отложить
            laterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            laterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            laterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            laterButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    @objc private func tapAllow() {
        // Анимация закрытия с эффектом
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.dismiss(animated: false)
            self.onAllow()
        }
    }
    
    @objc private func tapLater() {
        // Анимация закрытия с эффектом
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
            self.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.dismiss(animated: false)
            self.onLater()
        }
    }
}
