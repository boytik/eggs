import UIKit
import SnapKit

final class ChickArticlesDescription: UIViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let articleTitle: String
    private let coin10 = UIImageView()
    private var chapters: [ChapterData] = []
    private var purchasedChapters: Set<String> = []
    
    init(articleTitle: String) {
        self.articleTitle = articleTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        loadPurchasedChapters()
        setupNavigationBar()
        setupUI()
        setupScrollView()
        createChapterCards()
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
    
    private func updateWorldCount() {
        let worldCount = UserDefaults.standard.integer(forKey: "worldCount")
        print("Current world count: \(worldCount)")
    }
    
    private func loadPurchasedChapters() {
        let key = "purchasedChapters_\(articleTitle)"
        if let savedChapters = UserDefaults.standard.array(forKey: key) as? [String] {
            purchasedChapters = Set(savedChapters)
        }
    }
    
    private func savePurchasedChapters() {
        let key = "purchasedChapters_\(articleTitle)"
        UserDefaults.standard.set(Array(purchasedChapters), forKey: key)
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
        titleLabel.text = "Articles"
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true // Автоматическое уменьшение шрифта
        titleLabel.minimumScaleFactor = 0.6 // Минимальный масштаб (60% от исходного)
        titleLabel.lineBreakMode = .byTruncatingTail // Обрезание с многоточием если не помещается
        
        navigationItem.titleView = titleLabel
        
        // Constraints для titleLabel (после установки titleView)
        DispatchQueue.main.async {
            titleLabel.snp.makeConstraints { make in
                make.width.lessThanOrEqualTo(self.view.snp.width).offset(-100) // Ограничиваем ширину с отступами
                make.height.equalTo(44) // Стандартная высота navigation bar
            }
        }
        
        // Кастомная кнопка "Назад"
        let backButton = UIBarButtonItem(image: UIImage(named: "chickBack")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
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
    
    private func createChapterCards() {
        // Определяем префикс картинок и получаем уникальные тексты в зависимости от заголовка статьи
        let imagePrefix = getImagePrefix(for: articleTitle)
        let chapterTitles = getChapterTitles(for: articleTitle)
        
        chapters = [
            ChapterData(
                imageName: "\(imagePrefix)Img1",
                chapterNumber: purchasedChapters.contains("\(imagePrefix)Img1") ? "Read" : "Unread",
                title: chapterTitles[0],
                hasCoin: !purchasedChapters.contains("\(imagePrefix)Img1")
            ),
            ChapterData(
                imageName: "\(imagePrefix)Img2",
                chapterNumber: purchasedChapters.contains("\(imagePrefix)Img2") ? "Read" : "Unread",
                title: chapterTitles[1],
                hasCoin: !purchasedChapters.contains("\(imagePrefix)Img2")
            ),
            ChapterData(
                imageName: "\(imagePrefix)Img3",
                chapterNumber: purchasedChapters.contains("\(imagePrefix)Img3") ? "Read" : "Unread",
                title: chapterTitles[2],
                hasCoin: !purchasedChapters.contains("\(imagePrefix)Img3")
            ),
            ChapterData(
                imageName: "\(imagePrefix)Img4",
                chapterNumber: purchasedChapters.contains("\(imagePrefix)Img4") ? "Read" : "Unread",
                title: chapterTitles[3],
                hasCoin: !purchasedChapters.contains("\(imagePrefix)Img4")
            ),
            ChapterData(
                imageName: "\(imagePrefix)Img5",
                chapterNumber: purchasedChapters.contains("\(imagePrefix)Img5") ? "Read" : "Unread",
                title: chapterTitles[4],
                hasCoin: !purchasedChapters.contains("\(imagePrefix)Img5")
            )
        ]
        
        for chapter in chapters {
            let cardView = createChapterCard(chapter: chapter)
            stackView.addArrangedSubview(cardView)
        }
    }
    
    private func createChapterCard(chapter: ChapterData) -> UIView {
        let cardView = UIView()
        
        // Определяем цвета в зависимости от статуса покупки
        if chapter.chapterNumber == "Read" {
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chapterCardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Сохраняем данные главы в tag для передачи в detail
        cardView.tag = chapters.firstIndex(where: { $0.title == chapter.title }) ?? 0
        
        // Картинка главы
        let chapterImageView = UIImageView()
        chapterImageView.image = UIImage(named: chapter.imageName)
        chapterImageView.contentMode = .scaleAspectFit
        chapterImageView.clipsToBounds = true
        cardView.addSubview(chapterImageView)
        
        // Заголовок главы
        let titleLabel = UILabel()
        titleLabel.text = chapter.title
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 16)
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        cardView.addSubview(titleLabel)
        
        // Номер главы
        let chapterNumberLabel = UILabel()
        chapterNumberLabel.text = chapter.chapterNumber
        chapterNumberLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14)
        chapterNumberLabel.textColor = UIColor(named: "chickBrown")?.withAlphaComponent(0.50)
        cardView.addSubview(chapterNumberLabel)
        
        // coin - показываем только для непокупленных глав
        let coin10 = UIImageView(image: UIImage(named: "coin10"))
        coin10.isHidden = !chapter.hasCoin
        cardView.addSubview(coin10)
        
        // Constraints
        chapterImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(311)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(chapterImageView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        chapterNumberLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
        }
        
        coin10.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        // Фиксированная высота карточки
        cardView.snp.makeConstraints { make in
            make.height.equalTo(431)
        }
        
        return cardView
    }
    
    // MARK: - Helper Methods
    private func getImagePrefix(for title: String) -> String {
        switch title {
        case "How to Plan Your Spending and Not Break Your Eggs for Nothing":
            return "articleFirst"
        case "Why Save Money: The Power of Small Steps":
            return "articleSecond"
        case "How to Avoid Financial Mistakes and a \"Cracked Nest\"":
            return "articleThird"
        case "Income: How to Hatch New Eggs":
            return "articleFourth"
        case "How to Set Goals and Achieve Them Without Stress":
            return "articleFifth"
        default:
            return "articleFirst" // Fallback
        }
    }
    
    private func getChapterTitles(for title: String) -> [String] {
        switch title {
        case "How to Plan Your Spending and Not Break Your Eggs for Nothing":
            return [
                "How to Start Planning Your Expenses: The First Step to Financial Freedom",
                "The Financial Cushion: Why Everyone Needs One",
                "How to Avoid Impulse Buying and Protect Your Budget",
                "Don’t Break the Eggs: The Power of Financial Diversification",
                "Financial Goals: Turning Dreams Into Action"
            ]
        case "Why Save Money: The Power of Small Steps":
            return [
                "Small Steps to Big Money",
                "The Saving Habit That Changes Everything",
                "How Savings Bring Confidence",
                "The Secret Joy of Saving",
                "The Future Starts Today"
            ]
        case "How to Avoid Financial Mistakes and a \"Cracked Nest\"":
            return [
                "Building a Strong Nest: The Art of Balance",
                "The Importance of Checking Your Nest Regularly",
                "Emotional Spending: When Feelings Crack the Shell",
                "The Cracked Nest: How Little Mistakes Break Big Plans",
                "Turning Mistakes into Feathers: Growing from Cracks"
            ]
        case "Income: How to Hatch New Eggs":
            return [
                "Every Egg Counts: Understanding the Power of Income",
                "Don’t Keep All Your Eggs in One Basket",
                "Feeding the Hens: How to Grow Your Earning Power",
                "When Eggs Multiply: Managing Income Wisely",
                "The Golden Egg: Turning Effort into Freedom"
            ]
        case "How to Set Goals and Achieve Them Without Stress":
            return [
                "Planting the Seeds: Setting Goals That Grow Naturally",
                "The Gentle Farmer: Achieving More by Doing Less",
                "The Power of Tiny Steps: Growing Without Overwhelm",
                "Resting Without Guilt: Why Breaks Grow Results",
                "Harvest Time: Celebrating Your Wins (Big or Small)"
            ]
        default:
            return [
                "Introduction to Financial Planning",
                "Setting Your Financial Goals",
                "Creating Your Budget",
                "Tracking Your Expenses",
                "Review and Adjust"
            ]
        }
    }
    
    // MARK: - Actions
    @objc private func chapterCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cardView = gesture.view else { return }
        let chapterIndex = cardView.tag
        
        guard chapterIndex < chapters.count else { return }
        let chapter = chapters[chapterIndex]
        
        // Анимация нажатия
        UIView.animate(withDuration: 0.1, animations: {
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                cardView.transform = .identity
            }) { _ in
                // Проверяем статус главы
                if chapter.chapterNumber == "Read" {
                    // Глава уже куплена, переходим к детальному описанию
                    let detailVC = ChickArticlesDescriptionDetail(chapterTitle: chapter.title, chapterImageName: chapter.imageName)
                    self.navigationController?.pushViewController(detailVC, animated: true)
                } else {
                    // Глава не куплена, пытаемся купить
                    self.purchaseChapter(chapter: chapter, cardView: cardView, chapterIndex: chapterIndex)
                }
            }
        }
    }
    
    private func purchaseChapter(chapter: ChapterData, cardView: UIView, chapterIndex: Int) {
        let chapterPrice = 10
        let currentWorldCount = UserDefaults.standard.integer(forKey: "worldCount")
        
        if currentWorldCount >= chapterPrice {
            // Достаточно средств для покупки
            let newWorldCount = currentWorldCount - chapterPrice
            UserDefaults.standard.set(newWorldCount, forKey: "worldCount")
            
            // Добавляем главу в купленные
            purchasedChapters.insert(chapter.imageName)
            savePurchasedChapters()
            
            // Обновляем UI карточки
            updateChapterCardUI(cardView: cardView, isPurchased: true)
            
            // Обновляем данные главы
            chapters[chapterIndex] = ChapterData(
                imageName: chapter.imageName,
                chapterNumber: "Read",
                title: chapter.title,
                hasCoin: false
            )
            
            // Показываем уведомление о покупке
            showPurchaseNotification()
            
            // Переходим к детальному описанию после небольшой задержки
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let detailVC = ChickArticlesDescriptionDetail(chapterTitle: chapter.title, chapterImageName: chapter.imageName)
                self.navigationController?.pushViewController(detailVC, animated: true)
            }
        } else {
            // Недостаточно средств
            showInsufficientFundsAlert()
        }
    }
    
    private func updateChapterCardUI(cardView: UIView, isPurchased: Bool) {
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
                    label.text = "Read"
                }
            } else if let imageView = subview as? UIImageView {
                if imageView.image?.description.contains("coin10") == true {
                    imageView.isHidden = true
                }
            }
        }
    }
    
    private func showPurchaseNotification() {
        let alert = UIAlertController(title: "Chapter Purchased!", message: "10 coins deducted", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showInsufficientFundsAlert() {
        let alert = UIAlertController(title: "Insufficient Funds", message: "You need 10 coins to purchase this chapter", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Переопределяем стиль status bar для белого фона
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

// MARK: - Data Model
struct ChapterData {
    let imageName: String
    let chapterNumber: String
    let title: String
    let hasCoin: Bool
}
