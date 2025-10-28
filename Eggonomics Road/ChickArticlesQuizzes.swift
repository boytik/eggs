import UIKit
import SnapKit

final class ChickArticlesQuizzes: UIViewController {
    
    private let chickQuizBG = UIImageView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let questionCardView = UIView()
    private let questionLabel = UILabel()
    private let answerStackView = UIStackView()
    private var questions: [QuizQuestion] = []
    private var currentQuestionIndex = 0
    private var score = 0
    private var quizTitle: String
    private var overlayView = UIView()
    private var resultImageView = UIImageView()
    
    init(quizTitle: String) {
        self.quizTitle = quizTitle
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
        questions = getQuestionsForQuiz(quizTitle)
    }
    
    private func getQuestionsForQuiz(_ title: String) -> [QuizQuestion] {
        switch title {
        case "How to Plan Your Spending and Not Break Your Eggs for Nothing":
            return [
                QuizQuestion(question: "What is the first step in financial planning?", answers: ["Investing", "Understanding your cash flow", "Buying insurance"], correctAnswerIndex: 1),
                QuizQuestion(question: "What does the 50/30/20 rule represent?", answers: ["50% essentials, 30% wants, 20% savings", "50% savings, 30% essentials, 20% wants", "50% wants, 30% savings, 20% essentials"], correctAnswerIndex: 0),
                QuizQuestion(question: "Why should you track every expense?", answers: ["To feel guilty", "To notice spending patterns", "To impress others"], correctAnswerIndex: 1),
                QuizQuestion(question: "What's the purpose of categorizing expenses?", answers: ["To complicate things", "To understand needs vs wants", "To waste time"], correctAnswerIndex: 1),
                QuizQuestion(question: "What does planning give you?", answers: ["Stress", "Control and awareness", "Debt"], correctAnswerIndex: 1),
                QuizQuestion(question: "Should you track small expenses?", answers: ["No, only large ones", "Yes, every expense matters", "Only if you have time"], correctAnswerIndex: 1),
                QuizQuestion(question: "What can help with budgeting?", answers: ["A spreadsheet or budgeting app", "Ignoring it", "Guessing"], correctAnswerIndex: 0),
                QuizQuestion(question: "What does planning mean?", answers: ["Complete restriction", "Control and awareness", "No spending"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should 20% of your budget go to?", answers: ["Entertainment", "Savings or debt repayment", "Shopping"], correctAnswerIndex: 1),
                QuizQuestion(question: "What does financial planning bring?", answers: ["Confusion", "Confidence and peace of mind", "More expenses"], correctAnswerIndex: 1)
            ]
            
        case "Why Save Money: The Power of Small Steps":
            return [
                QuizQuestion(question: "How much should you start saving per day?", answers: ["$50", "$1-5", "$100"], correctAnswerIndex: 1),
                QuizQuestion(question: "What's more important than the amount?", answers: ["The bank", "Consistency", "The interest rate"], correctAnswerIndex: 1),
                QuizQuestion(question: "What do small steps create?", answers: ["Nothing", "Momentum", "Debt"], correctAnswerIndex: 1),
                QuizQuestion(question: "Who becomes rich?", answers: ["Lucky people", "People who save", "Only high earners"], correctAnswerIndex: 1),
                QuizQuestion(question: "How should saving be done?", answers: ["Manually each time", "Automatically", "Only when you remember"], correctAnswerIndex: 1),
                QuizQuestion(question: "What does saving turn chaos into?", answers: ["More chaos", "Structure", "Nothing"], correctAnswerIndex: 1),
                QuizQuestion(question: "What does money in the bank represent?", answers: ["Numbers", "Confidence", "Waste"], correctAnswerIndex: 1),
                QuizQuestion(question: "What do savings give you?", answers: ["Stress", "Options and security", "Debt"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should you celebrate?", answers: ["Only big wins", "Every milestone", "Nothing"], correctAnswerIndex: 1),
                QuizQuestion(question: "When should you start saving?", answers: ["When rich", "Today", "Tomorrow"], correctAnswerIndex: 1)
            ]
            
        case "How to Avoid Financial Mistakes and a \"Cracked Nest\"":
            return [
                QuizQuestion(question: "What is key to a strong nest?", answers: ["Speed", "Balance", "Luck"], correctAnswerIndex: 1),
                QuizQuestion(question: "How should you diversify?", answers: ["Don't diversify", "Like a bird spreads eggs across branches", "Put all in one place"], correctAnswerIndex: 1),
                QuizQuestion(question: "How often should you check your finances?", answers: ["Never", "Each month", "Every year"], correctAnswerIndex: 1),
                QuizQuestion(question: "What is emotional spending compared to?", answers: ["A helpful habit", "A sneaky fox stealing eggs", "Smart shopping"], correctAnswerIndex: 1),
                QuizQuestion(question: "What rule helps avoid emotional purchases?", answers: ["Buy immediately", "24-hour rule", "Never buy anything"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should you ask before unplanned purchases?", answers: ["Is it cheap?", "Will this make me happy tomorrow or just today?", "Do I need it right now?"], correctAnswerIndex: 1),
                QuizQuestion(question: "What do small cracks lead to?", answers: ["Nothing", "Big problems if unchecked", "More money"], correctAnswerIndex: 1),
                QuizQuestion(question: "What's easier: prevention or repair?", answers: ["Repair", "Prevention", "Both are equal"], correctAnswerIndex: 1),
                QuizQuestion(question: "What are financial mistakes?", answers: ["Failures", "Learning opportunities", "End of the world"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should you do after a mistake?", answers: ["Hide it", "Examine and learn from it", "Ignore it"], correctAnswerIndex: 1)
            ]
            
        case "Income: How to Hatch New Eggs":
            return [
                QuizQuestion(question: "What does each egg represent?", answers: ["Nothing", "Potential for growth and freedom", "Expenses"], correctAnswerIndex: 1),
                QuizQuestion(question: "Should you rely on one income source?", answers: ["Yes", "No, diversify income sources", "It doesn't matter"], correctAnswerIndex: 1),
                QuizQuestion(question: "What are examples of income diversification?", answers: ["Only salary", "Salary, freelance, investments, side businesses", "Just investments"], correctAnswerIndex: 1),
                QuizQuestion(question: "How do you get more eggs?", answers: ["Buy them", "Feed your hens well (invest in yourself)", "Wait"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should you invest in?", answers: ["Only stocks", "Yourself - skills and knowledge", "Nothing"], correctAnswerIndex: 1),
                QuizQuestion(question: "What happens without proper income management?", answers: ["You get richer", "Your egg basket has holes", "Nothing changes"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should you do when income grows?", answers: ["Increase lifestyle immediately", "Save or invest a portion first", "Spend it all"], correctAnswerIndex: 1),
                QuizQuestion(question: "What are golden eggs?", answers: ["Expensive items", "Passive income streams", "Debts"], correctAnswerIndex: 1),
                QuizQuestion(question: "What gives you freedom?", answers: ["Debt", "Passive income that works when you don't", "Working harder"], correctAnswerIndex: 1),
                QuizQuestion(question: "What should you do with active income?", answers: ["Spend it all", "Reinvest portion into passive opportunities", "Hide it"], correctAnswerIndex: 1)
            ]
            
        case "How to Set Goals and Achieve Them Without Stress":
            return [
                QuizQuestion(question: "What do goals need to grow?", answers: ["Force", "Patience and proper systems", "Luck"], correctAnswerIndex: 1),
                QuizQuestion(question: "What size goals should you start with?", answers: ["Huge goals only", "Small, achievable goals", "No goals"], correctAnswerIndex: 1),
                QuizQuestion(question: "What's better than forcing goals?", answers: ["Giving up", "Creating systems and habits", "Working harder"], correctAnswerIndex: 1),
                QuizQuestion(question: "What beats dramatic bursts?", answers: ["Nothing", "Gentle, consistent approach", "Random effort"], correctAnswerIndex: 1),
                QuizQuestion(question: "How should you break big goals?", answers: ["Don't break them", "Into smallest possible actions", "Into impossible tasks"], correctAnswerIndex: 1),
                QuizQuestion(question: "What builds confidence?", answers: ["Large steps only", "Each tiny victory", "Comparing to others"], correctAnswerIndex: 1),
                QuizQuestion(question: "Are breaks from goal pursuit lazy?", answers: ["Yes, always", "No, they're strategic rest", "Maybe"], correctAnswerIndex: 1),
                QuizQuestion(question: "What prevents burnout?", answers: ["Working harder", "Regular breaks and rest", "Ignoring goals"], correctAnswerIndex: 1),
                QuizQuestion(question: "Should you celebrate small wins?", answers: ["No, only big ones", "Yes, every milestone matters", "Never celebrate"], correctAnswerIndex: 1),
                QuizQuestion(question: "What does celebrating wins do?", answers: ["Wastes time", "Strengthens motivation and makes journey enjoyable", "Creates stress"], correctAnswerIndex: 1)
            ]
            
        default:
            return [
                QuizQuestion(question: "What is the main theme?", answers: ["Spending", "Building good financial habits", "Quick profits"], correctAnswerIndex: 1)
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
        answerStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
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
        
        // Анимация исчезновения и переход через 1 секунду
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            UIView.animate(withDuration: 0.3, animations: {
                self.questionCardView.alpha = 0
                self.questionCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                self.currentQuestionIndex += 1
                
                if self.currentQuestionIndex < self.questions.count {
                    self.showCurrentQuestion()
                } else {
                    self.showQuizResult()
                }
            }
        }
    }
    
    private func showQuizResult() {
        // Определяем результат - winfull только если все вопросы правильные (10/10)
        let isWin = score == questions.count
        let imageName = isWin ? "winfull" : "loseQuizArticle"
        
        if isWin {
            let currentWorldCount = UserDefaults.standard.integer(forKey: "worldCount")
            let newWorldCount = currentWorldCount + 100
            UserDefaults.standard.set(newWorldCount, forKey: "worldCount")
            print("Quiz completed! +100 coins. New balance: \(newWorldCount)")
            
            // Добавляем XP за правильный ответ (больше за полный квиз)
            ChickInfo.addXP(100) // 100 XP за правильный ответ в полном квизе
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
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(resultImageView.snp.width)
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
struct QuizQuestionData {
    let question: String
    let answers: [String]
    let correctAnswerIndex: Int
}
