import UIKit
import SnapKit

final class ChickMenu: UIViewController {
    
    private let backgroundImageView = UIImageView()
    
    // UI компоненты для статистики
    private let statsContainerView = UIView()
    private let incomeLabel = UILabel()
    private let expensesLabel = UILabel()
    private let progressLabel = UILabel()
    
    // Overlay компоненты
    private let overlayView = UIView()
    private let alertImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupOverlay()
        checkFirstTimeMenu()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Обновляем финансовую статистику после того как view полностью загружен
        updateFinancialStats()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        // Настройка фонового изображения
        backgroundImageView.image = UIImage(named: "chickBGMain")
        backgroundImageView.frame = view.bounds
        view.addSubview(backgroundImageView)
        
        // Настройка контейнера для статистики
        statsContainerView.backgroundColor = UIColor(named: "chickYellowLight")
        statsContainerView.layer.cornerRadius = 16 // Закругленные углы
        statsContainerView.layer.borderWidth = 4.0 // Обводка
        statsContainerView.layer.borderColor = UIColor(named: "chickDarkYellow")?.cgColor
        statsContainerView.clipsToBounds = true
        view.addSubview(statsContainerView)
        
        // Настройка лейблов
        setupStatsLabels()
        
        // Constraints для контейнера
        statsContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(40) // Под navigation bar
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.85) // 85% ширины экрана
            make.height.equalTo(122) // Фиксированная высота
        }
    }
    
    private func setupStatsLabels() {
        // Настройка шрифтов и цветов
        let fontName = "BlackHanSans-Regular"
        let textFont = UIFont(name: fontName, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        let numberFont = UIFont(name: fontName, size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
        let orangeColor = UIColor(named: "chickOrange") ?? .orange
        let brownColor = UIColor(named: "chickBrown") ?? .brown
        
        // Income Label
        let incomeText = NSMutableAttributedString(string: "Income: ", attributes: [.font: textFont, .foregroundColor: brownColor])
        incomeText.append(NSAttributedString(string: "0", attributes: [.font: numberFont, .foregroundColor: orangeColor]))
        incomeLabel.attributedText = incomeText
        incomeLabel.textAlignment = .center
        statsContainerView.addSubview(incomeLabel)
        
        // Expenses Label
        let expensesText = NSMutableAttributedString(string: "Expenses: ", attributes: [.font: textFont, .foregroundColor: brownColor])
        expensesText.append(NSAttributedString(string: "0", attributes: [.font: numberFont, .foregroundColor: orangeColor]))
        expensesLabel.attributedText = expensesText
        expensesLabel.textAlignment = .center
        statsContainerView.addSubview(expensesLabel)
        
        // Progress Label
        let progressText = NSMutableAttributedString(string: "Progress for the week: ", attributes: [.font: textFont, .foregroundColor: brownColor])
        progressText.append(NSAttributedString(string: "0", attributes: [.font: numberFont, .foregroundColor: orangeColor]))
        progressLabel.attributedText = progressText
        progressLabel.textAlignment = .center
        statsContainerView.addSubview(progressLabel)
        
        // Constraints для лейблов (центрируем)
        incomeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
        
        expensesLabel.snp.makeConstraints { make in
            make.top.equalTo(incomeLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(expensesLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-15)
        }
    }
    
    private func setupNavigationBar() {
        // Настройка белого navigation bar
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        
        // Делаем верхнюю safe area белой
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.backgroundColor = .white
        }
        
        // Настройка status bar
        navigationController?.navigationBar.barStyle = .default
        setNeedsStatusBarAppearanceUpdate()
        
        // Создаем label слева с двумя разными цветами
        let statusLabel = UILabel()
        statusLabel.numberOfLines = 2
        
        // Получаем текущий статус
        let currentStatus = getCurrentStatus()
        
        // Создаем attributed string для разных цветов и размеров
        let attributedString = NSMutableAttributedString()
        
        // "Status/" - chickBrown, размер 12
        let statusText = NSAttributedString(
            string: "Status\n",
            attributes: [
                .foregroundColor: UIColor(named: "chickBrown") ?? .brown,
                .font: UIFont(name: "BlackHanSans-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
            ]
        )
        
        // Текущий статус - chickOrange, размер 24
        let statusValueText = NSAttributedString(
            string: currentStatus,
            attributes: [
                .foregroundColor: UIColor(named: "chickOrange") ?? .orange,
                .font: UIFont(name: "BlackHanSans-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24)
            ]
        )
        
        attributedString.append(statusText)
        attributedString.append(statusValueText)
        
        statusLabel.attributedText = attributedString
        
        // Добавляем как left bar button item
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: statusLabel)
        
        let chickContainer = UIImageView(image: UIImage(named: "chickContainer"))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: chickContainer)
        
        let chickCount = UILabel()
        let worldCount = UserDefaults.standard.integer(forKey: "worldCount")
        chickCount.text = "\(worldCount)"
        chickCount.textColor = UIColor(named: "chickBrown")
        chickCount.font = UIFont(name: "BlackHanSans-Regular", size: 24)
        chickContainer.addSubview(chickCount)
        
        chickCount.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-44)
        }
    }
    
    // Переопределяем стиль status bar для белого фона
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    // MARK: - Overlay Methods
    private func setupOverlay() {
        // Настройка темного overlay
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.isHidden = true
        view.addSubview(overlayView)
        
        // Настройка картинки alert
        alertImageView.image = UIImage(named: "chickAlertMenu")
        alertImageView.contentMode = .scaleAspectFit
        alertImageView.isUserInteractionEnabled = true
        overlayView.addSubview(alertImageView)
        
        // Добавляем gesture recognizer для нажатия на картинку
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(alertImageTapped))
        alertImageView.addGestureRecognizer(tapGesture)
        
        // Constraints для overlay
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Constraints для картинки
        alertImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func checkFirstTimeMenu() {
        // Проверяем, открывался ли ChickMenu раньше
        let hasSeenMenu = UserDefaults.standard.bool(forKey: "hasSeenMenu")
        
        if !hasSeenMenu {
            // Показываем overlay при первом открытии
            showOverlay()
            // Сохраняем флаг о том, что меню уже видели
            UserDefaults.standard.set(true, forKey: "hasSeenMenu")
        }
    }
    
    private func showOverlay() {
        overlayView.isHidden = false
        overlayView.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 1
        }
    }
    
    @objc private func alertImageTapped() {
        // Плавно скрываем overlay при нажатии на картинку
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 0
        }) { _ in
            self.overlayView.isHidden = true
        }
    }
    
    // MARK: - Financial Stats
    private func updateFinancialStats() {
        print("=== Updating Financial Stats ===")
        let income = calculateTotalIncome()
        let expenses = calculateTotalExpenses()
        let progress = calculateWeeklyProgress()
        
        print("Final stats - Income: \(income), Expenses: \(expenses), Progress: \(progress)")
        updateStatsLabels(income: income, expenses: expenses, progress: progress)
    }
    
    private func calculateTotalIncome() -> Int {
        if let savedTransactions = UserDefaults.standard.array(forKey: "finance_income_transactions") as? [[String: Any]] {
            print("Found \(savedTransactions.count) income transactions")
            let total = savedTransactions.reduce(0) { total, transaction in
                if let amount = transaction["amount"] as? Int {
                    print("Income transaction (Int): \(amount)")
                    return total + amount
                } else if let amountNumber = transaction["amount"] as? NSNumber {
                    let amount = amountNumber.intValue
                    print("Income transaction (NSNumber): \(amount)")
                    return total + amount
                }
                print("Failed to cast amount: \(transaction["amount"] ?? "nil")")
                return total
            }
            print("Total income: \(total)")
            return total
        }
        print("No income transactions found")
        return 0
    }
    
    private func calculateTotalExpenses() -> Int {
        if let savedTransactions = UserDefaults.standard.array(forKey: "finance_expenses_transactions") as? [[String: Any]] {
            return savedTransactions.reduce(0) { total, transaction in
                if let amount = transaction["amount"] as? Int {
                    return total + amount
                } else if let amountNumber = transaction["amount"] as? NSNumber {
                    return total + amountNumber.intValue
                }
                return total
            }
        }
        return 0
    }
    
    private func calculateWeeklyProgress() -> Int {
        // Простой расчет: доходы - расходы
        let income = calculateTotalIncome()
        let expenses = calculateTotalExpenses()
        return max(0, income - expenses)
    }
    
    private func updateStatsLabels(income: Int, expenses: Int, progress: Int) {
        print("Updating labels with: Income=\(income), Expenses=\(expenses), Progress=\(progress)")
        
        // Настройка шрифтов и цветов
        let fontName = "BlackHanSans-Regular"
        let textFont = UIFont(name: fontName, size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        let numberFont = UIFont(name: fontName, size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
        let orangeColor = UIColor(named: "chickOrange") ?? .orange
        let brownColor = UIColor(named: "chickBrown") ?? .brown
        
        // Income Label
        let incomeText = NSMutableAttributedString(string: "Income: ", attributes: [.font: textFont, .foregroundColor: brownColor])
        incomeText.append(NSAttributedString(string: "\(income)", attributes: [.font: numberFont, .foregroundColor: orangeColor]))
        incomeLabel.attributedText = incomeText
        
        // Expenses Label
        let expensesText = NSMutableAttributedString(string: "Expenses: ", attributes: [.font: textFont, .foregroundColor: brownColor])
        expensesText.append(NSAttributedString(string: "\(expenses)", attributes: [.font: numberFont, .foregroundColor: orangeColor]))
        expensesLabel.attributedText = expensesText
        
        // Progress Label
        let progressText = NSMutableAttributedString(string: "Progress for the week: ", attributes: [.font: textFont, .foregroundColor: brownColor])
        progressText.append(NSAttributedString(string: "\(progress)", attributes: [.font: numberFont, .foregroundColor: orangeColor]))
        progressLabel.attributedText = progressText
        
        print("Labels updated successfully")
    }
    
    private func getCurrentStatus() -> String {
        let currentXP = UserDefaults.standard.integer(forKey: "userXP")
        
        if currentXP < 100 { return "New Egg" }
        if currentXP < 1500 { return "Young Hen" }
        if currentXP < 3000 { return "Farm Bird" }
        if currentXP < 6000 { return "Golden Hen" }
        return "Wise Broody Hen"
    }
}
