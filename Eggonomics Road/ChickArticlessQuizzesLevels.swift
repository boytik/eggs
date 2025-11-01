import UIKit
import SnapKit

final class ChickArticlessQuizzesLevels: UIViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var quizzes: [QuizData] = []
    private var purchasedQuizzes: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0) // Светло-бежевый фон
        
        loadPurchasedQuizzes()
        setupNavigationBar()
        setupUI()
        setupScrollView()
        createQuizCards()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем worldCount
        updateWorldCount()
        // Запускаем анимацию карточек при каждом появлении экрана
        DispatchQueue.main.async {
            self.animateCards()
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // Только портрет
    }

    override var shouldAutorotate: Bool {
        return false
    }
    
    private func updateWorldCount() {
        let worldCount = UserDefaults.standard.integer(forKey: "worldCount")
        print("Current world count: \(worldCount)")
    }
    
    private func loadPurchasedQuizzes() {
        if let savedQuizzes = UserDefaults.standard.array(forKey: "purchasedQuizzes") as? [String] {
            purchasedQuizzes = Set(savedQuizzes)
        }
    }
    
    private func savePurchasedQuizzes() {
        UserDefaults.standard.set(Array(purchasedQuizzes), forKey: "purchasedQuizzes")
    }
    
    private func animateCards() {
        for (index, cardView) in stackView.arrangedSubviews.enumerated() {
            cardView.alpha = 0
            cardView.transform = CGAffineTransform(translationX: 0, y: 50)
            
            UIView.animate(withDuration: 0.5, delay: Double(index) * 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                cardView.alpha = 1
                cardView.transform = .identity
            }
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
        
        // Создаем label с динамическим размером шрифта
        let titleLabel = UILabel()
        titleLabel.text = "Quizzes"
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 18)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.lineBreakMode = .byTruncatingTail
        
        navigationItem.titleView = titleLabel
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0) // Светло-бежевый фон
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // Настройка StackView
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalToSuperview().offset(-32)
        }
    }
    
    private func createQuizCards() {
        let quizTitles = [
            "How to Plan Your Spending and Not Break Your Eggs for Nothing",
            "Why Save Money: The Power of Small Steps",
            "How to Avoid Financial Mistakes and a \"Cracked Nest\"",
            "Income: How to Hatch New Eggs",
            "How to Set Goals and Achieve Them Without Stress"
        ]
        
        quizzes = quizTitles.map { title in
            let isPurchased = purchasedQuizzes.contains(title)
            return QuizData(
                title: title,
                isCompleted: isPurchased,
                hasCoin: !isPurchased
            )
        }
        
        for quiz in quizzes {
            let cardView = createQuizCard(quiz: quiz)
            stackView.addArrangedSubview(cardView)
        }
    }
    
    private func createQuizCard(quiz: QuizData) -> UIView {
        let cardView = UIView()
        
        // Настройка карточки в зависимости от статуса
        if quiz.isCompleted {
            cardView.backgroundColor = UIColor(named: "cardGray")
            cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        } else {
            cardView.backgroundColor = UIColor(named: "chickYellowLight")
            cardView.layer.borderColor = UIColor(named: "chickDarkYellow")?.cgColor
        }
        
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 4
        cardView.layer.borderWidth = 4
        
        // Добавляем gesture recognizer для нажатия на карточку
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(quizCardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Добавляем tag для идентификации карточки
        cardView.tag = quizzes.firstIndex(where: { $0.title == quiz.title }) ?? 0
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = quiz.title
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        cardView.addSubview(titleLabel)
        
        // Статус
        let statusLabel = UILabel()
        statusLabel.text = quiz.isCompleted ? "Completed" : "Not yet completed"
        statusLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = quiz.isCompleted ? UIColor.gray : UIColor(named: "chickBrown")?.withAlphaComponent(0.7)
        statusLabel.numberOfLines = 1
        statusLabel.textAlignment = .left
        cardView.addSubview(statusLabel)
        
        // Монета (только для незавершенных)
        let coinImageView = UIImageView()
        coinImageView.image = UIImage(named: "coin100")
        coinImageView.contentMode = .scaleAspectFit
        coinImageView.isHidden = !quiz.hasCoin
        cardView.addSubview(coinImageView)
        
        coinImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        // Фиксированная высота карточки
        cardView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }
        
        return cardView
    }
    
    // MARK: - Actions
    @objc private func quizCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cardView = gesture.view else { return }
        let quizIndex = cardView.tag
        
        guard quizIndex < quizzes.count else { return }
        let quiz = quizzes[quizIndex]
        
        // Анимация нажатия
        UIView.animate(withDuration: 0.1, animations: {
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                cardView.transform = .identity
            }) { _ in
                // Проверяем статус квиза
                if quiz.isCompleted {
                    // Квиз уже куплен, переходим к викторине
                    let quizVC = ChickArticlesQuizzes(quizTitle: quiz.title)
                    self.navigationController?.pushViewController(quizVC, animated: true)
                } else {
                    // Квиз не куплен, пытаемся купить
                    self.purchaseQuiz(quiz: quiz, cardView: cardView, quizIndex: quizIndex)
                }
            }
        }
    }
    
    private func purchaseQuiz(quiz: QuizData, cardView: UIView, quizIndex: Int) {
        let quizPrice = 100
        let currentWorldCount = UserDefaults.standard.integer(forKey: "worldCount")
        
        if currentWorldCount >= quizPrice {
            // Достаточно средств для покупки
            let newWorldCount = currentWorldCount - quizPrice
            UserDefaults.standard.set(newWorldCount, forKey: "worldCount")
            
            // Добавляем квиз в купленные
            purchasedQuizzes.insert(quiz.title)
            savePurchasedQuizzes()
            
            // Обновляем UI карточки
            updateQuizCardUI(cardView: cardView, isPurchased: true)
            
            // Обновляем данные квиза
            quizzes[quizIndex] = QuizData(
                title: quiz.title,
                isCompleted: true,
                hasCoin: false
            )
            
            // Показываем уведомление о покупке
            showPurchaseNotification()
            
            // Переходим к викторине после небольшой задержки
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let quizVC = ChickArticlesQuizzes(quizTitle: quiz.title)
                self.navigationController?.pushViewController(quizVC, animated: true)
            }
        } else {
            // Недостаточно средств
            showInsufficientFundsAlert()
        }
    }
    
    private func updateQuizCardUI(cardView: UIView, isPurchased: Bool) {
        UIView.animate(withDuration: 0.3) {
            if isPurchased {
                cardView.backgroundColor = UIColor(named: "cardGray")
                cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
            }
        }
        
        // Обновляем статус и скрываем монету
        for subview in cardView.subviews {
            if let label = subview as? UILabel {
                if label.font?.pointSize == 14 { // Это label статуса
                    label.text = "Completed"
                    label.textColor = UIColor.gray
                }
            } else if let imageView = subview as? UIImageView {
                if imageView.image?.description.contains("coin100") == true {
                    imageView.isHidden = true
                }
            }
        }
    }
    
    private func showPurchaseNotification() {
        let alert = UIAlertController(title: "Quiz Purchased!", message: "100 coins deducted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showInsufficientFundsAlert() {
        let alert = UIAlertController(title: "Insufficient Funds", message: "You need 100 coins to purchase this quiz", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Переопределяем стиль status bar для белого фона
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

// MARK: - Data Model
struct QuizData {
    let title: String
    let isCompleted: Bool
    let hasCoin: Bool
}
