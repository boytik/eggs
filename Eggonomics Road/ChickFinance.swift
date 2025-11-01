import UIKit
import SnapKit

final class ChickFinance: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    
    // Top card components
    private let incomeExpensesCard = UIView()
    private let incomeLabel = UILabel()
    private let expensesLabel = UILabel()
    private let incomeUnderline = UIView()
    private let expensesUnderline = UIView()
    private let counterCardView = UIView()
    private let valueLabel = UILabel()
    private let minusButton = UIButton()
    private let plusButton = UIButton()
    
    // Bottom card components
    private let transactionsCard = UIView()
    private let transactionsStackView = UIStackView()
    
    private var currentValue: Int = 0
    private var isIncomeSelected: Bool = true
    
    // UserDefaults keys
    private let incomeKey = "finance_income_transactions"
    private let expensesKey = "finance_expenses_transactions"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
        
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
        // Запускаем анимацию карточек при каждом появлении экрана
        DispatchQueue.main.async {
            self.animateCards()
        }
    }
    
    private func animateCards() {
        let cards = [incomeExpensesCard, transactionsCard]
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
        
        // Finance label for left bar button
        let financeLabel = UILabel()
        financeLabel.text = "Finance"
        financeLabel.textColor = UIColor(named: "chickBrown")
        financeLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24)
        financeLabel.textAlignment = .left
        
        // Balance label for right bar button
        let balanceLabel = UILabel()
        let worldCount = UserDefaults.standard.integer(forKey: "worldCount")
        balanceLabel.text = "\(worldCount)"
        balanceLabel.textColor = UIColor(named: "chickBrown")
        balanceLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24)
        balanceLabel.textAlignment = .right
        
        // Create bar button items
        let financeButton = UIBarButtonItem(customView: financeLabel)
        let balanceButton = UIBarButtonItem(customView: balanceLabel)
        
        navigationItem.leftBarButtonItem = financeButton
        navigationItem.rightBarButtonItem = balanceButton
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
    
    private func setupIncomeExpensesCard() {
        stackView.addArrangedSubview(incomeExpensesCard)
        
        incomeExpensesCard.backgroundColor = UIColor(named: "cardGray")
        incomeExpensesCard.layer.cornerRadius = 16
        incomeExpensesCard.layer.borderWidth = 4
        incomeExpensesCard.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        
        incomeExpensesCard.addSubview(incomeLabel)
        incomeExpensesCard.addSubview(expensesLabel)
        incomeExpensesCard.addSubview(incomeUnderline)
        incomeExpensesCard.addSubview(expensesUnderline)
        incomeExpensesCard.addSubview(counterCardView)
        
        // Настройка карточки для счетчика
        counterCardView.backgroundColor = UIColor(named: "bgColor")
        counterCardView.layer.cornerRadius = 16
        counterCardView.layer.borderWidth = 0
        counterCardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        counterCardView.clipsToBounds = true
        
        counterCardView.addSubview(minusButton)
        counterCardView.addSubview(valueLabel)
        counterCardView.addSubview(plusButton)
        
        // Income Label
        incomeLabel.text = "Income"
        incomeLabel.textColor = UIColor(named: "chickBrown")
        incomeLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        incomeLabel.textAlignment = .left
        
        // Expenses Label
        expensesLabel.text = "Expenses"
        expensesLabel.textColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.5)
        expensesLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        expensesLabel.textAlignment = .right
        
        // Setup underlines
        incomeUnderline.backgroundColor = UIColor(named: "chickBrown")
        expensesUnderline.backgroundColor = UIColor(named: "chickBrown")
        expensesUnderline.isHidden = true
        
        // Add tap gestures
        let incomeTap = UITapGestureRecognizer(target: self, action: #selector(incomeTapped))
        let expensesTap = UITapGestureRecognizer(target: self, action: #selector(expensesTapped))
        incomeLabel.addGestureRecognizer(incomeTap)
        expensesLabel.addGestureRecognizer(expensesTap)
        incomeLabel.isUserInteractionEnabled = true
        expensesLabel.isUserInteractionEnabled = true
        
        // Value Label
        valueLabel.text = "0"
        valueLabel.textColor = UIColor(named: "chickBrown")
        valueLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.isUserInteractionEnabled = true
        
        // Добавляем tap gesture для valueLabel
        let valueTap = UITapGestureRecognizer(target: self, action: #selector(valueLabelTapped))
        valueLabel.addGestureRecognizer(valueTap)
        
        // Minus Button
        minusButton.backgroundColor = UIColor(named: "chickBrown")
        minusButton.layer.cornerRadius = 20
        minusButton.setTitle("-", for: .normal)
        minusButton.setTitleColor(.white, for: .normal)
        minusButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        minusButton.addTarget(self, action: #selector(minusButtonTapped), for: .touchUpInside)
        
        // Plus Button
        plusButton.backgroundColor = UIColor(named: "chickBrown")
        plusButton.layer.cornerRadius = 20
        plusButton.setTitle("+", for: .normal)
        plusButton.setTitleColor(.white, for: .normal)
        plusButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        plusButton.addTarget(self, action: #selector(plusButtonTapped), for: .touchUpInside)
        
        // Constraints
        incomeExpensesCard.snp.makeConstraints { make in
            make.height.equalTo(168)
        }
        
        incomeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview().offset(-60)
        }
        
        expensesLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.centerX.equalToSuperview().offset(60)
        }
        
        incomeUnderline.snp.makeConstraints { make in
            make.top.equalTo(incomeLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(incomeLabel)
            make.height.equalTo(2)
        }
        
        expensesUnderline.snp.makeConstraints { make in
            make.top.equalTo(expensesLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(expensesLabel)
            make.height.equalTo(2)
        }
        
        // Constraints для карточки счетчика
        counterCardView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
//            make.top.equalTo(incomeLabel.snp.bottom).offset(20)
            make.height.equalTo(66)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // Constraints для элементов внутри карточки
        minusButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        valueLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(minusButton.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(plusButton.snp.leading).offset(-12)
        }
        
        plusButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        // Делаем кнопки круглыми
        minusButton.layer.cornerRadius = 20
        plusButton.layer.cornerRadius = 20
    }
    
    private func setupTransactionsCard() {
        stackView.addArrangedSubview(transactionsCard)
        
        transactionsCard.backgroundColor = UIColor(named: "cardGray")
        transactionsCard.layer.cornerRadius = 16
        transactionsCard.layer.borderWidth = 4
        transactionsCard.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        
        transactionsCard.addSubview(transactionsStackView)
        
        transactionsStackView.axis = .vertical
        transactionsStackView.spacing = 12
        transactionsStackView.alignment = .fill
        transactionsStackView.distribution = .fillEqually
        
        transactionsCard.snp.makeConstraints { make in
            make.height.equalTo(300)
        }
        
        transactionsStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    private func loadTransactions() {
        // Очищаем текущие транзакции
        clearTransactions()
        
        // Загружаем транзакции из UserDefaults
        let key = isIncomeSelected ? incomeKey : expensesKey
        if let savedTransactions = UserDefaults.standard.array(forKey: key) as? [[String: Any]] {
            for transactionData in savedTransactions {
                if let amount = transactionData["amount"] as? Int,
                   let date = transactionData["date"] as? String,
                   let isIncome = transactionData["isIncome"] as? Bool {
                    let amountString = isIncome ? "+\(amount)" : "-\(amount)"
                    let transactionView = createTransactionView(amount: amountString, date: date, isIncome: isIncome)
                    transactionsStackView.addArrangedSubview(transactionView)
                }
            }
        }
    }
    
    private func clearTransactions() {
        // Удаляем все существующие транзакции из stackView
        for subview in transactionsStackView.arrangedSubviews {
            transactionsStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
    }
    
    private func createTransactionView(amount: String, date: String, isIncome: Bool) -> UIView {
        let containerView = UIView()
        
        let amountLabel = UILabel()
        let dateLabel = UILabel()
        
        amountLabel.text = amount
        amountLabel.textColor = isIncome ? .systemGreen : .systemRed
        amountLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        amountLabel.textAlignment = .left
        
        dateLabel.text = date
        dateLabel.textColor = UIColor(named: "chickBrown")
        dateLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14)
        dateLabel.textAlignment = .right
        
        containerView.addSubview(amountLabel)
        containerView.addSubview(dateLabel)
        
        amountLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { make in
            make.height.equalTo(30)
        }
        
        return containerView
    }
    
    @objc private func incomeTapped() {
        isIncomeSelected = true
        updateSelectionUI()
        updateValueDisplay()
        loadTransactions() // Загружаем транзакции для Income
    }
    
    @objc private func expensesTapped() {
        isIncomeSelected = false
        updateSelectionUI()
        updateValueDisplay()
        loadTransactions() // Загружаем транзакции для Expenses
    }
    
    private func updateSelectionUI() {
        if isIncomeSelected {
            incomeLabel.textColor = UIColor(named: "chickBrown")
            expensesLabel.textColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.5)
            incomeUnderline.isHidden = false
            expensesUnderline.isHidden = true
        } else {
            incomeLabel.textColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.5)
            expensesLabel.textColor = UIColor(named: "chickBrown")
            incomeUnderline.isHidden = true
            expensesUnderline.isHidden = false
        }
    }
    
    @objc private func minusButtonTapped() {
        if currentValue > 0 {
            currentValue -= 1
            updateValueDisplay()
        }
    }
    
    @objc private func plusButtonTapped() {
        currentValue += 1
        updateValueDisplay()
    }
    
    @objc private func valueLabelTapped() {
        // Добавляем транзакцию только при нажатии на valueLabel
        if currentValue > 0 {
            saveTransaction()
        }
    }
    
    private func updateValueDisplay() {
        valueLabel.text = "\(currentValue)"
    }
    
    private func saveTransaction() {
        // Создаем новую транзакцию
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let dateString = formatter.string(from: currentDate)
        
        let amount = currentValue  // Сохраняем числовое значение
        let isIncome = isIncomeSelected
        
        // Создаем объект транзакции
        let transaction = [
            "amount": amount,
            "date": dateString,
            "isIncome": isIncome
        ] as [String : Any]
        
        // Получаем текущие транзакции
        let key = isIncomeSelected ? incomeKey : expensesKey
        var transactions = UserDefaults.standard.array(forKey: key) as? [[String: Any]] ?? []
        
        // Добавляем новую транзакцию в начало списка
        transactions.insert(transaction, at: 0)
        
        // Ограничиваем количество транзакций (например, 20)
        if transactions.count > 20 {
            transactions = Array(transactions.prefix(20))
        }
        
        // Сохраняем в UserDefaults
        UserDefaults.standard.set(transactions, forKey: key)
        print("Saved transaction: amount=\(amount), key=\(key), total transactions=\(transactions.count)")
        
        // Обновляем отображение
        loadTransactions()
    }
}
