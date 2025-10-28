import UIKit
import SnapKit

final class ChickArticlesDescriptionDetail: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let articleImageView = UIImageView()
    private let descriptionLabel = UILabel()
    private let answerButton = UIButton()
    
    private let chapterTitle: String
    private let chapterImageName: String
    
    init(chapterTitle: String, chapterImageName: String) {
        self.chapterTitle = chapterTitle
        self.chapterImageName = chapterImageName
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
        setupContent()
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
        
        let chickInfo = UIBarButtonItem(image: UIImage(named: "chickInfo")?.withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(answerButtonTapped))
        navigationItem.rightBarButtonItem = chickInfo
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0) // Светло-бежевый фон
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(scrollView.snp.height).priority(.low)
        }
    }
    
    private func setupContent() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(articleImageView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(answerButton)
        
        // Настройка заголовка (оранжевый цвет)
        titleLabel.text = chapterTitle
        titleLabel.textColor = UIColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0) // Оранжевый цвет
        titleLabel.font = UIFont(name: "BlackHanSans-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .left
        
        // Настройка картинки
        articleImageView.image = UIImage(named: chapterImageName)
        articleImageView.contentMode = .scaleAspectFit
        articleImageView.layer.cornerRadius = 12
        articleImageView.clipsToBounds = true
        
        // Настройка описания
        descriptionLabel.text = getDescriptionText(for: chapterTitle)
        descriptionLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Темно-коричневый
        descriptionLabel.font = UIFont(name: "BlackHanSans-Regular", size: 14)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        descriptionLabel.lineBreakMode = .byWordWrapping
        
        // Настройка кнопки
        answerButton.setBackgroundImage(UIImage(named: "answerEarnChickButton"), for: .normal)
        answerButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        answerButton.addTarget(self, action: #selector(answerButtonTapped), for: .touchUpInside)
        
        // Constraints
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        articleImageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(343)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(articleImageView.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        answerButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func getDescriptionText(for title: String) -> String {
        // Возвращаем соответствующий текст описания для каждой главы
        switch title {
        case "How to Start Planning Your Expenses: The First Step to Financial Freedom":
            return "Most people live paycheck to paycheck, unaware of where their money goes. The first step toward financial freedom is understanding your cash flow. Start by recording every expense, no matter how small. You'll soon notice patterns—how much goes to coffee, transport, or online subscriptions that don't add real value.\n\nOnce you know your spending habits, categorize them into needs, wants, and savings. The popular 50/30/20 rule helps: 50% for essentials, 30% for pleasures, and 20% for savings or debt repayment.\n\nPlanning doesn't mean restricting yourself—it's about control and awareness. When you know where your money goes, you can direct it toward what truly matters. Even a simple spreadsheet or budgeting app can help you gain confidence and peace of mind."
        case "The Financial Cushion: Why Everyone Needs One":
            return "A financial cushion is your safety net—money set aside for unexpected expenses or emergencies. Without it, a single unexpected bill can derail your entire financial plan.\n\nStart small: aim to save $500-$1000 for your initial emergency fund. This covers minor emergencies like car repairs or medical bills. Once you have this foundation, work toward building 3-6 months of living expenses.\n\nYour financial cushion gives you peace of mind and prevents you from going into debt when life throws curveballs. It's not about being paranoid—it's about being prepared and maintaining your financial stability."
        case "How to Avoid Impulse Buying and Protect Your Budget":
            return "Impulse buying is one of the biggest budget killers. Those small, unplanned purchases add up quickly and can destroy even the most carefully crafted financial plan.\n\nCreate a 24-hour rule: wait a day before making any non-essential purchase over $50. This cooling-off period often reveals whether you truly need the item or just want it in the moment.\n\nUse shopping lists, avoid browsing when you're emotional, and unsubscribe from marketing emails. Remember, every dollar spent on impulse is a dollar not saved for your future goals."
        case "Don't Break the Eggs: The Power of Financial Diversification":
            return "The old saying 'don't put all your eggs in one basket' applies perfectly to personal finance. Diversification spreads your risk across different types of investments and income sources.\n\nDon't rely on a single income stream or investment. Consider stocks, bonds, real estate, and even side hustles. When one area struggles, others can compensate.\n\nDiversification doesn't guarantee profits, but it reduces the risk of catastrophic losses. It's about building a resilient financial foundation that can weather economic storms."
        case "Financial Goals: Turning Dreams Into Action":
            return "Dreams without action remain just dreams. Financial goals require clear planning, measurable milestones, and consistent action to become reality.\n\nUse the SMART framework: Specific, Measurable, Achievable, Relevant, and Time-bound goals. Instead of 'I want to save money,' try 'I will save $5,000 for a vacation by December 2024.'\n\nBreak large goals into smaller, manageable steps. Celebrate small wins along the way. Remember, financial success is a marathon, not a sprint—consistency beats perfection every time."
        case "Small Steps to Big Money":
            return "Rome wasn't built in a day, and neither is wealth. The secret to building significant savings isn't about making huge sacrifices—it's about making small, consistent changes that compound over time.\n\nStart with micro-savings: save just $1-5 per day. That's less than a coffee, but it adds up to $365-1,825 per year. The key is consistency, not the amount.\n\nSmall steps create momentum. Once you see your savings grow, you'll naturally want to save more. It's like a snowball rolling downhill—small actions create big results over time."
        case "The Saving Habit That Changes Everything":
            return "Many people believe that saving is only for the rich. In reality, it's the other way around — people become rich because they save. A saving habit builds discipline, confidence, and calm.\n\nTry to make it automatic. Set up a rule: every time you get paid, a small part goes directly to savings — like clockwork. Make it so easy that you can't fail. Even if it's just a few dollars, consistency will do the heavy lifting.\n\nAt first, it might feel strange — like brushing your teeth. But after a few months, you'll wonder how you ever lived without it. Savings aren't about deprivation: they're about preparation. The habit turns chaos into structure, and fear into freedom. That's why it's one of the most powerful habits you can build in life — simple, small, and transformational."
        case "How Savings Bring Confidence":
            return "Money in the bank isn't just numbers—it's confidence. When you have savings, you sleep better, worry less, and make better decisions because you're not operating from a place of scarcity.\n\nSavings give you options. You can say no to bad opportunities, yes to good ones, and handle emergencies without panic. This psychological security affects every area of your life.\n\nStart small and watch your confidence grow with your balance. Even $100 in savings can change how you approach financial decisions. It's not about the amount—it's about the mindset shift from scarcity to abundance."
        case "The Secret Joy of Saving":
            return "Saving money isn't about deprivation—it's about delayed gratification and the joy of watching your money grow. There's something deeply satisfying about seeing your balance increase month after month.\n\nCelebrate your savings milestones, no matter how small. Treat yourself to something meaningful when you reach goals. The key is to make saving feel rewarding, not restrictive.\n\nShare your progress with supportive friends or family. Saving becomes more enjoyable when it's a positive, shared experience rather than a secret struggle. Remember, you're not missing out—you're building something better."
        case "The Future Starts Today":
            return "Every dollar you save today is a gift to your future self. Compound interest works its magic over time, turning small, consistent savings into significant wealth.\n\nDon't wait for the 'perfect' time to start saving—it doesn't exist. Start with whatever you can spare today, even if it's just spare change. The habit matters more than the amount.\n\nVisualize your future self thanking you for the financial security you're building today. Every small step you take now creates a brighter, more secure tomorrow. The best time to plant a tree was 20 years ago—the second best time is now."
        case "Building a Strong Nest: The Art of Balance":
            return "A strong nest isn't built overnight—it's crafted with patience, wisdom, and careful attention to balance. Just like birds carefully select materials for their nests, you must choose your financial foundations wisely.\n\nBalance is key: not too risky, not too conservative. Diversify your investments like a bird spreads its eggs across different branches. Some will hatch, some might not, but your overall nest remains secure.\n\nRegular maintenance keeps your nest strong. Check your investments, adjust your budget, and repair any cracks before they become problems. A well-maintained nest can weather any storm."
        case "The Importance of Checking Your Nest Regularly":
            return "Even the strongest nest needs regular inspection. Set aside time each month to review your finances—check your accounts, track your spending, and assess your progress toward goals.\n\nLook for cracks: unexpected expenses, rising costs, or investments that aren't performing. Early detection prevents small problems from becoming big disasters.\n\nMake it a habit, like checking your car's oil or your home's smoke detectors. Regular financial checkups keep your nest secure and your peace of mind intact."
        case "Emotional Spending: When Feelings Crack the Shell":
            return "We've all been there — buying something just because it \"feels good.\" Maybe it's a new gadget, a fancy dinner, or that extra pair of shoes you didn't need. But emotional spending is like a sneaky fox: it slips into your nest and steals your eggs one by one.\n\nThe problem isn't the purchase itself — it's the impulse. When emotions lead, logic hides. To avoid cracking your budget, pause before every unplanned purchase. Ask, \"Will this make me happy tomorrow, or just today?\"\n\nOne simple trick is to use the 24-hour rule: if you still want it tomorrow, go ahead. Most of the time, the desire fades, and your eggs stay safe.\n\nSaving money doesn't mean saying \"no\" to joy. It means saying \"yes\" to lasting satisfaction — the kind that comes from knowing you're building something solid, not patching cracks with glitter."
        case "The Cracked Nest: How Little Mistakes Break Big Plans":
            return "Small cracks in your financial nest can lead to big problems if left unchecked. A missed payment here, an impulse purchase there—these seemingly minor mistakes can compound into major setbacks.\n\nThink of your budget like a nest: one small crack doesn't seem dangerous, but over time, it weakens the entire structure. Water seeps in, predators find entry, and your security is compromised.\n\nPrevention is easier than repair. Build good habits from the start, and fix small problems immediately. A well-maintained nest protects your eggs—and your financial future—from unexpected storms."
        case "Turning Mistakes into Feathers: Growing from Cracks":
            return "Every bird's nest has cracks—it's how you respond that matters. Financial mistakes aren't failures; they're learning opportunities that make you stronger and wiser.\n\nWhen you make a financial mistake, don't hide from it. Examine what went wrong, understand why it happened, and create systems to prevent it from happening again. Each mistake teaches you something valuable.\n\nTurn your cracks into feathers—use your experiences to build a stronger, more resilient nest. The bird that learns from its mistakes builds the most secure home of all."
        case "Every Egg Counts: Understanding the Power of Income":
            return "Every egg in your basket represents potential—potential for growth, security, and freedom. Understanding how to maximize your income is like learning to collect more eggs without breaking the ones you already have.\n\nStart by tracking every dollar that comes in. Know your sources, understand your patterns, and identify opportunities for growth. Even small increases compound over time.\n\nRemember, it's not just about earning more—it's about earning smarter. Focus on income that grows with your skills and creates lasting value, not just quick wins."
        case "Don't Keep All Your Eggs in One Basket":
            return "The old saying holds true in income too—don't rely on a single source. Just like a farmer with only one hen risks losing everything if she stops laying, depending on one income stream leaves you vulnerable.\n\nDiversify your income sources: salary, freelance work, investments, side businesses. When one stream slows down, others can keep you afloat.\n\nStart small with additional income streams. Even a few extra dollars from a hobby or skill can grow into something significant over time. The goal is resilience, not just more money."
        case "Feeding the Hens: How to Grow Your Earning Power":
            return "To get more eggs, you need to feed your hens well. In income terms, this means investing in yourself—your skills, knowledge, and abilities that generate money.\n\nSpend time and money on education, training, and skill development. Learn new technologies, improve your communication, or develop expertise in high-demand areas.\n\nThink of yourself as the hen that lays golden eggs. The better you feed and care for yourself, the more valuable eggs you'll produce. Self-investment always pays the best returns."
        case "When Eggs Multiply: Managing Income Wisely":
            return "Earning more is great, but managing that income wisely is the real challenge. Without proper planning, new income can lead to increased spending, leaving you feeling broke despite earning more—your egg basket has holes.\n\nDon't immediately increase your lifestyle when income grows. Instead, save or invest a portion first to create new hens rather than consuming all eggs at once.\n\nMoney management isn't about being stingy—it's about being smart. Make your income work hard for you. A wise farmer doesn't eat all the eggs. They hatch some for the future."
        case "The Golden Egg: Turning Effort into Freedom":
            return "The ultimate goal isn't just more eggs—it's turning your effort into lasting freedom. This means building income streams that work even when you're not actively working.\n\nFocus on creating passive income: investments, royalties, rental income, or businesses that run themselves. These are your golden eggs—they keep producing value without constant effort.\n\nStart by reinvesting a portion of your active income into passive opportunities. Over time, your golden eggs will multiply, giving you the freedom to choose how you spend your time and energy."
        case "Planting the Seeds: Setting Goals That Grow Naturally":
            return "Like a farmer planting seeds, setting financial goals requires patience, preparation, and faith in the process. Choose goals that align with your values and grow naturally from your current situation.\n\nStart with small, achievable goals that build confidence. A goal to save $100 feels more manageable than $10,000, but both lead to the same destination—just at different speeds.\n\nPlant your goals in fertile soil: create systems that support them, track your progress regularly, and adjust your approach as you learn. Good goals grow stronger over time, not weaker."
        case "The Gentle Farmer: Achieving More by Doing Less":
            return "The best farmers don't force their crops—they create the right conditions and let nature do the work. Similarly, the most effective goal achievement comes from creating systems, not from constant pushing.\n\nFocus on building habits that support your goals rather than relying on willpower alone. Set up automatic savings, create routines that reinforce good financial behavior, and remove obstacles that make bad choices easier.\n\nRemember, sustainable progress beats dramatic bursts. A gentle, consistent approach yields better long-term results than frantic effort followed by burnout."
        case "The Power of Tiny Steps: Growing Without Overwhelm":
            return "Big goals can feel overwhelming, but they're achieved through countless tiny steps. Break your financial goals into the smallest possible actions you can take today.\n\nInstead of 'save $5,000 this year,' start with 'save $1 this week.' Small steps feel manageable and create momentum. Each tiny victory builds confidence for the next step.\n\nTrack your progress visually—watch your savings grow, celebrate small milestones, and remember that every giant oak started as a tiny acorn. Consistency in small actions creates extraordinary results."
        case "Resting Without Guilt: Why Breaks Grow Results":
            return "Even the most fertile fields need fallow periods to restore their nutrients. Taking breaks from intense goal pursuit isn't laziness—it's strategic rest that makes you more effective.\n\nSchedule regular breaks in your financial planning: monthly reviews, quarterly assessments, and annual celebrations. Use these pauses to reflect, adjust, and recharge.\n\nRest prevents burnout and gives you fresh perspective. Sometimes stepping back helps you see new opportunities or better approaches. A well-rested farmer makes better decisions than an exhausted one."
        case "Harvest Time: Celebrating Your Wins (Big or Small)":
            return "Every farmer celebrates their harvest, no matter how small. Celebrating your financial wins—big or small—strengthens your motivation and makes the journey enjoyable.\n\nAcknowledge every milestone: your first $100 saved, paying off a credit card, or reaching a savings goal. These celebrations reinforce positive behavior and remind you why you started.\n\nCelebration isn't just about the finish line—it's part of the journey. When you celebrate your wins, you're more likely to continue because you see that your efforts have taken root and are bearing fruit."
        default:
            return "This chapter provides valuable insights and practical advice on financial management. Learn the essential concepts and apply them to improve your financial well-being."
        }
    }
    
    @objc private func answerButtonTapped() {
        print("Answer button tapped!")
        // Переходим к викторине с названием главы
        let quizVC = ChickArticlesQuiz(chapterTitle: chapterTitle)
        navigationController?.pushViewController(quizVC, animated: true)
    }
    
    // Переопределяем стиль status bar для белого фона
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
}
