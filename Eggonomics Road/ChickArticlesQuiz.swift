import UIKit
import SnapKit

final class ChickArticlesQuiz: UIViewController {
    
    private let chickQuizBG = UIImageView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let questionCardView = UIView()
    private let questionLabel = UILabel()
    private let answerStackView = UIStackView()
    private var questions: [QuizQuestion] = []
    private var currentQuestionIndex = 0
    private var score = 0
    private var chapterTitle: String
    private var overlayView = UIView()
    private var resultImageView = UIImageView()
    
    init(chapterTitle: String) {
        self.chapterTitle = chapterTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupUI()
        setupScrollView()
        createQuizQuestions()
        showCurrentQuestion()
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
        titleLabel.text = "Quiz"
        titleLabel.textColor = UIColor(named: "chickBrown")
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 18)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.lineBreakMode = .byTruncatingTail
        
        navigationItem.titleView = titleLabel
        
        // Кастомная кнопка "Назад"
        let backButton = UIBarButtonItem(image: UIImage(named: "chickBack")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0) // Светло-бежевый фон
    }
    
    private func setupScrollView() {
        chickQuizBG.image = UIImage(named: "chickQuizBG")
        chickQuizBG.frame = view.bounds
        view.addSubview(chickQuizBG)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(questionCardView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(scrollView.snp.height).priority(.low)
        }
        
        questionCardView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(422)
        }
    }
    
    private func createQuizQuestions() {
        questions = getQuestionsForChapter(chapterTitle)
    }
    
    private func getQuestionsForChapter(_ title: String) -> [QuizQuestion] {
        switch title {
        case "How to Start Planning Your Expenses: The First Step to Financial Freedom":
            return [
                QuizQuestion(
                    question: "What is the first step toward financial freedom according to this chapter?",
                    answers: [
                        "Earning more money",
                        "Understanding your cash flow",
                        "Investing in stocks"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What does the 50/30/20 rule suggest for budget allocation?",
                    answers: [
                        "50% savings, 30% needs, 20% wants",
                        "50% essentials, 30% pleasures, 20% savings",
                        "50% investments, 30% expenses, 20% emergency fund"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What should you record to understand your spending patterns?",
                    answers: [
                        "Only large expenses over $100",
                        "Every expense, no matter how small",
                        "Only monthly bills and subscriptions"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "The Financial Cushion: Why Everyone Needs One":
            return [
                QuizQuestion(
                    question: "What is a financial cushion?",
                    answers: [
                        "A comfortable mattress for sleeping",
                        "Money set aside for unexpected expenses",
                        "Extra income from investments"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "How much should you aim to save for your initial emergency fund?",
                    answers: [
                        "$100-$200",
                        "$500-$1000",
                        "$5000-$10000"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What does a financial cushion prevent?",
                    answers: [
                        "Making investments",
                        "Going into debt when emergencies occur",
                        "Spending money on entertainment"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "How to Avoid Impulse Buying and Protect Your Budget":
            return [
                QuizQuestion(
                    question: "What is the 24-hour rule for avoiding impulse buying?",
                    answers: [
                        "Wait 24 hours before making any purchase over $50",
                        "Only shop during 24-hour stores",
                        "Spend no more than $24 per day"
                    ],
                    correctAnswerIndex: 0
                ),
                QuizQuestion(
                    question: "What is impulse buying described as in this chapter?",
                    answers: [
                        "A smart shopping strategy",
                        "One of the biggest budget killers",
                        "A way to save money"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What should you ask yourself before making an unplanned purchase?",
                    answers: [
                        "Can I afford this?",
                        "Will this make me happy tomorrow, or just today?",
                        "Is this on sale?"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "Don't Break the Eggs: The Power of Financial Diversification":
            return [
                QuizQuestion(
                    question: "What does 'don't put all your eggs in one basket' mean in finance?",
                    answers: [
                        "Don't buy expensive items",
                        "Spread your risk across different investments",
                        "Don't save money in banks"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What types of investments should you consider for diversification?",
                    answers: [
                        "Only stocks",
                        "Stocks, bonds, real estate, and side hustles",
                        "Only savings accounts"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What does diversification guarantee?",
                    answers: [
                        "Higher profits",
                        "No losses",
                        "Reduced risk of catastrophic losses"
                    ],
                    correctAnswerIndex: 2
                )
            ]
            
        case "Financial Goals: Turning Dreams Into Action":
            return [
                QuizQuestion(
                    question: "What does SMART stand for in goal setting?",
                    answers: [
                        "Simple, Measurable, Achievable, Realistic, Timely",
                        "Specific, Measurable, Achievable, Relevant, Time-bound",
                        "Smart, Meaningful, Attainable, Realistic, Timely"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What is better than 'I want to save money'?",
                    answers: [
                        "I will save $5,000 for a vacation by December 2024",
                        "I will save some money",
                        "I will save when I can"
                    ],
                    correctAnswerIndex: 0
                ),
                QuizQuestion(
                    question: "What type of race is financial success compared to?",
                    answers: [
                        "A sprint",
                        "A marathon",
                        "A relay race"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "Small Steps to Big Money":
            return [
                QuizQuestion(
                    question: "How much should you start saving per day according to this chapter?",
                    answers: [
                        "$50-100",
                        "$1-5",
                        "$20-50"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What is more important than the amount you save?",
                    answers: [
                        "The type of account",
                        "Consistency",
                        "The interest rate"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What creates momentum in saving?",
                    answers: [
                        "Large amounts",
                        "Small steps",
                        "Complex strategies"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "The Saving Habit That Changes Everything":
            return [
                QuizQuestion(
                    question: "What do people become rich because of?",
                    answers: [
                        "High salaries",
                        "They save",
                        "Luck"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What should you make automatic?",
                    answers: [
                        "Your spending",
                        "Saving a small part of every paycheck",
                        "Your investments"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What does the saving habit turn chaos into?",
                    answers: [
                        "More chaos",
                        "Structure",
                        "Confusion"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "How Savings Bring Confidence":
            return [
                QuizQuestion(
                    question: "What does money in the bank represent?",
                    answers: [
                        "Just numbers",
                        "Confidence",
                        "Wasted opportunity"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What can you do when you have savings?",
                    answers: [
                        "Spend more freely",
                        "Say no to bad opportunities and yes to good ones",
                        "Stop working"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What mindset shift does savings create?",
                    answers: [
                        "From abundance to scarcity",
                        "From scarcity to abundance",
                        "From spending to hoarding"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "The Secret Joy of Saving":
            return [
                QuizQuestion(
                    question: "What is saving money really about?",
                    answers: [
                        "Deprivation",
                        "Delayed gratification and joy of watching money grow",
                        "Being cheap"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What should you celebrate?",
                    answers: [
                        "Only large milestones",
                        "Every savings milestone, no matter how small",
                        "Only when you reach your final goal"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What makes saving more enjoyable?",
                    answers: [
                        "Keeping it secret",
                        "Sharing progress with supportive people",
                        "Not thinking about it"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        case "The Future Starts Today":
            return [
                QuizQuestion(
                    question: "What is every dollar you save today?",
                    answers: [
                        "A burden",
                        "A gift to your future self",
                        "Wasted money"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What works its magic over time?",
                    answers: [
                        "Luck",
                        "Compound interest",
                        "Market timing"
                    ],
                    correctAnswerIndex: 1
                ),
                QuizQuestion(
                    question: "What matters more than the amount when starting to save?",
                    answers: [
                        "The interest rate",
                        "The habit",
                        "The account type"
                    ],
                    correctAnswerIndex: 1
                )
            ]
            
        default:
            return [
                QuizQuestion(
                    question: "What is the main theme of this chapter?",
                    answers: [
                        "Spending money wisely",
                        "Building good financial habits",
                        "Making quick profits"
                    ],
                    correctAnswerIndex: 1
                )
            ]
        }
    }
    
    private func showCurrentQuestion() {
        guard currentQuestionIndex < questions.count else {
            showQuizResult()
            return
        }
        
        let question = questions[currentQuestionIndex]
        setupQuestionCard(question: question)
    }
    
    private func setupQuestionCard(question: QuizQuestion) {
        // Очищаем предыдущую карточку
        questionCardView.subviews.forEach { $0.removeFromSuperview() }
        
        // Настройка карточки
        questionCardView.backgroundColor = UIColor(named: "chickYellowLight")
        questionCardView.layer.cornerRadius = 24
        questionCardView.layer.shadowColor = UIColor.black.cgColor
        questionCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        questionCardView.layer.shadowOpacity = 0.1
        questionCardView.layer.shadowRadius = 4
        questionCardView.layer.borderWidth = 2
        questionCardView.layer.borderColor = UIColor(named: "chickDarkYellow")?.cgColor
        
        // Начальное состояние для анимации
        questionCardView.alpha = 0
        questionCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Вопрос
        questionLabel.text = question.question
        questionLabel.font = UIFont(name: "BlackHanSans-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24, weight: .bold)
        questionLabel.textColor = UIColor(named: "chickBrown")
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        questionCardView.addSubview(questionLabel)
        
        // Настройка StackView для ответов
        answerStackView.axis = .vertical
        answerStackView.spacing = 16
        answerStackView.alignment = .fill
        answerStackView.distribution = .fillEqually
        questionCardView.addSubview(answerStackView)
        
        // Кнопки ответов
        for (index, answer) in question.answers.enumerated() {
            let button = UIButton()
            button.setTitle(answer, for: .normal)
            button.setTitleColor(UIColor(named: "chickBrown"), for: .normal)
            button.titleLabel?.font = UIFont(name: "BlackHanSans-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .regular)
            button.titleLabel?.numberOfLines = 0
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.lineBreakMode = .byWordWrapping
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
            button.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0) // Светло-оранжевый
            button.layer.cornerRadius = 25
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor(named: "chickDarkYellow")?.cgColor
            button.tag = index
            button.addTarget(self, action: #selector(answerButtonTapped(_:)), for: .touchUpInside)
            answerStackView.addArrangedSubview(button)
            
            button.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(50)
            }
        }
        
        // Constraints
        questionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        answerStackView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        // Анимация появления карточки
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.questionCardView.alpha = 1
            self.questionCardView.transform = .identity
        }
    }
    
    @objc private func answerButtonTapped(_ sender: UIButton) {
        let question = questions[currentQuestionIndex]
        let selectedAnswerIndex = sender.tag
        
        // Анимация нажатия - быстрое уменьшение и возврат
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        
        // Эффект вспышки при нажатии
        let flashView = UIView(frame: sender.bounds)
        flashView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        flashView.layer.cornerRadius = sender.layer.cornerRadius
        sender.addSubview(flashView)
        
        UIView.animate(withDuration: 0.3, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
        }
        
        // Проверяем правильность ответа с анимацией
        if selectedAnswerIndex == question.correctAnswerIndex {
            score += 1
            UIView.animate(withDuration: 0.3) {
                sender.backgroundColor = UIColor.green.withAlphaComponent(0.3)
                sender.setTitleColor(.green, for: .normal)
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                sender.backgroundColor = UIColor.red.withAlphaComponent(0.3)
                sender.setTitleColor(.red, for: .normal)
            }
            
            // Подсвечиваем правильный ответ с анимацией
            if let correctButton = answerStackView.arrangedSubviews.first(where: { 
                ($0 as? UIButton)?.tag == question.correctAnswerIndex 
            }) as? UIButton {
                UIView.animate(withDuration: 0.3, delay: 0.2) {
                    correctButton.backgroundColor = UIColor.green.withAlphaComponent(0.3)
                    correctButton.setTitleColor(.green, for: .normal)
                }
            }
        }
        
        // Отключаем все кнопки в этой карточке
        answerStackView.arrangedSubviews.forEach { view in
            if let button = view as? UIButton {
                button.isEnabled = false
            }
        }
        
        // Анимация исчезновения карточки и показ результата через 1 секунду
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.3, animations: {
                self.questionCardView.alpha = 0
                self.questionCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                self.showQuizResult()
            }
        }
    }
    
    private func showQuizResult() {
        // Определяем результат (правильный или неправильный ответ)
        let isCorrect = score > 0
        let imageName = isCorrect ? "winQuizArticle" : "loseQuizArticle"
        
        // Если победа, начисляем 10 монет и XP
        if isCorrect {
            let currentWorldCount = UserDefaults.standard.integer(forKey: "worldCount")
            let newWorldCount = currentWorldCount + 10
            UserDefaults.standard.set(newWorldCount, forKey: "worldCount")
            print("Quiz completed! +10 coins. New balance: \(newWorldCount)")
            
            // Добавляем XP за правильный ответ
            ChickInfo.addXP(50) // 50 XP за правильный ответ в квизе главы
        }
        
        // Настраиваем overlay
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        overlayView.frame = view.bounds
        
        // Настраиваем картинку результата
        resultImageView.image = UIImage(named: imageName)
        resultImageView.contentMode = .scaleAspectFit
        resultImageView.isUserInteractionEnabled = true
        
        // Добавляем tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(resultImageTapped))
        resultImageView.addGestureRecognizer(tapGesture)
        
        // Добавляем в иерархию view
        overlayView.alpha = 0
        view.addSubview(overlayView)
        overlayView.addSubview(resultImageView)
        
        // Теперь устанавливаем constraints
        resultImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        // Показываем overlay с анимацией
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 1
        }
    }
    
    @objc private func resultImageTapped() {
        // Переходим к ChickTabBar
        let tabBarVC = ChickTabBar()
        tabBarVC.modalPresentationStyle = .fullScreen
        present(tabBarVC, animated: true)
    }
    
    // Переопределяем стиль status bar для белого фона
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}

// MARK: - Data Model
struct QuizQuestion {
    let question: String
    let answers: [String]
    let correctAnswerIndex: Int
}
