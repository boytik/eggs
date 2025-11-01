import UIKit
import SnapKit

final class ChickArticles: UIViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var articles: [ArticleData] = []
    private var purchasedArticles: Set<String> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPurchasedArticles()
        setupNavigationBar()
        setupUI()
        setupScrollView()
        createArticleCards()
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
        
        // Создаем label слева с двумя разными цветами
        let statusLabel = UILabel()
        statusLabel.text = "Articles"
        statusLabel.textColor = UIColor(named: "chickBrown")
        statusLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24)
        statusLabel.textAlignment = .center
        navigationItem.titleView = statusLabel
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "bgColor")
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // Настройка StackView
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        // Constraints
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
            make.width.equalToSuperview().offset(-32)
        }
    }
    
    private func loadPurchasedArticles() {
        if let savedArticles = UserDefaults.standard.array(forKey: "purchasedArticles") as? [String] {
            purchasedArticles = Set(savedArticles)
        }
    }
    
    private func savePurchasedArticles() {
        UserDefaults.standard.set(Array(purchasedArticles), forKey: "purchasedArticles")
    }
    
    private func createArticleCards() {
        articles = [
            ArticleData(
                imageName: "article1",
                progress: "Articles: 5/5",
                title: "How to Plan Your Spending and Not Break Your Eggs for Nothing",
                status: purchasedArticles.contains("article1") ? "Read" : "Unread",
                hasCoin: !purchasedArticles.contains("article1")
            ),
            ArticleData(
                imageName: "article2",
                progress: "Articles: 0/5",
                title: "Why Save Money: The Power of Small Steps",
                status: purchasedArticles.contains("article2") ? "Read" : "Unread",
                hasCoin: !purchasedArticles.contains("article2")
            ),
            ArticleData(
                imageName: "article3",
                progress: "Articles: 5/5",
                title: "How to Avoid Financial Mistakes and a \"Cracked Nest\"",
                status: purchasedArticles.contains("article3") ? "Read" : "Unread",
                hasCoin: !purchasedArticles.contains("article3")
            ),
            ArticleData(
                imageName: "article4",
                progress: "Articles: 5/5",
                title: "Income: How to Hatch New Eggs",
                status: purchasedArticles.contains("article4") ? "Read" : "Unread",
                hasCoin: !purchasedArticles.contains("article4")
            ),
            ArticleData(
                imageName: "article5",
                progress: "Articles: 5/5",
                title: "How to Set Goals and Achieve Them Without Stress",
                status: purchasedArticles.contains("article5") ? "Read" : "Unread",
                hasCoin: !purchasedArticles.contains("article5")
            )
        ]
        
        for article in articles {
            let cardView = createArticleCard(article: article)
            stackView.addArrangedSubview(cardView)
        }
    }
    
    private func createArticleCard(article: ArticleData) -> UIView {
        let cardView = UIView()
        
        // Определяем цвета в зависимости от статуса покупки
        if article.status == "Read" {
            cardView.backgroundColor = UIColor(named: "cardGray")
            cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
        } else {
            cardView.backgroundColor = UIColor(named: "chickYellowLight")
            cardView.layer.borderColor = UIColor(named: "chickDarkYellow")?.cgColor
        }
        
        cardView.layer.cornerRadius = 32
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 4
        cardView.layer.borderWidth = 4
        
        // Добавляем gesture recognizer для нажатия на карточку
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(articleCardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Добавляем tag для идентификации карточки
        cardView.tag = articles.firstIndex(where: { $0.title == article.title }) ?? 0
        
        // Картинка статьи
        let articleImageView = UIImageView()
        articleImageView.image = UIImage(named: article.imageName)
        articleImageView.contentMode = .scaleAspectFit
//        articleImageView.layer.cornerRadius = 8
        articleImageView.clipsToBounds = true
        cardView.addSubview(articleImageView)
        
        // Прогресс текст
        let progressLabel = UILabel()
        progressLabel.text = article.progress
        progressLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14)
        progressLabel.textColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.50)
        cardView.addSubview(progressLabel)
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = article.title
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16)
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        cardView.addSubview(titleLabel)
        
        // Статус
        let statusLabel = UILabel()
        statusLabel.text = article.status
        statusLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14)
        statusLabel.textColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.50)
        cardView.addSubview(statusLabel)
        
        // Монета (если есть)
        if article.hasCoin {
            let coinImageView = UIImageView()
            coinImageView.image = UIImage(named: "coin50")
            coinImageView.contentMode = .scaleAspectFit
            cardView.addSubview(coinImageView)
            
            coinImageView.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-16)
                make.trailing.equalToSuperview().offset(-16)
