//
//  ChickInfo.swift
//  Eggonomics Road
//
//  Created by Ravil on 22.10.2025.
//

import UIKit
import SnapKit

final class ChickInfo: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    // Система прогресса
    private var currentXP: Int = 0
    private var currentLevel: Int = 1
    private var progressView: UIProgressView?
    private var progressValueLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        
        loadProgress()
        setupNavigationBar()
        setupUI()
        setupScrollView()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // Только портрет
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем прогресс
        loadProgress()
        updateProgressDisplay()
        // Запускаем анимацию карточек при каждом появлении экрана
        DispatchQueue.main.async {
            self.animateCards()
        }
    }
    
    private func animateCards() {
        let cards = stackView.arrangedSubviews
        for (index, card) in cards.enumerated() {
            card.alpha = 0
            card.transform = CGAffineTransform(translationX: 0, y: 50)
            
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                card.alpha = 1
                card.transform = .identity
            }
        }
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.backgroundColor = .white
        }
        
        navigationController?.navigationBar.barStyle = .default
        setNeedsStatusBarAppearanceUpdate()
        
        let statusLabel = UILabel()
        statusLabel.text = "Info"
        statusLabel.textColor = UIColor(named: "chickBrown")
        statusLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24)
        statusLabel.textAlignment = .center
        navigationItem.titleView = statusLabel
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
    }
    
    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    private func createCards() {
        createToNextLevelCard()
        createStatusCard()
        createDescriptionCard()
        createDisclaimerButton()
    }
    
    private func createToNextLevelCard() {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(named: "cardGray")
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 4
        cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "To Next Level"
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .left
        
        // Progress value with egg icon
        let progressContainer = UIView()
        let progressValueLabel = UILabel()
        let progressData = getProgressToNextLevel()
        progressValueLabel.text = "\(progressData.current)"
        progressValueLabel.textColor = UIColor(named: "chickOrange")
        progressValueLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        
        // Сохраняем ссылки для обновления
        self.progressValueLabel = progressValueLabel
        
        let eggImageView = UIImageView()
        eggImageView.image = UIImage(named: "egg")
        eggImageView.contentMode = .scaleAspectFit
        
        progressContainer.addSubview(progressValueLabel)
        progressContainer.addSubview(eggImageView)
        
        progressValueLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        eggImageView.snp.makeConstraints { make in
            make.leading.equalTo(progressValueLabel.snp.trailing).offset(4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.trailing.equalToSuperview()
        }
        
        // Progress bar
        let progressView = UIProgressView()
        progressView.progressTintColor = UIColor(named: "chickOrange")
        progressView.trackTintColor = UIColor(named: "chickOrange")?.withAlphaComponent(0.3)
        progressView.progress = progressData.progress
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        
        // Сохраняем ссылку для обновления
        self.progressView = progressView
        
        // Tips list
        let tipsStackView = UIStackView()
        tipsStackView.axis = .vertical
        tipsStackView.spacing = 8
        tipsStackView.alignment = .fill
        
        let tips = [
            "Complete quizzes regularly to earn points and experience.",
            "Track your income and expenses to make smarter decisions.",
            "Participate in challenges and special tasks for bonus rewards.",
            "Stay consistent - small daily actions add up over time.",
            "Help others or share knowledge to gain extra recognition."
        ]
        
        for tip in tips {
            let tipLabel = UILabel()
            tipLabel.text = "• \(tip)"
            tipLabel.textColor = UIColor(named: "chickBrown")
            tipLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
            tipLabel.numberOfLines = 0
            tipLabel.textAlignment = .left
            tipsStackView.addArrangedSubview(tipLabel)
        }
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(progressContainer)
        cardView.addSubview(progressView)
        cardView.addSubview(tipsStackView)
        
        stackView.addArrangedSubview(cardView)
        
        // Constraints
        cardView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(200)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
        }
        
        progressContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(progressContainer.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(8)
        }
        
        tipsStackView.snp.makeConstraints { make in
            make.top.equalTo(progressView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    private func createStatusCard() {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(named: "cardGray")
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 4
        cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Status"
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textAlignment = .left
        
        // Separator line
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.3)
        
        // Status list
        let statusStackView = UIStackView()
        statusStackView.axis = .vertical
        statusStackView.spacing = 16
        statusStackView.alignment = .fill
        
        let statuses = [
            ("New Egg", "Just hatched! Still observing and learning how the farm works.", "0-99"),
            ("Young Hen", "A bit more experienced but still curious and energetic. Starting to gather first knowledge and resources.", "100-1499"),
            ("Farm Bird", "A true hard worker. Handles the main tasks of the farm and knows how to plan.", "1500-2999"),
            ("Golden Hen", "A valuable and wise member of the farm. Brings consistent results and helps others grow.", "3000-5999"),
            ("Wise Broody Hen", "A real strategist and mentor. Knows all the farm's secrets, wisely manages resources, and cares for the younger generation.", "6000+")
        ]
        
        for (title, description, eggsRequired) in statuses {
            let statusItemView = UIView()
            
            let statusTitleLabel = UILabel()
            statusTitleLabel.text = title
            statusTitleLabel.textColor = UIColor(named: "chickBrown")
            statusTitleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
            statusTitleLabel.textAlignment = .left
            
            let eggsRequiredLabel = UILabel()
            eggsRequiredLabel.text = eggsRequired
            eggsRequiredLabel.textColor = UIColor(named: "chickOrange")
            eggsRequiredLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold)
            eggsRequiredLabel.textAlignment = .right
            
            let descriptionLabel = UILabel()
            descriptionLabel.text = description
            descriptionLabel.textColor = UIColor(named: "chickBrown")
            descriptionLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
            descriptionLabel.numberOfLines = 0
            descriptionLabel.textAlignment = .left
            
            statusItemView.addSubview(statusTitleLabel)
            statusItemView.addSubview(eggsRequiredLabel)
            statusItemView.addSubview(descriptionLabel)
            
            statusTitleLabel.snp.makeConstraints { make in
                make.top.leading.equalToSuperview()
            }
            
            eggsRequiredLabel.snp.makeConstraints { make in
                make.top.trailing.equalToSuperview()
                make.leading.greaterThanOrEqualTo(statusTitleLabel.snp.trailing).offset(8)
            }
            
            descriptionLabel.snp.makeConstraints { make in
                make.top.equalTo(statusTitleLabel.snp.bottom).offset(4)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            
            statusStackView.addArrangedSubview(statusItemView)
        }
        
        cardView.addSubview(titleLabel)
        cardView.addSubview(separatorView)
        cardView.addSubview(statusStackView)
        
        stackView.addArrangedSubview(cardView)
        
        // Constraints
        cardView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(400)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        
        statusStackView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    private func createDescriptionCard() {
        let cardView = UIView()
        cardView.backgroundColor = UIColor(named: "cardGray")
        cardView.layer.cornerRadius = 16
        cardView.layer.borderWidth = 4
        cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Complete quizzes, earn points. and unlock achievements. Each decision shapes your journey — from small daily choices to big milestones. The smarter you play, the stronger and more successful your farm becomes!"
        descriptionLabel.textColor = UIColor(named: "chickBrown")
        descriptionLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        
        cardView.addSubview(descriptionLabel)
        stackView.addArrangedSubview(cardView)
        
        descriptionLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        cardView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(100)
        }
    }
    
    private func createDisclaimerButton() {
        let buttonView = UIView()
        buttonView.backgroundColor = UIColor(named: "cardGray")
        buttonView.layer.cornerRadius = 16
        buttonView.layer.borderWidth = 4
        buttonView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        
        let disclaimerLabel = UILabel()
        disclaimerLabel.text = "Disclaimer"
        disclaimerLabel.textColor = UIColor(named: "chickBrown")
        disclaimerLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        disclaimerLabel.textAlignment = .left
        
        let arrowImageView = UIImageView()
        arrowImageView.image = UIImage(systemName: "chevron.right")
        arrowImageView.tintColor = UIColor(named: "chickBrown")
        arrowImageView.contentMode = .scaleAspectFit
        
        buttonView.addSubview(disclaimerLabel)
        buttonView.addSubview(arrowImageView)
        stackView.addArrangedSubview(buttonView)
        
        disclaimerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        buttonView.snp.makeConstraints { make in
            make.height.equalTo(60)
        }
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(disclaimerTapped))
        buttonView.addGestureRecognizer(tapGesture)
        buttonView.isUserInteractionEnabled = true
    }
    
    @objc private func disclaimerTapped() {
        showDisclaimerModal()
    }
    
    private func showDisclaimerModal() {
        // Create overlay
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.alpha = 0
        view.addSubview(overlayView)
        
        // Create modal container
        let modalView = UIView()
        modalView.backgroundColor = UIColor(named: "chickYellowLight")
        modalView.layer.cornerRadius = 16
        modalView.layer.borderWidth = 4
        modalView.layer.borderColor = UIColor(named: "chickDarkYellow")?.cgColor
        modalView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        overlayView.addSubview(modalView)
        
        // Create disclaimer image
        let disclaimerImageView = UIImageView()
        disclaimerImageView.image = UIImage(named: "disclaimerImg")
        disclaimerImageView.contentMode = .scaleAspectFit
        modalView.addSubview(disclaimerImageView)
        
        // Add tap gesture to overlay
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideDisclaimerModal))
        overlayView.addGestureRecognizer(tapGesture)
        
        // Constraints
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        modalView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(320)
            make.height.equalTo(400)
        }
        
        disclaimerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        // Animate appearance
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            overlayView.alpha = 1
            modalView.transform = .identity
        })
    }
    
    @objc private func hideDisclaimerModal() {
        guard let overlayView = view.subviews.last(where: { $0.backgroundColor == UIColor.black.withAlphaComponent(0.5) }) else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            overlayView.alpha = 0
        }) { _ in
            overlayView.removeFromSuperview()
        }
    }
    
    // MARK: - Progress System
    private func loadProgress() {
        currentXP = UserDefaults.standard.integer(forKey: "userXP")
        currentLevel = calculateLevel(from: currentXP)
        print("Loaded progress: XP=\(currentXP), Level=\(currentLevel)")
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        if xp < 100 { return 1 }
        if xp < 1500 { return 2 }
        if xp < 3000 { return 3 }
        if xp < 6000 { return 4 }
        return 5
    }
    
    private func getCurrentStatus() -> (String, String, String) {
        let statuses = [
            ("New Egg", "Just hatched! Still observing and learning how the farm works.", "0-99"),
            ("Young Hen", "A bit more experienced but still curious and energetic. Starting to gather first knowledge and resources.", "100-1499"),
            ("Farm Bird", "A true hard worker. Handles the main tasks of the farm and knows how to plan.", "1500-2999"),
            ("Golden Hen", "A valuable and wise member of the farm. Brings consistent results and helps others grow.", "3000-5999"),
            ("Wise Broody Hen", "A real strategist and mentor. Knows all the farm's secrets, wisely manages resources, and cares for the younger generation.", "6000+")
        ]
        
        return statuses[currentLevel - 1]
    }
    
    private func getProgressToNextLevel() -> (current: Int, needed: Int, progress: Float) {
        let levelThresholds = [0, 100, 1500, 3000, 6000]
        let nextLevelThreshold = levelThresholds[min(currentLevel, levelThresholds.count - 1)]
        let currentLevelThreshold = levelThresholds[max(currentLevel - 1, 0)]
        
        let currentProgress = currentXP - currentLevelThreshold
        let neededForNext = nextLevelThreshold - currentLevelThreshold
        let progress = Float(currentProgress) / Float(neededForNext)
        
        return (current: currentProgress, needed: neededForNext, progress: min(progress, 1.0))
    }
    
    private func updateProgressDisplay() {
        let progressData = getProgressToNextLevel()
        
        // Обновляем прогресс-бар
        if let progressView = progressView {
            UIView.animate(withDuration: 1.0) {
                progressView.setProgress(progressData.progress, animated: true)
            }
        }
        
        // Обновляем счетчик
        if let progressValueLabel = progressValueLabel {
            progressValueLabel.text = "\(progressData.current)"
        }
    }
    
    // Публичный метод для добавления XP (вызывается из квизов)
    static func addXP(_ amount: Int) {
        let currentXP = UserDefaults.standard.integer(forKey: "userXP")
        let newXP = currentXP + amount
        UserDefaults.standard.set(newXP, forKey: "userXP")
        print("Added \(amount) XP. Total: \(newXP)")
    }
}