//                make.width.height.equalTo(40)
            }
        }
        
        // Constraints
        articleImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(311)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(articleImageView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressLabel.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // Фиксированная высота карточки
        cardView.snp.makeConstraints { make in
            make.height.equalTo(459)
        }
        
        return cardView
    }
    
    // MARK: - Actions
    @objc private func articleCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cardView = gesture.view else { return }
        let articleIndex = cardView.tag
        
        guard articleIndex < articles.count else { return }
        let article = articles[articleIndex]
        
        // Анимация нажатия
        UIView.animate(withDuration: 0.1, animations: {
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                cardView.transform = .identity
            }) { _ in
                // Проверяем, куплена ли статья
                if article.status == "Read" {
                    // Статья уже куплена, переходим к описанию
                    let descriptionVC = ChickArticlesDescription(articleTitle: article.title)
                    self.navigationController?.pushViewController(descriptionVC, animated: true)
                } else {
                    // Статья не куплена, проверяем баланс и покупаем
                    self.purchaseArticle(article: article, cardView: cardView, articleIndex: articleIndex)
                }
            }
        }
    }
    
    private func purchaseArticle(article: ArticleData, cardView: UIView, articleIndex: Int) {
        let currentBalance = UserDefaults.standard.integer(forKey: "worldCount")
        let articlePrice = 50
        
        if currentBalance >= articlePrice {
            // Достаточно средств для покупки
            let newBalance = currentBalance - articlePrice
            UserDefaults.standard.set(newBalance, forKey: "worldCount")
            
            // Добавляем статью в купленные
            purchasedArticles.insert(article.imageName)
            savePurchasedArticles()
            
            // Обновляем UI карточки
            updateCardUI(cardView: cardView, isPurchased: true)
            
            // Обновляем данные статьи
            articles[articleIndex] = ArticleData(
                imageName: article.imageName,
                progress: article.progress,
                title: article.title,
                status: "Read",
                hasCoin: false
            )
            
            // Показываем уведомление о покупке
            showPurchaseNotification()
            
            // Переходим к описанию статьи
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let descriptionVC = ChickArticlesDescription(articleTitle: article.title)
                self.navigationController?.pushViewController(descriptionVC, animated: true)
            }
        } else {
            // Недостаточно средств
            showInsufficientFundsAlert()
        }
    }
    
    private func updateCardUI(cardView: UIView, isPurchased: Bool) {
        UIView.animate(withDuration: 0.3) {
            if isPurchased {
                cardView.backgroundColor = UIColor(named: "cardGray")
                cardView.layer.borderColor = UIColor(named: "borderGray")?.cgColor
            }
        }
        
        // Обновляем статус и скрываем монету
        for subview in cardView.subviews {
            if let label = subview as? UILabel {
                if label.text == "Unread" {
                    label.text = "Read"
                }
            }
            if let imageView = subview as? UIImageView {
                if imageView.image == UIImage(named: "coin50") {
                    imageView.isHidden = true
                }
            }
        }
    }
    
    private func showPurchaseNotification() {
        let alert = UIAlertController(title: "Article Purchased!", message: "50 coins deducted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showInsufficientFundsAlert() {
        let alert = UIAlertController(title: "Insufficient Funds", message: "You need 50 coins to purchase this article", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Переопределяем стиль status bar для белого фона
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

// MARK: - Data Model
struct ArticleData {
    let imageName: String
    let progress: String
    let title: String
    let status: String
    let hasCoin: Bool
}
